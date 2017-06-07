//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import Dispatch

open class ProcessProcedure: Procedure, InputProcedure, OutputProcedure {

    public struct LaunchRequest {
        /// (Read-only) The path to the executable to be launched.
        let executableURL: URL

        /// (Read-only) The command arguments that should be used to launch the executable.
        let arguments: [String]?

        /// (Read-only) The current directory to be used when launching the executable.
        let currentDirectoryURL: URL?

        /// (Read-only) The environment to be used when launching the executable.
        let environment: [String : String]?

        /// (Read-only) The standard error (FileHandle or Pipe object).
        let standardError: Any?

        /// (Read-only) The standard input (FileHandle or Pipe object).
        let standardInput: Any?

        /// (Read-only) The standard output (FileHandle or Pipe object).
        let standardOutput: Any?

        /// Initialize a request to launch a Process.
        ///
        /// The minimum required parameter is a path to the executable to launch (`executableURL`).
        ///
        /// Other parameters are optional, and are described in full in the documentation
        /// for NSTask/Process: https://developer.apple.com/reference/foundation/process
        ///
        /// By default, `Process` inherits the environment and some other parameters from the current process.
        ///
        /// - Parameters:
        ///   - executableURL: the path to the executable to be launched.
        ///   - arguments: (optional) the command arguments that should be used to launch the executable.
        ///   - currentDirectoryURL: (optional) the current directory to be used when launching the executable.
        ///   - environment: (optional) the environment to be used when launching the executable.
        ///   - standardError: (optional) the standard error (FileHandle or Pipe object)
        ///   - standardInput: (optional) the standard input (FileHandle or Pipe object)
        ///   - standardOutput: (optional) the standard output (FileHandle or Pipe object)
        init(executableURL: URL, arguments: [String]? = nil, currentDirectoryURL: URL? = nil, environment: [String : String]? = nil, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil) {
            self.executableURL = executableURL
            self.arguments = arguments
            self.currentDirectoryURL = currentDirectoryURL
            self.environment = environment
            self.standardError = standardError
            self.standardInput = standardInput
            self.standardOutput = standardOutput
        }
    }

    public struct TerminationResult {
        let status: Int32
        let reason: Process.TerminationReason
    }

    /// Error type for ProcessProcedure
    public enum Error: Swift.Error, Equatable {
        case emptyLaunchPath
        case invalidLaunchPath
        case didNotExitCleanly(Int32, Process.TerminationReason)

        public static func == (lhs: ProcessProcedure.Error, rhs: ProcessProcedure.Error) -> Bool {
            switch (lhs, rhs) {
            case (.emptyLaunchPath, .emptyLaunchPath): return true
            case (.invalidLaunchPath, .invalidLaunchPath): return true
            case let (.didNotExitCleanly(lhsStatus, lhsReason), .didNotExitCleanly(rhsStatus, rhsReason)):
                return (lhsReason == rhsReason) && (lhsStatus == rhsStatus)
            default: return false
            }
        }
    }

    /// Closure type for processDidLaunch event
    public typealias ProcessDidLaunch = (ProcessProcedure) -> Void

    /// Closure type for determining whether the process exited cleanly
    /// - Parameters:
    ///   - Process.terminationStatus (In32)
    ///   - Process.terminationReason (Process.TerminationReason)
    /// - returns Bool: `true` if the Process exited cleanly, `false` otherwise
    public typealias ProcessDidExitCleanly = (Int32, Process.TerminationReason) -> Bool

    /// The default closure for checking the exit status
    public static let defaultProcessDidExitCleanly: ProcessDidExitCleanly = { status, reason in
        switch reason {
        case .uncaughtSignal: return false
        case .exit:
            switch status {
            case 0: return true
            default: return false
            }
        }
    }

    /// The LaunchRequest used to launch a Process.
    public var input: Pending<LaunchRequest> {
        get { return stateLock.withCriticalScope { _input } }
        set {
            assert(!isExecuting, "Changing the input on a ProcessProcedure after it has started to execute will not have any effect.")
            assert(!isFinished, "Changing the input on a ProcessProcedure after it has finished will not have any effect.")
            stateLock.withCriticalScope {
                _input = newValue
            }
        }
    }

    /// The ProcessProcedure result.
    ///
    /// On success (determined by the `processDidExitCleanly` handler), it will
    /// be set to `.success(TerminationResult)`.
    ///
    /// If the `processDidExitCleanly` handler returns `false`, `output` will
    /// bet set to `.failure(ProcessProcedure.Error.didNotExitCleanly)`.
    ///
    /// Both `TerminationResult` and `ProcessProcedure.Error.didNotExitCleanly`
    /// provide the Process `terminationStatus` and `terminationReason`.
    public var output: Pending<ProcedureResult<TerminationResult>> {
        get { return stateLock.withCriticalScope { _output } }
        set {
            stateLock.withCriticalScope {
                _output = newValue
            }
        }
    }

    // - returns process: the Process   // internal for testing
    internal fileprivate(set) var process: Process? {
        get { return stateLock.withCriticalScope { _process } }
        set {
            stateLock.withCriticalScope {
                _process = newValue
            }
        }
    }

    fileprivate var _process: Process?
    fileprivate var _processIdentifier: Int32 = 0
    fileprivate var _input: Pending<LaunchRequest> = .pending
    fileprivate var _output: Pending<ProcedureResult<TerminationResult>> = .pending
    fileprivate let stateLock = PThreadMutex()

    /// - the closure that is called once the Process has been launched
    private let processDidLaunch: ProcessDidLaunch

    /// - returns processDidExitCleanly: the closure for exiting cleanly.
    private let processDidExitCleanly: ProcessDidExitCleanly

    // MARK: Initializer (with launchPath + currentDirectoryPath)

    /// Initialize a ProcessProcedure.
    ///
    /// The minimum required parameter is a path to the executable to launch (`launchPath`).
    ///
    /// Other parameters are optional, and are described in full in the documentation
    /// for NSTask/Process: https://developer.apple.com/reference/foundation/process
    ///
    /// By default, `Process` inherits the environment and some other parameters from the current process.
    ///
    /// - Parameters:
    ///   - launchPath: the path to the executable to be launched.
    ///   - arguments: (optional) the command arguments that should be used to launch the executable.
    ///   - currentDirectoryPath: (optional) the current directory to be used when launching the executable.
    ///   - environment: (optional) the environment to be used when launching the executable.
    ///   - standardError: (optional) the standard error (FileHandle or Pipe object)
    ///   - standardInput: (optional) the standard input (FileHandle or Pipe object)
    ///   - standardOutput: (optional) the standard output (FileHandle or Pipe object)
    ///   - processDidLaunch: a ProcessDidLaunch block that is called once the Process has been launched.
    ///   - processDidExitCleanly: a ProcessDidExitCleanly block that is called once the Process has terminated, and is used to determine whether the ProcessProcedure finishes with an error.
    public convenience init(launchPath: String, arguments: [String]? = nil, currentDirectoryPath: String? = nil, environment: [String : String]? = nil, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil, processDidLaunch: @escaping ProcessDidLaunch = { _ in }, processDidExitCleanly: @escaping ProcessDidExitCleanly = ProcessProcedure.defaultProcessDidExitCleanly) {

        let executableURL = URL(fileURLWithPath: launchPath)
        let currentDirectoryURL = (currentDirectoryPath != nil) ? URL(fileURLWithPath: currentDirectoryPath!) : nil

        let launchRequest = LaunchRequest(executableURL: executableURL, arguments: arguments, currentDirectoryURL: currentDirectoryURL, environment: environment, standardError: standardError, standardInput: standardInput, standardOutput: standardOutput)

        self.init(launchRequest: launchRequest, processDidLaunch: processDidLaunch, processDidExitCleanly: processDidExitCleanly)
    }

    // MARK: Initializer (with executableURL + currentDirectoryURL)

    /// Initialize a ProcessProcedure.
    ///
    /// The minimum required parameter is a path to the executable to launch (`executableURL`).
    ///
    /// Other parameters are optional, and are described in full in the documentation
    /// for NSTask/Process: https://developer.apple.com/reference/foundation/process
    ///
    /// By default, `Process` inherits the environment and some other parameters from the current process.
    ///
    /// - Parameters:
    ///   - executableURL: the path to the executable to be launched.
    ///   - arguments: (optional) the command arguments that should be used to launch the executable.
    ///   - currentDirectoryURL: (optional) the current directory to be used when launching the executable.
    ///   - environment: (optional) the environment to be used when launching the executable.
    ///   - standardError: (optional) the standard error (FileHandle or Pipe object)
    ///   - standardInput: (optional) the standard input (FileHandle or Pipe object)
    ///   - standardOutput: (optional) the standard output (FileHandle or Pipe object)
    ///   - processDidLaunch: a ProcessDidLaunch block that is called once the Process has been launched.
    ///   - processDidExitCleanly: a ProcessDidExitCleanly block that is called once the Process has terminated, and is used to determine whether the ProcessProcedure finishes with an error.
    public convenience init(executableURL: URL, arguments: [String]? = nil, currentDirectoryURL: URL? = nil, environment: [String : String]? = nil, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil, processDidLaunch: @escaping ProcessDidLaunch = { _ in }, processDidExitCleanly: @escaping ProcessDidExitCleanly = ProcessProcedure.defaultProcessDidExitCleanly) {

        let launchRequest = LaunchRequest(executableURL: executableURL, arguments: arguments, currentDirectoryURL: currentDirectoryURL, environment: environment, standardError: standardError, standardInput: standardInput, standardOutput: standardOutput)

        self.init(launchRequest: launchRequest, processDidLaunch: processDidLaunch, processDidExitCleanly: processDidExitCleanly)
    }

    /// Initialize a ProcessProcedure.
    ///
    /// A LaunchRequest must be provided before the ProcessProcedure executes.
    /// It can be provided up-front, via this initializer, or later via result injection.
    ///
    /// Optionally, a `processDidLaunch` and/or `processDidExitCleanly` handler may be
    /// provided.
    ///
    /// The `processDidLaunch` and `processDidExitCleanly` handlers are executed
    /// on the ProcessProcedure's internal EventQueue.
    ///
    /// - Parameters:
    ///   - launchRequest: a `LaunchRequest` containing the parameters used to launch a Process
    ///   - processDidLaunch: a ProcessDidLaunch block that is called once the Process has been launched.
    ///   - processDidExitCleanly: a ProcessDidExitCleanly block that is called once the Process has terminated, and is used to determine whether the ProcessProcedure finishes with an error.
    public init(launchRequest: LaunchRequest? = nil, processDidLaunch: @escaping ProcessDidLaunch = { _ in }, processDidExitCleanly: @escaping ProcessDidExitCleanly = ProcessProcedure.defaultProcessDidExitCleanly) {

        self.processDidLaunch = processDidLaunch
        self.processDidExitCleanly = processDidExitCleanly
        super.init()
        self.input = launchRequest.flatMap { .ready($0) } ?? .pending

        addDidCancelBlockObserver { procedure, _ in
            DispatchQueue.main.async {
                guard let process = procedure.process else { return }
                guard procedure.isExecuting && process.isRunning else { return }
                process.terminate()
                // `finish()` is handled by the process termination handler
            }
        }
    }

    open override func execute() {

        guard let request = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        guard request.executableURL.isFileURL else {
            finish(withResult: .failure(Error.invalidLaunchPath))
            return
        }

        let launchPath = request.executableURL.path
        guard !launchPath.isEmpty else {
            finish(withResult: .failure(Error.emptyLaunchPath))
            return
        }

        // Check whether the launchPath provided in the request is executable
        //
        // NOTE: This check is a "snapshot" check, is **not** exhaustive, and
        // exists largely to assist in catching simple programmer error.
        //
        // If the `launchPath` disappears or becomes non-executable between the time
        // of this check, and the ProcessProcedure's later call to `Process.launch()`,
        // or if various other error situations occur with the provided LaunchRequest
        // parameters passed to the Process, Process may throw an Objective-C exception
        // on macOS < 10.13.
        // See the documentation for Process / NSTask for more details.
        //
        guard FileManager.default.isExecutableFile(atPath: launchPath) else {
            finish(withResult: .failure(Error.invalidLaunchPath))
            return
        }

        // NOTE: NSTask / Process is *not* thread-safe.
        // See: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html#//apple_ref/doc/uid/10000057i-CH12-125664
        //
        // It's not a good idea to call `launch()` on a thread that may disappear before the
        // NSTask / Process goes away. Thus, we use the main queue/thread.

        DispatchQueue.main.async { [weak self] in
            guard let procedure = self else { return }

            // create Process
            let process = procedure.createProcess(withRequest: request)

            process.terminationHandler = { [weak procedure] process in
                guard let procedure = procedure else { return }

                guard !procedure.isCancelled else {
                    // special case: hide the Process's cancellation error
                    // if the ProcessProcedure was cancelled
                    procedure.finish()
                    return
                }

                let terminationStatus = process.terminationStatus
                let terminationReason = process.terminationReason

                // Dispatch the `processDidExitCleanly` closure on the EventQueue
                procedure.eventQueue.dispatch {

                    if procedure.processDidExitCleanly(terminationStatus, terminationReason) {
                        procedure.finish(withResult: .success(TerminationResult(status: terminationStatus, reason: terminationReason)))
                    }
                    else {
                        procedure.finish(withResult: .failure(Error.didNotExitCleanly(terminationStatus, terminationReason)))
                    }
                }
            }

            // The ProcessProcedure can be cancelled concurrently with this block on the main queue.
            // Check whether the Procedure has been cancelled.
            guard !procedure.isCancelled else {
                procedure.finish()
                return
            }

            // Store the process
            procedure.process = process

            // Launch the Process
            do { try procedure.run(process: process) }
            catch {
                // Failed to run the Process
                // Note: This will generally only occur on macOS 10.13+, where new methods
                //       on Process are available that throw errors (instead of raising
                //       Objective-C exceptions).
                procedure.finish(withResult: .failure(error))
                return
            }

            // Store the processIdentifier
            procedure.processIdentifier = process.processIdentifier

            // Dispatch the ProcessDidLaunch callback
            procedure.eventQueue.dispatch {
                procedure.processDidLaunch(procedure)
            }
        }
    }
}

// MARK: - Properties of the Process

public extension ProcessProcedure {

    /// The processIdentifier for the started Process.
    ///
    /// This value is 0 until the ProcessProcedure executes and starts the Process.
    ///
    /// To retrieve the processIdentifier as soon as it is available,
    /// access it inside the ProcessDidLaunch callback (added to the ProcessProcedure).
    ///
    /// The processIdentifier remains non-zero after the ProcessProcedure starts the
    /// Process - even after the Process terminates. Do not assume based on a non-zero
    /// processIdentifier that the expected associated Process is still running.
    public fileprivate(set) var processIdentifier: Int32 {
        get { return stateLock.withCriticalScope { _processIdentifier } }
        set {
            stateLock.withCriticalScope {
                _processIdentifier = newValue
            }
        }
    }
}

// MARK: - Configuration Properties (Read-only)

public extension ProcessProcedure {

    /// (Read-only) The command arguments that should be used to launch the executable.
    var arguments: [String]? {
        get { return input.value?.arguments }
    }

    /// (Read-only) The current directory to be used when launching the executable.
    var currentDirectoryURL: URL? {
        get { return input.value?.currentDirectoryURL }
    }

    /// (Read-only) The environment to be used when launching the executable.
    var environment: [String : String]? {
        get { return input.value?.environment }
    }

    /// (Read-only) The path (URL) for the executable to be launched.
    var executableURL: URL? {
        get { return input.value?.executableURL }
    }

    /// (Read-only) The standard error (FileHandle or Pipe object).
    var standardError: Any? {
        get { return input.value?.standardError }
    }

    /// (Read-only) The standard input (FileHandle or Pipe object).
    var standardInput: Any? {
        get { return input.value?.standardInput }
    }

    /// (Read-only) The standard output (FileHandle or Pipe object).
    var standardOutput: Any? {
        get { return input.value?.standardOutput }
    }
}

// MARK: - Process Suspend / Resume

public extension ProcessProcedure {

    /// Resumes execution of the ProcessProcedure's Process that had previously been suspended with
    /// a call to suspend().
    ///
    /// See the documentation for Process.resume():
    /// https://developer.apple.com/reference/foundation/process/1407819-resume
    ///
    /// If multiple `suspend()` messages were sent to the receiver, an equal number of `resume()`
    /// messages must be sent before the task resumes execution.
    ///
    /// Calling `resume()` when the ProcessProcedure is not executing (i.e. before it executes or
    /// after it finishes) has no effect and returns false.
    ///
    /// - parameter completion: A completion block that is called with the result of the resume() call
    func resume(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let procedure = self else { return }
            guard procedure.isExecuting else {
                completion(false)
                return
            }
            let result = procedure.process?.resume() ?? false
            completion(result)
        }
    }

    /// Suspends execution of the ProcessProcedure's Process.
    ///
    /// See the documentation for Process.suspend():
    /// https://developer.apple.com/reference/foundation/process/1411590-suspend
    ///
    /// Multiple `suspend()` messages can be sent, but they must be balanced with an equal number of
    /// `resume()` messages before the Process resumes execution.
    ///
    /// Calling `suspend()` when the ProcessProcedure is not executing (i.e. before it executes or
    /// after it finishes) has no effect and returns false.
    ///
    /// - parameter completion: A completion block that is called with the result of the suspend() call
    func suspend(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let procedure = self else { return }
            guard procedure.isExecuting else {
                completion(false)
                return
            }
            let result = procedure.process?.suspend() ?? false
            completion(result)
        }
    }
}

fileprivate extension ProcessProcedure {

    fileprivate func createProcess(withRequest request: LaunchRequest) -> Process {
        let process = Process()

        #if swift(>=3.2)
            if #available(OSX 10.13, *) {
                process.executableURL = request.executableURL
                if let currentDirectoryURL = request.currentDirectoryURL {
                    process.currentDirectoryURL = currentDirectoryURL
                }
            }
            else {
                // Versions of macOS < 10.13 only support string-based paths
                process.launchPath = request.executableURL.path
                if let currentDirectoryPath = request.currentDirectoryURL?.path {
                    process.currentDirectoryPath = currentDirectoryPath
                }
            }
        #else
            process.launchPath = request.executableURL.path
            if let currentDirectoryPath = request.currentDirectoryURL?.path {
                process.currentDirectoryPath = currentDirectoryPath
            }
        #endif
        if let arguments = request.arguments {
            process.arguments = arguments
        }
        if let environment = request.environment {
            process.environment = environment
        }
        if let standardError = request.standardError {
            process.standardError = standardError
        }
        if let standardInput = request.standardInput {
            process.standardInput = standardInput
        }
        if let standardOutput = request.standardOutput {
            process.standardOutput = standardOutput
        }
        return process
    }

    #if swift(>=3.2)
    // On macOS 10.13+, new methods on Process are available that throw errors
    // (instead of raising Objective-C exceptions). This method uses them if
    // possible.
    fileprivate func run(process: Process) throws {
        if #available(OSX 10.13, *) {
            try process.run()
        }
        else {
            // macOS < 10.13 only support the launch() method, which may throw an ObjC exception
            process.launch()
        }
    }
    #else
    fileprivate func run(process: Process) throws {
        // Earlier SDKs only support Process.launch()
        process.launch()
    }
    #endif
}

// MARK: - Unavailable

public extension ProcessProcedure {

    @available(*, unavailable, renamed: "executableURL")
    var launchPath: String? { fatalError("Use executableURL") }

    @available(*, unavailable, renamed: "currentDirectoryURL")
    var currentDirectoryPath: String? { fatalError("Use currentDirectoryURL") }
}
