//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit
import Dispatch

open class ProcessProcedure: Procedure {

    /// Error type for ProcessProcedure
    public enum Error: Swift.Error, Equatable {
        case terminationReason(Process.TerminationReason)

        public static func == (lhs: ProcessProcedure.Error, rhs: ProcessProcedure.Error) -> Bool {
            switch (lhs, rhs) {
            case let (.terminationReason(lhsReason), .terminationReason(rhsReason)):
                return lhsReason == rhsReason
            }
        }
    }

    /// Closure type for testing if the task did exit cleanly
    public typealias ProcessDidExitCleanly = (Int) -> Bool

    /// The default closure for checking the exit status
    public static let defaultProcessDidExitCleanly: ProcessDidExitCleanly = { status in
        switch status {
        case 0: return true
        default: return false
        }
    }

    // - returns process: the Process
    fileprivate let process: Process

    /// - returns processDidExitCleanly: the closure for exiting cleanly.
    private let processDidExitCleanly: ProcessDidExitCleanly

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
    ///   - processDidExitCleanly: a ProcessDidExitCleanly closure with a default.
    public init(launchPath: String, arguments: [String]? = nil, currentDirectoryPath: String? = nil, environment: [String : String]? = nil, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil, processDidExitCleanly: @escaping ProcessDidExitCleanly = ProcessProcedure.defaultProcessDidExitCleanly) {

        let process = Process()
        process.launchPath = launchPath
        if let arguments = arguments {
            process.arguments = arguments
        }
        if let currentDirectoryPath = currentDirectoryPath {
            process.currentDirectoryPath = currentDirectoryPath
        }
        if let environment = environment {
            process.environment = environment
        }
        if let standardError = standardError {
            process.standardError = standardError
        }
        if let standardInput = standardInput {
            process.standardInput = standardInput
        }
        if let standardOutput = standardOutput {
            process.standardOutput = standardOutput
        }

        self.process = process
        self.processDidExitCleanly = processDidExitCleanly
        super.init()

        addDidCancelBlockObserver { procedure, errors in
            DispatchQueue.main.async {
                guard procedure.isExecuting && procedure.process.isRunning else { return }
                procedure.process.terminate()
            }
        }
    }

    open override func execute() {
        // NOTE: NSTask/Process is *not* thread-safe.
        // See: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html#//apple_ref/doc/uid/10000057i-CH12-125664
        //
        // It's not a good idea to call `launch()` on a thread that may disappear before the
        // NSTask/Process goes away. Thus, we use the main queue/thread.

        DispatchQueue.onMain { [weak self] in
            guard let procedure = self else { return }

            procedure.process.terminationHandler = { [weak procedure] task in
                guard let procedure = procedure else { return }

                if procedure.processDidExitCleanly(Int(procedure.process.terminationStatus)) {
                    procedure.finish()
                }
                else {
                    procedure.finish(withError: Error.terminationReason(procedure.process.terminationReason))
                }
            }

            guard !procedure.isCancelled else { return }
            procedure.process.launch()
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
    /// access it inside a DidExecuteObserver (added to the ProcessProcedure).
    var processIdentifier: Int32 {
        get {
            return DispatchQueue.onMain { process.processIdentifier }
        }
    }
}

// MARK: - Configuration Properties (Read-only)

public extension ProcessProcedure {

    /// (Read-only) The command arguments that should be used to launch the executable.
    var arguments: [String]? {
        get { return DispatchQueue.onMain { process.arguments } }
    }

    /// (Read-only) The current directory to be used when launching the executable.
    var currentDirectoryPath: String {
        get { return DispatchQueue.onMain { process.currentDirectoryPath } }
    }

    /// (Read-only) The environment to be used when launching the executable.
    var environment: [String : String]? {
        get { return DispatchQueue.onMain { process.environment } }
    }

    /// (Read-only) The path to the executable to be launched.
    var launchPath: String {
        get { return DispatchQueue.onMain { process.launchPath! } }
    }

    /// (Read-only) The standard error (FileHandle or Pipe object).
    var standardError: Any? {
        get { return DispatchQueue.onMain { process.standardError } }
    }

    /// (Read-only) The standard input (FileHandle or Pipe object).
    var standardInput: Any? {
        get { return DispatchQueue.onMain { process.standardInput } }
    }

    /// (Read-only) The standard output (FileHandle or Pipe object).
    var standardOutput: Any? {
        get { return DispatchQueue.onMain { process.standardOutput } }
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
            let result = procedure.process.resume()
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
            let result = procedure.process.suspend()
            completion(result)
        }
    }
}
