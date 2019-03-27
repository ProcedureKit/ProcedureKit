//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation
import os

internal struct ProcedureKit {

    fileprivate enum FinishingFrom: CustomStringConvertible {
        case main, finish
        var description: String {
            switch self {
            case .main: return "main()"
            case .finish: return "finish()"
            }
        }
    }

    fileprivate enum State: Int, Comparable {

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case initialized
        case willEnqueue
        case pending
        case started
        case executing
        case finishing
        case finished

        func canTransition(to other: State, whenCancelled isCancelled: Bool) -> Bool {
            switch (self, other) {
            case (.initialized, .willEnqueue),
                 (.willEnqueue, .pending),
                 (.pending, .started),
                 (.started, .executing),
                 (.executing, .finishing),
                 (.finishing, .finished):
                return true

            case (.started, .finishing):
                // Once a Procedure has started, it can go direct to finishing.
                return true

            default:
                return false
            }
        }
    }

    @available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *)
    internal struct Signposts {

        internal static let procedure: OSLog = {
            return OSLog(subsystem: "run.kit.procedure", category: "ProcedureKit")
        }()
    }

    private init() { }
}

public enum ProcedureStatus: String {
    case pending, executing, cancelled, failed, finished
}


/**
 Type to express the intent of the user in regards to executing an Operation instance

 - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
 */
@available(*, deprecated, message: "Use underlying quality of service APIs instead.")
@objc public enum UserIntent: Int {
    case none = 0, sideEffect, initiated

    internal var qualityOfService: QualityOfService {
        switch self {
        case .initiated, .sideEffect:
            return .userInitiated
        default:
            return .default
        }
    }
}


/**
 Procedure is an Operation subclass. It is an abstract class which should be subclassed.

 ```swift
 import ProcedureKit

 class MyFirstProcedure: Procedure {
     override func execute() {
         guard !isCancelled else { return }
         print("Hello World")
         finish()
     }
 }

 let queue = ProcedureQueue()
 let myProcedure = MyFirstProcedure()
 queue.addOperation(myProcedure)
 ```

 The key points here are:

 1. Subclass `Procedure`
 2. Override `execute` but do not call `super.execute()`
 3. Check the `isCancelled` property before starting any work.
 4. If not cancelled, always call `finish()` after the work is done. This could be done asynchronously.
 5. Add procedures to instances of `ProcedureQueue`.

 ### Built-in Procedures

 ProcedureKit includes a number of built-in Procedure subclasses, such as `GroupProcedure`,
 `RetryProcedure`, `RepeatProcedure`. Many of these built-in subclasses can be used as-is
 (without subclassing them). See their documentation for information on what they do and
 how to utilize them.

 ### Cancellation

 Once you add a Procedure to a ProcedureQueue, the queue takes over and handles the
 scheduling of the task at some point in the future (based on dependencies, and
 qualityOfService, etc).

 If you later decide that you do not want to execute the procedure after all, you can cancel
 the procedure to prevent it from running needlessly. You do this by calling the `cancel()`
 method on the Procedure instance itself.

 Cancelling a Procedure before it has been started by the queue will cause the queue to:
    - Ignore any unfinished dependencies
    - Automatically finish the Procedure (without calling your `execute()` override)

 This helps clear the cancelled Procedure from the queue as quickly as possible. Since it
 hasn't yet started to execute, the framework can help handle this case for you.

 However, cancelling a Procedure that has already been started by the queue will *not*
 automatically stop it from executing. It is the responsibility of your Procedure subclass,
 once it has started to execute, to check its cancelled state and respond to cancellation
 by finishing as quickly as possible.

 You can implement this via two different methods:
    1. Checking `isCancelled` periodically (for example, in your `execute()` override)
    2. Adding a DidCancel observer or overriding `produceDidCancel(withErrors:)`, which will be called after your Procedure is cancelled.

 Which method you should use is likely determined by how your Procedure performs the
 bulk of its task (synchronously - in its `execute()` override - or asynchronously, for
 which a DidCancel observer may be more useful).
 */
open class Procedure: Operation, ProcedureProtocol {

    private var _isTransitioningToExecuting = false
    private var _isHandlingCancel = false
    private var _isCancelled = false  // should always be set by .cancel()
    private var _isHandlingFinish: Bool = false

    fileprivate let isAutomaticFinishingDisabled: Bool

    // A strong reference to the ProcedureQueue onto which this Procedure was added
    // This is cleared when the Procedure finishes
    private var _queue: ProcedureQueue?

    fileprivate var procedureQueue: ProcedureQueue? {
        get { return stateLock.withCriticalScope { _queue } }
    }

    // Stored pending finish information
    // (used if a Procedure is cancelled and finish() is called prior to the queue
    // starting the Procedure - see `shouldFinish`)
    fileprivate struct FinishingInfo {
        var error: Error?
        var source: ProcedureKit.FinishingFrom
    }
    private var _pendingFinish: FinishingInfo?

    // only accessed from within the EventQueue
    private var pendingAutomaticFinish: FinishingInfo?
    private var finishedHandlingCancel: Bool = false

    // The Procedure's EventQueue
    // A serial FIFO queue onto which all Procedure Events that call user code are dispatched.
    // (ex. `execute()` overrides, observer callbacks, etc.)
    public let eventQueue = EventQueue(label: "run.kit.procedure.ProcedureKit.Procedure.EventQueue")

    /**
     Expresses the user intent in regards to the execution of this Procedure.

     Setting this property will set the appropriate quality of service parameter
     on the parent Operation.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     */
    @available(*, deprecated, message: "Use underlying quality of service APIs instead.")
    public var userIntent: UserIntent = .none

    @available(OSX 10.10, iOS 8.0, tvOS 8.0, watchOS 2.0, *)
    open override var qualityOfService: QualityOfService {
        get { return super.qualityOfService }
        set {
            super.qualityOfService = newValue
            eventQueue.qualityOfService = newValue.qos
        }
    }

    open override var name: String? {
        didSet {
            synchronise {
                let formatter = Log.Formatters.makeProcedureLogFormatter(operationName: operationName)
                protectedProperties.log.formatter = formatter
                protectedProperties.log.formatter = formatter
            }
        }
    }

    internal let uuid = UUID()

    internal var typeDescription: String {
        return String(describing: type(of: self))
    }

    internal class ProcedureQueueContext { }
    internal let queueAddContext = ProcedureQueueContext()

    deinit {
        // ensure that any EvaluateConditions operation is cancelled
        evaluateConditionsProcedure?.cancel()

        // ensure that the Protected Properies are deinitialized within the lock
        stateLock.withCriticalScope {
            self.protectedProperties = nil
            _evaluateConditionsProcedure = nil
        }
    }

    // MARK: - State

    fileprivate let stateLock = PThreadMutex()

    @discardableResult
    fileprivate func synchronise<T>(block: () -> T) -> T {
        return stateLock.withCriticalScope(block: block)
    }

    // the state variable to be used *within* the stateLock
    fileprivate var _state = ProcedureKit.State.initialized { // swiftlint:disable:this variable_name
        willSet(newState) {
            assert(_state.canTransition(to: newState, whenCancelled: _isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity). Ensure that Procedure instances are added to a ProcedureQueue not an OperationQueue.")
        }
    }

    // the state variable to be used *outside* the stateLock
    fileprivate private(set) var state: ProcedureKit.State {
        get {
            return synchronise { _state }
        }
        set(newState) {
            synchronise { _state = newState }
        }
    }

    /// Boolean indicator for whether the Procedure has been enqueued
    final public var isEnqueued: Bool {
        return synchronise { _isEnqueued }
    }

    /// Boolean indicator for whether the Procedure is pending
    final public var isPending: Bool {
        return synchronise { _isPending }
    }

    /// Boolean indicator for whether the Procedure is currently executing or not
    final public override var isExecuting: Bool {
        return synchronise { _isExecuting }
    }

    /// Boolean indicator for whether the Procedure has finished or not
    final public override var isFinished: Bool {
        return synchronise { _isFinished }
    }

    public var status: ProcedureStatus {
        return synchronise {
            switch (_isPending, _isExecuting, _isFinished, _isCancelled, (_error != nil)) {
            case (true, _, _, _, _):
                return .pending
            case (_, true, _, _, _):
                return .executing
            case (_, _, true, _, _):
                return .finished
            case (_, _, _, true, _):
                return .cancelled
            case (_, _, _, _, true):
                return .failed
            default:
                return .finished
            }
        }
    }

    private var _mutuallyExclusiveCategories: Set<String>?
    private var mutuallyExclusiveCategories: Set<String>? {
        get { return synchronise { _mutuallyExclusiveCategories } }
        set { synchronise { _mutuallyExclusiveCategories = newValue } }
    }
    private var _mutualExclusivityTicket: ProcedureQueue.ExclusivityLockTicket?
    private var mutualExclusivityTicket: ProcedureQueue.ExclusivityLockTicket? {
        get { return synchronise { _mutualExclusivityTicket } }
        set { synchronise { _mutualExclusivityTicket = newValue } }
    }

    // Only called by the ConditionEvaluator
    fileprivate func request(mutuallyExclusiveCategories: Set<String>, completion: @escaping (Bool) -> Void) {
        // On the internal EventQueue
        dispatchEvent {
            guard self.state < .started else {
                // If the Procedure has already started or finished, it's too late to acquire mutual
                // exclusivity locks. This can occur, normally, if a Procedure is cancelled (and then
                // finished) at just the right time.
                guard self.isCancelled else {
                    fatalError("Procedure started prior to acquiring mutual exclusivity locks, but is not cancelled.")
                }

                // Immediately call the completion block, with false
                completion(false)
                return
            }
            guard let procedureQueue = self.procedureQueue else {
                fatalError("procedureQueue is nil")
            }

            // Store the mutually-exclusive categories for later release (when the Procedure is finished).
            assert(self.mutuallyExclusiveCategories == nil, "Mutually exclusive locks were requested more than once.")
            self.mutuallyExclusiveCategories = mutuallyExclusiveCategories

            // Request a lock via the ProcedureQueue
            procedureQueue.requestLock(for: mutuallyExclusiveCategories) { lockTicket in
                // Once a lock ticket is acquired, store the lockTicket
                // (which must be claimed once the Procedure starts)

                self.mutualExclusivityTicket = lockTicket

                // and call the completion block
                completion(true)
            }
        }
    }

    /// Boolean indicator for whether the Procedure is cancelled or not
    ///
    /// Canceling a Procedure does not actively stop the Procedure's code from executing.
    ///
    /// An executing Procedure is responsible for checking its own cancellation status,
    /// and stopping and moving to the finished state as quickly as possible.
    ///
    /// Built-in Procedure subclasses in ProcedureKit (like GroupProcedure and CloudKitProcedure)
    /// handle responding to cancellation as appropriate.
    ///
    final public override var isCancelled: Bool {
        return synchronise { _isCancelled }
    }

    /// The Boolean indicators to be used *within* the stateLock
    private var _isEnqueued: Bool {
        return _state >= .pending
    }
    private var _isPending: Bool {
        return _state == .pending
    }
    private var _isExecuting: Bool {
        return _state == .executing
    }
    private var _isFinished: Bool {
        return _state == .finished
    }

    // MARK: - Protected Internal Properties

    fileprivate var _evaluateConditionsProcedure: EvaluateConditions? // swiftlint:disable:this variable_name

    // Grouped in a class to allow for easily deinitializing in `deinit`.
    fileprivate class ProtectedProperties {
        var log: ProcedureLog = Log.Channels<Log>()
        var error: Error? = nil
        var observers = [AnyObserver<Procedure>]()
        var directDependencies = Set<Operation>()
        var conditions = Set<Condition>()
    }

    fileprivate var protectedProperties: ProtectedProperties! = ProtectedProperties() // see deinit

    // the errors variable to be used *within* the stateLock
    private var _error: Error? {
        return protectedProperties.error
    }

    // MARK: - Errors

    final public var error: Error? {
        get { return synchronise { _error } }
        set {
            synchronise {
                guard _state <= .executing else {
                    assertionFailure("Cannot append errors to Procedure that is finishing or finished.")
                    return
                }
                protectedProperties.error = newValue
            }
        }
    }

    // MARK: - Log

    /**
     Access the logger for this Operation

     The `log` property can be used as the interface to access the logger.
     e.g. to output a message with `LogSeverity.Info` from inside
     the `Procedure`, do this:

     ```swift
     log.info("This is my message")
     ```

     To adjust the instance severity of the LoggerType for the
     `Procedure`, access it via this property too:

     ```swift
     log.severity = .Verbose
     ```

     The logger is a very simple type, and all it does beyond
     manage the enabled status and severity is send the String to
     a block on a dedicated serial queue. Therefore to provide custom
     logging, set the `logger` property:

     ```swift
     log.logger = { message in sendMessageToAnalytics(message) }
     ```

     By default, the Logger's logger block is the same as the global
     LogManager. Therefore to use a custom logger for all Operations:

     ```swift
     LogManager.logger = { message in sendMessageToAnalytics(message) }
     ```

     */
    final public var log: ProcedureLog {
        get { return synchronise { protectedProperties.log } }
        set { synchronise { protectedProperties.log = newValue } }
    }

    // MARK: - Observers

    final internal var observers: [AnyObserver<Procedure>] {
        get { return synchronise { protectedProperties.observers } }
    }

    // MARK: - Dependencies & Conditions

    internal var directDependencies: Set<Operation> {
        get { return synchronise { protectedProperties.directDependencies } }
    }

    /// - returns conditions: the Set of Condition instances attached to the operation
    public var conditions: Set<Condition> {
        get { return synchronise { protectedProperties.conditions } }
    }

    /// Internal for testing.
    internal var evaluateConditionsProcedure: EvaluateConditions? {
        return synchronise { _evaluateConditionsProcedure }
    }

    // MARK: - Initialization

    public override init() {
        isAutomaticFinishingDisabled = false
        super.init()
        name = String(describing: type(of: self))

        // Add a signpost observer to every procedure        
        if #available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *) {
            addObserver(SignpostObserver())
        }
    }

    // MARK: - Disable Automatic Finishing

    /**
     Ability to override Procedure's built-in finishing behavior, if a
     subclass requires full control over when `finish()` is called.

     Used for GroupProcedure to implement proper .Finished state-handling
     (only finishing after all child operations have finished).

     The default behavior of Procedure is to automatically call `finish()`
     when:
     (a) the Procedure is cancelled prior to it starting
         (in which case, the Procedure will skip calling `execute()`)
     (b) when willExecuteObservers log errors

     To ensure that a Procedure subclass does not finish until the
     subclass calls `finish()`:
     call `super.init(disableAutomaticFinishing: true)` in the init.

     - Important: If `disableAutomaticFinishing == TRUE`, the subclass is
     responsible for calling `finish()` in **ALL** cases, including when the
     Procedure is cancelled.

     You can react to cancellation using a `DidCancelObserver` and/or
     checking periodically during `execute()` with something like:

     ```swift
     guard !cancelled else {
        // do any necessary clean-up
        finish()    // always call finish if automatic finishing is disabled
        return
     }
     ```

     */
    public init(disableAutomaticFinishing: Bool) {
        isAutomaticFinishingDisabled = disableAutomaticFinishing
        super.init()
        name = String(describing: type(of: self))
        if #available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *) {
            addObserver(SignpostObserver())
        }
    }

    // MARK: - Execution

    /// Called by the framework before a Procedure is added to a ProcedureQueue.
    ///
    /// - warning: Do *NOT* call this function directly.
    ///
    /// - Parameter queue: the ProcedureQueue onto which the Procedure will be added
    public final func willEnqueue(on queue: ProcedureQueue) {
        synchronise {
            _state = .willEnqueue
            _queue = queue
        }
    }

    /// Called by the framework before a Procedure is added to a ProcedureQueue, but *after*
    /// the ProcedureQueue delegate's `procedureQueue(_:willAddProcedure:context:)` is called.
    ///
    /// - warning: Do *NOT* call this function directly.
    public final func pendingQueueStart() {
        let optionalConditionEvaluator: EvaluateConditions? = synchronise {
            _state = .pending

            // After the state has been set to `.willEnqueue` (via an earlier call
            // to `willEnqueue(on:)`), Procedure conditions cannot be modified.
            //
            // `pendingQueueStart()` is called *after* the ProcedureQueue
            // delegate's `procedureQueue(_:willAddProcedure:context:)` is called,
            // but *before* the Procedure is actually added to the queue. Thus:
            //  - the delegate's willAdd method has had a chance to add any dependencies to
            //    the Procedure (which _must_ be picked up and added as dependencies to the
            //    EvaluateConditions operation)
            //  - the Procedure will not be executed by the queue until this method returns
            //
            // Thus, construct the EvaluateConditions procedure now (if needed).
            guard !protectedProperties.conditions.isEmpty else { return nil }

            // If the Procedure is cancelled, there is no point to evaluating Conditions
            guard !_isCancelled else { return nil }

            // Create the EvaluateConditions operation
            let evaluator = EvaluateConditions(procedure: self)
            evaluator.name = "\(operationName) Evaluate Conditions"

            // Add the direct dependencies of the procedure as direct dependencies of the evaluator
            // (to ensure that conditions are evaluated after all of the Procedure's dependencies)
            let directDependencies = protectedProperties.directDependencies
            evaluator.addDependencies(directDependencies)

            // Store the evaluator in the Procedure
            // (the Procedure maintains a strong reference to the EvaluateConditions operation)
            assert(_evaluateConditionsProcedure == nil)
            _evaluateConditionsProcedure = evaluator

            return evaluator
        }

        guard let evaluator = optionalConditionEvaluator else { return }

        // The Procedure must be dependent on its condition evaluator.
        // Call super.addDependency so the evaluator isn't added to the visible
        // `directDependencies`, but *is* treated as a dependency by the underlying
        // Operation.
        super.addDependency(evaluator)
    }

    /// Called by the framework after a Procedure is added to a ProcedureQueue.
    /// The Procedure may have already been scheduled for / started executing.
    /// This is only used to manage when it's safe to begin evaluating conditions.
    internal final func postQueueAdd() {
        guard let evaluateConditionsProcedure = evaluateConditionsProcedure else { return }

        // If this Procedure has a condition evaluator, the condition evaluator must not
        // finish prior to the return of the internal OperationQueue.addOperation() call
        // in ProcedureQueue that adds this Procedure to the ProcedureQueue's underlying
        // OperationQueue.
        //
        // (If the EvaluateConditions operation finishes while the underlying OperationQueue
        // implementation is in the process of adding the operation, a rare race condition may
        // be triggered with NSOperationQueue's handling of the Operation isReady state for
        // the Procedure. This can result in a situation in which a Procedure with, for
        // example, failing conditions ends up cancelled + ready but never finishes.)
        //
        // To accomplish this, signal to the EvaluateConditions operation that it is now safe 
        // (post-add) to begin evaluating conditions (assuming it is otherwise ready).

        evaluateConditionsProcedure.parentProcedureHasBeenAddedToQueue()
    }

    /// Starts the Procedure, correctly managing the cancelled state. Cannot be over-ridden
    ///
    /// - warning: Do not call `start()` directly on a Procedure. Add the Procedure to a `ProcedureQueue`.
    public final override func start() {
        // Don't call super.start

        assert(state >= .pending, "Calling start() manually on a Procedure is unsupported. Instead, add the Procedure to a ProcedureQueue.") // Do not check for < .started here; _start() does that.
        assert(procedureQueue != nil, "The Procedure's associated procedureQueue is nil. If you are adding the Procedure to a ProcedureQueue, this should never happen.")

        // Dispatch the innards of start() on the EventQueue,
        // inheriting the current QoS level (i.e. the Qos that
        // the ProcedureQueue decided to use to call start()).

        let currentQoS = DispatchQoS(qosClass: DispatchQueue.currentQoSClass, relativePriority: 0)

        eventQueue.dispatchEventBlockInternal(minimumQoS: currentQoS) {
            self._start()
        }
    }

    private final func _start() {

        debugAssertIsOnEventQueue() // should only be executed on the EventQueue

        // NOTE: The EventQueue handles ensuring proper autoreleasepool behavior,
        // so there is no need for an explicit autoreleasepool here.

        assert(state < .started, "A Procedure cannot be started more than once.")

        let hasPendingFinish = synchronise { () -> FinishingInfo? in
            _state = .started
            return _pendingFinish
        }

        if let pendingFinish = hasPendingFinish {
            assert(isCancelled)
            // A call to finish occurred prior to the Procedure starting (but after it was cancelled)
            // Handle this pending finish now, and skip processing execute
            _finish(withInfo: pendingFinish)
            return
        }

        guard !isCancelled || isAutomaticFinishingDisabled else {
            queueAutomaticFinish(from: .main)
            return
        }

        _main()
    }

    /// - warning: Do not call `main()` directly on a Procedure. Add the Procedure to a `ProcedureQueue`.
    public final override func main() {
        assertionFailure("Do not call main() directly on a Procedure. Add the Procedure to a ProcedureQueue.")
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    private final func _main() {

        debugAssertIsOnEventQueue()

        assert(state >= .started, "Procedure.main() is being called when Procedure.start() has not been called. Do not call main() directly. Add the Procedure to a ProcedureQueue.")

        if let mutualExclusivityTicket = mutualExclusivityTicket {
            // Mutual Exclusivity has been requested for this Procedure
            // Proceed only once the ticket has been claimed via the ProcedureQueue

            guard let procedureQueue = procedureQueue else {
                fatalError("Procedure has a nil procedureQueue") // ProcedureKit internal programmer error
            }

            // Store the current QoS level
            let originalQoS = DispatchQoS(qosClass: DispatchQueue.currentQoSClass, relativePriority: 0)

            // Now that the Procedure has started, claim the mutual exclusivity lock
            procedureQueue.procedureClaimLock(withTicket: mutualExclusivityTicket) {
                // Mutual Exclusivity lock has been claimed - can now proceed with executing

                // Dispatch the innards of main() on the EventQueue,
                // inheriting the original QoS level (i.e. the Qos that
                // the ProcedureQueue decided to use to call start()).

                self.eventQueue.dispatchEventBlockInternal(minimumQoS: originalQoS) {
                    self._main_step1()
                }
            }
        }
        else {
            // No Mutual Exclusivity required - proceed immediately with the next steps of executing
            _main_step1()
        }
    }

    private final func _main_step1() {

        debugAssertIsOnEventQueue()

        log.verbose.trace()
        log.verbose.message("[observers]: WillExecute")

        // Call the WillExecute observers
        let willExecuteObserversGroup = dispatchObservers(pendingEvent: PendingEvent.execute) { observer, pendingEvent in
            observer.will(execute: self, pendingExecute: pendingEvent)
        }

        // After the WillExecute observers have all completed, proceed to Step 2 of main()
        // Inherit the current QoS level to ensure that the QoS level of start() persists through to execute()
        optimizedDispatchEventNotify(group: willExecuteObserversGroup, inheritQoS: true) {
            self._main_step2()
        }
    }

    private final func _main_step2() { // swiftlint:disable:this function_body_length

        debugAssertIsOnEventQueue()

        // Prevent concurrent execution
        func getNextState() -> ProcedureKit.State? {
            return synchronise {

                // Check to see if the procedure is already attempting to execute
                assert(!_isExecuting, "Procedure is attempting to execute, but is already executing.")
                guard !_isTransitioningToExecuting else {
                    assertionFailure("Procedure is attempting to execute twice, concurrently.")
                    return nil
                }

                // Check to see if the procedure has now been finished
                // by an observer (or anything else)
                guard _state <= .started else { return nil }
                guard !_isHandlingFinish else {
                    // a finish is pending, simply exit from processing execute
                    return nil
                }

                // Check to see if the procedure has now been cancelled
                // by an observer
                guard ((_error == nil) && !_isCancelled) || isAutomaticFinishingDisabled else {
                    return .finishing
                }

                // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
                _isTransitioningToExecuting = true
                return .executing
            }
        }

        // Check the state again, as it could have changed in another queue via finish
        func getNextStateAgain() -> (ProcedureKit.State?, ProcedureQueue?) {
            return synchronise {
                guard _state <= .started else { return (nil, nil) }

                guard !_isHandlingFinish else {
                    // a finish is pending, simply exit from processing execute
                    return (nil, nil)
                }

                if _isCancelled && !isAutomaticFinishingDisabled && !_isHandlingFinish {
                    // Procedure was cancelled, and automatic finishing is enabled.
                    // Because execute() has not yet been called, handle finish here.
                    return (.finishing, nil)
                }

                _state = .executing
                _isTransitioningToExecuting = false

                return (.executing, _queue)
            }
        }

        log.verbose.trace()
        log.verbose.message("[event]: Continue Pending Execute")

        // Determine the next Procedure state (prepare to set to executing, if possible)
        let nextState = getNextState()

        guard nextState != .finishing else {
            // The Procedure should transition to finishing
            // (for example, if cancelled prior to execute())
            queueAutomaticFinish(from: .main)
            return
        }

        guard nextState == .executing else { return }

        willChangeValue(forKey: .executing)

        // Set the state to executing (unless something, like cancellation, has happened concurrently)
        let (nextState2, queue) = getNextStateAgain()

        didChangeValue(forKey: .executing)

        guard nextState2 != .finishing else {
            // The Procedure should transition to finishing
            // (for example, if cancelled prior to execute())
            queueAutomaticFinish(from: .main)
            return
        }

        guard nextState2 == .executing else { return }

        log.verbose.message("Will Execute")

        // Call the execute() function (which should be overriden in Procedure subclasses)
        if let underlyingQueue = queue?.underlyingQueue {
            // The Procedure was enqueued on a ProcedureQueue that specifies an `underlyingQueue`.
            //
            // Explicitly call the `execute()` function on the underlyingQueue, while also
            // pausing dispatch of any new blocks on the Procedure's EventQueue until the call
            // to `execute()` returns, to ensure that `execute()` occurs on the underlyingQueue
            // *and* non-concurrently with this Procedure's EventQueue.

            eventQueue.dispatchSynchronizedBlock(onOtherQueue: underlyingQueue) {
                // This block is now synchronized with *both* queues:
                //  - the Procedure's EventQueue
                //  - the underlyingQueue of the ProcedureQueue on which the Procedure is scheduled to execute
                // and is *on* the underlyingQueue of said ProcedureQueue.

                // Call the `execute()` function on the underlyingQueue
                self.execute()

                // Dispatch async back to the Procedure's EventQueue to
                // process DidExecute observers.
                self.dispatchEvent {
                    self._handleDidExecute()
                }
            }
            return
        }

        execute()
        _handleDidExecute()
    }

    private func _handleDidExecute() {

        debugAssertIsOnEventQueue()

        // Dispatch DidExecute observers
        log.verbose.trace()
        log.verbose.message("[observers]: DidExecute")
        _ = dispatchObservers(pendingEvent: PendingEvent.postDidExecute) { observer, _ in
            observer.did(execute: self)
        }

        // Log that execute() has returned
        log.info.message("Did Execute")
    }

    /// Procedure subclasses must override `execute()`.
    /// - important: Do not call `super.execute()` when subclassing `Procedure` directly.
    open func execute() {
        log.warning.message("\(self) must override `execute()`.")
        finish()
    }

    /// Adds an operation to the same queue as target.
    ///
    /// - Precondition: Target must already be added to a queue / `GroupProcedure`.
    /// - Parameters:
    ///   - operation: The operation to add to the same queue as target.
    ///   - pendingEvent: (optional) A PendingEvent. The operation will be added prior to the PendingEvent.
    /// - Returns: A `ProcedureFuture` that is completed once the operation has been added to the queue.
    /// - Throws: `ProcedureKitError.noQueue` if the target has not yet been added to a queue / `GroupProcedure`.
    @discardableResult public final func produce(operation: Operation, before pendingEvent: PendingEvent? = nil) throws -> ProcedureFuture {
        precondition(state > .initialized, "Cannot add operation which is not being scheduled on a queue")
        guard let queue = synchronise(block: { return _queue }) else {
            throw ProcedureKitError.noQueue()
        }

        let promise = ProcedurePromise()

        log.verbose.trace()
        log.verbose.message(".produce() | Will add \(operation.operationName)")

        // Dispatch the innards of produce() onto the EventQueue
        dispatchEvent {
            self._produce(operation: operation, onQueue: queue, before: pendingEvent, promise: promise)
        }

        return promise.future
    }

    private func _produce(operation: Operation, onQueue queue: ProcedureQueue, before pendingEvent: PendingEvent? = nil, promise: ProcedurePromise) {
        debugAssertIsOnEventQueue()

        log.verbose.trace()
        log.verbose.message(".produce() | [observers]: WillAddOperation(\(operation.operationName))")

        // Dispatch WillAddOperation observers
        let willAddObserversGroup = dispatchObservers(pendingEvent: PendingEvent.addOperation) { observer, _ in
            observer.procedure(self, willAdd: operation)
        }

        // After the WillAddOperation observers have all completed
        optimizedDispatchEventNotify(group: willAddObserversGroup) {
            // Proceed to step 2 of handling produce()
            self._produce_step2(operation: operation, onQueue: queue, before: pendingEvent, promise: promise)
        }
    }

    private func _produce_step2(operation: Operation, onQueue queue: ProcedureQueue, before pendingEvent: PendingEvent? = nil, promise: ProcedurePromise) {
        debugAssertIsOnEventQueue()

        log.verbose.trace()
        log.verbose.message(".produce() | [event]: AddOperation(\(operation.operationName)) to queue.")

        // Add the new produced operation to the ProcedureQueue on which this Procedure was added
        queue.addOperation(operation, withContext: queueAddContext).then(on: self) {

            // After adding to the queue completes, proceed to step 3 of handling produce()
            self._produce_step3(operation: operation, onQueue: queue, before: pendingEvent, promise: promise)
        }
    }

    private func _produce_step3(operation: Operation, onQueue queue: ProcedureQueue, before pendingEvent: PendingEvent? = nil, promise: ProcedurePromise) {

        log.verbose.trace()

        if let pendingEvent = pendingEvent {
            // Ensure that the PendingEvent occurs sometime after this point
            pendingEvent.doBeforeEvent {
                log.verbose.message("ProcedureQueue.add(\(operation.operationName)) called prior to (\(pendingEvent)).")
            }
        }

        log.info.message(".produce() | Did add \(operation.operationName)")

        log.verbose.message(".produce() | [observers]: DidAddOperation(\(operation.operationName))")

        // Complete the promise, since the produced operation has been added to the queue
        promise.complete()

        // Dispatch DidAddOperation observers
        _ = self.dispatchObservers(pendingEvent: PendingEvent.postDidAdd) { observer, _ in
            observer.procedure(self, didAdd: operation)
        }
        // no follow-up events to wait on the didAdd observers
    }

    // MARK: - Cancellation

    /**
     By default, cancelling a Procedure simply sets the `isCancelled` flag to true.

     It is the responsibility of the Procedure subclass to handle cancellation,
     as appropriate.

     For example, GroupProcedure handles cancellation by cancelling all of its
     children.

     You can react to cancellation using a DidCancelObserver
     and/or checking periodically during execute with something like:

     ```swift
     guard !isCancelled else {
        // do any necessary clean-up
        finish()    // always call finish when your Procedure is done
        return
     }
     ```

     */

    open func procedureDidCancel(with error: Error?) {
        // no-op
    }

    public final override func cancel() {
        _cancel(with: nil)
    }

    public final func cancel(with error: Error?) {
        _cancel(with: error)
    }

    // Micro-optimaization used by GroupProcedure to bypass dispatching to the event queue for its cancellation handling
    internal func _procedureDidCancel(with error: Error?) {
        // no-op
    }

    private enum ShouldCancelResult {
        case shouldCancel
        case alreadyFinishingOrFinished
        case alreadyCancelling
        case alreadyCancelled
    }

    private var shouldCancel: ShouldCancelResult {
        return synchronise {
            // Do not cancel if already finished or finishing, or if finish has already been called
            guard _state <= .executing && !_isHandlingFinish else { return .alreadyFinishingOrFinished }
            // Do not cancel if already cancelled
            guard !_isCancelled else { return .alreadyCancelled }
            // Only a single call to cancel should continue
            guard !_isHandlingCancel else { return .alreadyCancelling }
            _isHandlingCancel = true
            return .shouldCancel
        }
    }

    private final func _cancel(with error: Error?, promise: ProcedurePromise? = nil) {

        log.verbose.trace()

        let shouldCancel = self.shouldCancel

        guard shouldCancel == .shouldCancel else {
            promise?.complete()//(withFailure: shouldCancel.error ?? ProcedureKitError.unknown)
            return
        }

        // Immediately (and possibly concurrently with the EventQueue) set the `isCancelled`
        // state of the Procedure to true, sending appropriate KVO.

        willChangeValue(forKey: .cancelled)

        let resultingError = synchronise { () -> Error? in
            protectedProperties.error = error ?? protectedProperties.error
            _isCancelled = true
            return protectedProperties.error
        }

        if let error = resultingError {
            log.verbose.message("Will cancel with error: \(error).")
        }
        else {
            log.verbose.message("Will cancel without error.")
        }

        didChangeValue(forKey: .cancelled)

        // Call super to trigger .isReady state change on cancel as well as isReady KVO notification
        super.cancel()

        // Micro-optimization for built-in Procedures that can safely handle cancellation off the EventQueue
        _procedureDidCancel(with: error)

        // Cancel the EvaluateConditions operation (in case the Procedure is cancelled
        // before its dependencies have finished, and the EvaluateConditions operation
        // is still waiting on those dependencies).
        //
        // If the Procedure is cancelled before it is added to a queue, the
        // EvaluateConditions operation will not yet exist, and so must be handled
        // later.
        evaluateConditionsProcedure?.cancel()

        // Trigger DidCancel function & observers on the event queue
        dispatchEvent {

            // procedureDidCancel(withErrors:) override
            self.procedureDidCancel(with: resultingError)

            // DidCancel observers
            self.log.verbose.message("[observers]: DidCancel")
            let didCancelObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.postDidCancel) { observer, _ in
                observer.did(cancel: self, with: resultingError)
            }

            // After the DidCancel observers have all completed
            self.optimizedDispatchEventNotify(group: didCancelObserversGroup) {
                // Process the pending automatic finish (from main) if present

                self.finishedHandlingCancel = true

                if let pendingAutomaticFinish = self.pendingAutomaticFinish {
                    // Pass the pending automatic finish to finish()
                    // finish() will handle ensuring that only the first call to finish succeeds
                    // (i.e. if a DidCancel observer has already called finish, that call is the one
                    // that succeeds)
                    self.finish(with: pendingAutomaticFinish.error, from: pendingAutomaticFinish.source)

                    // Ensure that the EvaluateConditions operation is cancelled
                    self.evaluateConditionsProcedure?.cancel()
                }
            }

            promise?.complete()
        }
    }

    // MARK: - Finishing

    open func procedureWillFinish(with error: Error?) { }

    open func procedureDidFinish(with error: Error?) { }

    /**
     Finish method which must be called eventually after an operation has
     begun executing (even if cancelled).

     This method may not be overridden. To handle finishing, override
     `procedureWillFinish(withErrors:)` or `procedureDidFinish(withErrors:)`
     or use a WillFinish / DidFinish observer.

     - parameter errors: an array of `Error`, which defaults to empty.
     */
    public func finish(with error: Error? = nil) {
        finish(with: error, from: .finish)
    }

    // Used to queue an automatic finish from Procedure.start()/main()
    // (i.e. if a Procedure should automatically finish prior to executing if, for example,
    // it is cancelled prior to executing)
    private func queueAutomaticFinish(from source: ProcedureKit.FinishingFrom) {

        debugAssertIsOnEventQueue() // only ever called from a block on the EventQueue
        assert(pendingAutomaticFinish == nil)
        assert(state < .executing)

        if finishedHandlingCancel {
            // DidCancel observers have already been run, and given a chance to call finish() themselves.
            // Thus, it is safe to call finish() directly here (which will queue a finish attempt at the
            // end of the EventQueue):
            finish(with: nil, from: source)
        }
        else {
            // DidCancel observers have not yet been run.
            // They may or may not be queued on the event queue yet (queuing may happen concurrently).
            // The only guarantee is that they will be queued and run at some point after this
            // current event.
            //
            // Thus, it is *not* safe to simply queue (async) a finishing block to execute on the
            // EventQueue - we cannot guarantee it will be queued prior to the DidCancel event block.
            //
            // Instead, store the pendingAutomaticFinish for processing in the DidCancel observer block
            // (whenever it is executed):
            pendingAutomaticFinish = FinishingInfo(error: nil, source: source)
        }
    }

    private final func shouldFinish(with receivedError: Error?, from source: ProcedureKit.FinishingFrom) -> FinishingInfo? {
        return synchronise {
            // Do not finish is already finishing or finished
            guard _state <= .finishing else { return nil }
            // Do not finish if not yet started - unless cancelled
            var queueFinishForStart = false
            if _state < .started {
                guard _isCancelled else {
                    assertionFailure("Cannot finish Procedure prior to it being started (unless cancelled).")
                    return nil
                }
                // if the Procedure is cancelled, we can queue the finish for after
                // start() is called
                queueFinishForStart = true
            }
            // Only a single call to _finish should continue
            guard !_isHandlingFinish else { return nil }
            _isHandlingFinish = true

            guard !queueFinishForStart else {
                // Calls to finish() prior to the Procedure starting are
                // queued to be executed once the queue has started the Procedure.
                // (As long as the Procedure is cancelled first.)
                //
                // (It's an error for an Operation added to an OperationQueue to
                // set isFinished to true prior to the queue starting the Operation.)
                _pendingFinish = FinishingInfo(error: receivedError, source: source)
                return nil
            }

            return FinishingInfo(error: receivedError, source: source)
        }
    }

    private final func finish(with receivedError: Error?, from source: ProcedureKit.FinishingFrom) {

        log.verbose.trace()

        guard let finishingInfo = shouldFinish(with: receivedError, from: source) else {
            log.verbose.message("An earlier call to finish \((isFinished) ? "has already succeeded." : "is pending. The Procedure will finish from the first call.") This call will have no effect: finish(with: \(receivedError.debugDescription)")
            return
        }

        _finish(withInfo: finishingInfo)
    }

    private final func _finish(withInfo info: FinishingInfo) {
        dispatchEvent {
            self._finish_onEventQueue(withInfo: info)
        }
    }

    private final func _finish_onEventQueue(withInfo info: FinishingInfo) {

        debugAssertIsOnEventQueue()
        debugSynchronizedAssertIsExecuting()

        log.verbose.trace()

        // Obtain a local strong reference to the Procedure queue
        guard let strongProcedureQueue = procedureQueue else {
            // NOTE: For the mutual exclusivity implementation to work properly,
            // a strong reference to the ProcedureQueue must exist through finish.
            //
            // Procedure is supposed to hold onto its own strong reference
            // to the ProcedureQueue onto which it was added.
            fatalError("Procedure hasn't finished, but procedureQueue is nil") // ProcedureKit internal programmer error
        }

        // NOTE:
        // - The stateLock should only be held when necessary, and should not
        //   be held when notifying observers (whether via KVO or Operation's
        //   observers) or deadlock can result.

        // Determine whether the `isExecuting` state is changing.
        // (If the Procedure is finishing from a state other than .executing, `isExecuting` will
        // not transition from `true` -> `false`, and no KVO is necessary.)
        let changedExecutingState = isExecuting

        if changedExecutingState {
            willChangeValue(forKey: .executing)
        }

        // Change the state to .finishing and set & retrieve the final resulting array of errors
        let resultingError: Error? = synchronise {
            protectedProperties.error = protectedProperties.error ?? info.error
            _state = .finishing
            return protectedProperties.error
        }

        if changedExecutingState {
            didChangeValue(forKey: .executing)
        }

        if let error = resultingError {
            log.verbose.message("Will finish with error: \(error).")
        }
        else {
            log.verbose.message("Will finish with no errors.")
        }

        procedureWillFinish(with: resultingError)

        let willFinishObserversGroup = dispatchObservers(pendingEvent: PendingEvent.finish) {
            $0.will(finish: self, with: resultingError, pendingFinish: $1)
        }

        optimizedDispatchEventNotify(group: willFinishObserversGroup) {
            // Once all the WillFinishObservers have completed, continue processing finish

            self.log.verbose.message("[event]: Resuming pending finish")

            // Change the state to .finished and signal `isFinished` KVO.
            //
            // IMPORTANT: willChangeValue and didChangeValue *must* occur
            // on the same *thread*.
            //
            // Thus, both are executed below (in the same block on the EventQueue),
            // as delaying didChangeValue to another block on the queue (for example,
            // after the DidFinishObservers) may not result in it executing on the
            // same _thread_ as the earlier call to willChangeValue.
            //
            self.willChangeValue(forKey: .finished)
            self.synchronise {
                // Set the state to .finished
                self._state = .finished
                // Clear the internal Procedure strong reference to its ProcedureQueue
                //
                // A separate strong reference (strongProcedureQueue) exists for use
                // in cleanup (unlocking) tasks below
                self._queue = nil
            }
            self.didChangeValue(forKey: .finished)

            // Call the Procedure.procedureDidFinish(withErrors:) override
            self.procedureDidFinish(with: resultingError)

            // If mutually exclusive categories were locked, unlock
            if let mutuallyExclusiveCategories = self.mutuallyExclusiveCategories {
                strongProcedureQueue.unlock(mutuallyExclusiveCategories: mutuallyExclusiveCategories)
            }

            // Dispatch the DidFinishObservers
            let didFinishObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.postFinish) { observer, _ in
                observer.did(finish: self, with: resultingError)
            }

            self.optimizedDispatchEventNotify(group: didFinishObserversGroup) {
                // Once all the DidFinishObservers have completed, log a final notice

                if let error = resultingError {
                    self.log.warning.message("Did finish with error: \(error).")
                }
                else {
                    self.log.info.message("Did finish without errors.")
                }
            }
        }
    }

    // MARK: - Observers

    /**
     Add an observer to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    open func addObserver<Observer>(_ observer: Observer) where Observer: ProcedureObserver, Observer.Procedure: Procedure {
        assert(self as? Observer.Procedure != nil, "add(observer:) passed an Observer with an invalid expected Procedure type. The Observer will not receive any events from this Procedure. (Observer expects a Procedure of type \"\(String(describing: Observer.Procedure.self))\", but `self` is a \"\(typeDescription)\" and cannot be converted.)")

        addAnyObserver(AnyObserver(base: TransformObserver<Observer.Procedure, Procedure>(base: observer)))
    }

    // Internal function used to add AnyObserver<Procedure> to the Procedure's internal array of observers.
    internal func addAnyObserver(_ observer: AnyObserver<Procedure>) {
        debugSynchronizedAssertIsPending("Adding observers to a Procedure after it has been added to a queue is an inherent race condition, and risks missing events.")

        dispatchEvent {

            self.debugAssertIsOnEventQueue()

            // Add the observer to the internal observers array
            self.synchronise {
                self.protectedProperties.observers.append(observer)
            }

            // Dispatch the DidAttach event to the observer
            if let observerEventQueue = observer.eventQueue, observerEventQueue !== self.eventQueue {
                // This observer has a desired eventQueue onto which all observer
                // callbacks should be synchronized.
                //
                // Dispatch the observer callback block onto the observer's event queue
                self.eventQueue.dispatchSynchronizedBlock(onOtherQueue: observerEventQueue) {
                    // this block is now synchronized with *both* queues
                    //observerEventQueue.debugAssertIsOnQueue()

                    // process observer block on Observer's event queue
                    observer.didAttach(to: self)
                }
                return
            }
            else {
                // The observer lacks a desired eventQueue, so just execute the block directly on the
                // Procedure's EventQueue.
                observer.didAttach(to: self)
            }
        }
    }

    /// Appropriately dispatch an observer call (using the provided block) for every observer.
    ///
    /// - IMPORTANT: Only call this if already on the eventQueue.
    ///
    /// - Parameters:
    ///   - pendingEvent: the Procedure's PendingEvent that occurs after all the observers have completed their work
    ///   - block: a block that will be called for every observer, on the appropriate queue/thread
    /// - Returns: a DispatchGroup that will be signaled (ready) when the PendingEvent is ready (i.e. when
    ///            all of the observers have completed their work)
    @discardableResult
    internal func dispatchObservers(pendingEvent: (Procedure) -> PendingEvent, block: @escaping (AnyObserver<Procedure>, PendingEvent) -> Void) -> DispatchGroup {
        debugAssertIsOnEventQueue() // This function should only be called if already on the EventQueue

        let iterator = observers.makeIterator()
        let pendingEvent = pendingEvent(self)

        processObservers(iterator: iterator, futureEvent: pendingEvent, block: block)
        return pendingEvent.group
    }

    typealias ObserverIterator = IndexingIterator<[AnyObserver<Procedure>]>
    private func processObservers(iterator: ObserverIterator, futureEvent: PendingEvent, block: @escaping (AnyObserver<Procedure>, PendingEvent) -> Void) {
        debugAssertIsOnEventQueue() // This function should only be called if already on the EventQueue

        var modifiableIterator = iterator
        while let observer = modifiableIterator.next() {

            if let observerEventQueue = observer.eventQueue, observerEventQueue !== eventQueue {
                // This observer has a desired eventQueue onto which all observer
                // callbacks should be synchronized.
                //
                // Dispatch the observer callback block onto the observer's event queue,
                // and chain an async dispatch back to this Procedure's event queue
                // to continue processing any remaining observers once this observer's
                // callback has returned.
                //
                let originalQoS = DispatchQoS(qosClass: DispatchQueue.currentQoSClass, relativePriority: 0)
                eventQueue.dispatchSynchronizedBlock(onOtherQueue: observerEventQueue) {
                    // This block is now synchronized with *both* queues:
                    //  - the parent Procedure's EventQueue
                    //  - the observer's queue
                    // and is *on* the observer's queue.

                    // Process the observer block on Observer's event queue
                    block(observer, futureEvent)

                    // Dispatch async back to the Procedure's EventQueue to
                    // continue processing observers.
                    self.dispatchEvent(minimumQoS: originalQoS) {
                        self.processObservers(iterator: modifiableIterator, futureEvent: futureEvent, block: block)
                    }
                }
                return
            }
            else {
                block(observer, futureEvent)
            }
        }
    }
}

// MARK: - Dependencies

public extension Procedure {

    final func addDependency<Dependency: ProcedureProtocol>(_ dependency: Dependency) {
        guard let op = dependency as? Operation else {
            assertionFailure("Adding dependencies which do not subclass Foundation.Operation is not supported.")
            return
        }
        addDependency(op)
    }
}

// MARK: - Event Queue

internal extension Procedure {

    /// Asynchronously dispatches an event for execution on the Procedure's EventQueue.
    ///
    /// - Parameters:
    ///   - block: a block to execute on the EventQueue
    func dispatchEvent(minimumQoS: DispatchQoS? = nil, block: @escaping () -> Void) {
        eventQueue.dispatchEventBlockInternal(minimumQoS: minimumQoS, block: block)
    }

    // Only to be called when already on the eventQueue
    func optimizedDispatchEventNotify(group: DispatchGroup, inheritQoS: Bool = false, block: @escaping () -> Void) {
        debugAssertIsOnEventQueue()

        if group.wait(timeout: .now()) == .success {
            // no need to dispatch notify, just execute block directly
            // (optimal path when the DispatchGroup is already finished)
            block()
        }
        else {
            // must wait on group to execute the block on the eventQueue

            // use either the QoS of the Procedure, or the current QoS
            let minimumQoS = (!inheritQoS) ? qualityOfService.qos : DispatchQoS(qosClass: DispatchQueue.currentQoSClass, relativePriority: 0)

            eventQueue.dispatchNotify(withGroup: group, minimumQoS: minimumQoS, block: block)
        }
    }

    func debugAssertIsOnEventQueue() {
        eventQueue.debugAssertIsOnQueue()
    }
}

// MARK: - Conditions

extension Procedure {

    // A custom internal operation subclass that handles evaluating Conditions for a Procedure.
    final class EvaluateConditions: Operation {

        private enum State: Int, Comparable { // swiftlint:disable:this nesting

            static func < (lhs: State, rhs: State) -> Bool {
                return lhs.rawValue < rhs.rawValue
            }

            case waiting
            case dispatchedStart
            case started
            case executingMain
        }

        let queue: DispatchQueue
        weak var procedure: Procedure?
        let context: ConditionEvaluationContext

        init(procedure: Procedure) {
            self.procedure = procedure
            let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.EvaluateConditions", qos: procedure.qualityOfService.qos, attributes: [.concurrent])
            self.queue = queue
            self.context = ConditionEvaluationContext(queue: queue, behavior: .andPredicate)
            super.init()
        }

        func parentProcedureHasBeenAddedToQueue() {
            // Only once the parent Procedure has been fully added to the ProcedureQueue
            // (OperationQueue) is it safe to begin evaluating conditions (if otherwise isReady).

            dispatchStartOnce(source: .parentProcedureHasBeenAddedToQueue)
        }

        private var _isFinished: Bool = false
        private var _isExecuting: Bool = false
        private let stateLock = PThreadMutex()
        private var _state: State = .waiting
        private var _parentProcedureHasBeenAddedToQueue: Bool = false

        override var isFinished: Bool {
            get { return stateLock.withCriticalScope { return _isFinished } }
            set {
                willChangeValue(forKey: .finished)
                stateLock.withCriticalScope { _isFinished = newValue }
                didChangeValue(forKey: .finished)
            }
        }
        override var isExecuting: Bool {
            get { return stateLock.withCriticalScope { return _isExecuting } }
            set {
                willChangeValue(forKey: .executing)
                stateLock.withCriticalScope { _isExecuting = newValue }
                didChangeValue(forKey: .executing)
            }
        }

        final override var isReady: Bool {
            let superIsReady = super.isReady
            if superIsReady {
                // If super.isReady == true, dispatch start *once*
                dispatchStartOnce(source: .isReady)
            }
            return superIsReady
        }

        private enum StartSource { // swiftlint:disable:this nesting

            case isReady
            case parentProcedureHasBeenAddedToQueue
        }

        final private func dispatchStartOnce(source: StartSource) {
            // dispatch start() once
            let shouldDispatchStart: Bool = stateLock.withCriticalScope {
                guard _state < .dispatchedStart else { return false } // already started evaluating
                switch source {
                case .isReady:
                    // if isReady, can proceed to .dispatchedStart *if* _parentProcedureHasBeenAddedToQueue
                    guard _parentProcedureHasBeenAddedToQueue else {
                        // isReady, but the parent procedure hasn't yet been added
                        // to the queue - do not proceed
                        return false
                    }
                case .parentProcedureHasBeenAddedToQueue:
                    assert(!_parentProcedureHasBeenAddedToQueue)
                    _parentProcedureHasBeenAddedToQueue = true
                    // can proceed to .dispatchedStart *if* otherwise isReady
                    guard super.isReady else { return false }
                }
                _state = .dispatchedStart
                return true
            }
            guard shouldDispatchStart else { return }

            guard let procedure = procedure else {
                // the Procedure went away - finish immediately
                finish()
                return
            }
            guard let procedureQueue = procedure.procedureQueue else {
                fatalError("The Condition Evaluator's Procedure has a nil associated ProcedureQueue.")
            }
            procedureQueue.requestEvaluation(of: self)
        }
        final fileprivate func dispatchStartOnce() {
            dispatchStartOnce(source: .isReady)
        }

        final override func cancel() {
            // If the EvaluateConditions operation is cancelled
            // Ensure that the attached Procedure is cancelled
            procedure?.cancel()
            super.cancel()
            // Cancel the context to ensure that any concurrent
            // evaluation of Conditions rapidly stops.
            context.cancel()
        }

        /// Should only be called by ProcedureQueue
        /// (see: the call to `procedureQueue.requestEvaluation(of: self)` above)
        override func start() {
            isExecuting = true
            main()
        }

        /// Should only be called by start()
        override func main() {
            // This should only be executed once
            let shouldContinue: Bool = stateLock.withCriticalScope {
                guard _state < .executingMain else { return false }
                _state = .executingMain
                return true
            }
            guard shouldContinue else { return }

            guard let procedure = procedure else {
                // the Procedure went away - finish immediately
                finish()
                return
            }
            guard !isCancelled else {
                // this EvaluateConditions operation has been cancelled
                // ensure that the dependent Procedure is cancelled
                procedure.cancel()
                // then finish immediately
                finish()
                return
            }

            let conditions = procedure.conditions
            conditions.evaluate(procedure: procedure, withContext: context) { result in

                // Determine whether the Procedure can proceed to execution
                switch result {
                case .success(true):
                    // All conditions were successful - the Procedure may execute
                    // Continue on
                    break
                case .success(false):
                    // One or more conditions failed (with an ignored error)
                    procedure.log.verbose.message("Condition(s) failed.")
                    // Cancel the Procedure without errors
                    procedure.cancel()
                    // Finish this EvaluateConditions operation immediately
                    self.finish()
                    return
                case let .failure(error):
                    procedure.log.verbose.message("Condition(s) failed with error: \(error).")
                    procedure.cancel(with: error)
                    // Finish this EvaluateConditions operation immediately
                    self.finish()
                    return
                }

                // If the parent Procedure wasn't cancelled
                // by something else
                guard !procedure.isCancelled else {
                    // Finish this EvaluateConditions operation immediately
                    self.finish()
                    return
                }

                // Check for any mutually exclusive categories
                // to apply to the Procedure
                let mutuallyExclusiveCategories = conditions.mutuallyExclusiveCategories
                guard !mutuallyExclusiveCategories.isEmpty else {
                    // No mutually-exclusive categories to acquire - finish immediately
                    self.finish()
                    return
                }

                // Acquire the mutually-exclusive categories (locks) for the Procedure
                // before allowing it to execute.

                procedure.request(mutuallyExclusiveCategories: mutuallyExclusiveCategories) { _ in
                    // Exclusivity locks have been acquired, or the request did not succeed
                    // (but for valid cancellation/timing reasons).
                    //
                    // Regardless, it is now safe to finish the EvaluateConditions operation
                    // and trigger the parent Procedure (if it hasn't already cancelled + finished).
                    self.finish()
                }
            }
        }
        func finish() {
            isExecuting = false
            isFinished = true
        }
    }

    func addDirectDependency(_ directDependency: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        stateLock.withCriticalScope { () -> Void in
            protectedProperties.directDependencies.insert(directDependency)

            // occurs inside the stateLock to prevent any double-adds of dependencies
            // to the EvaluateConditions operation
            assert(!((_evaluateConditionsProcedure?.isExecuting ?? false) || (_evaluateConditionsProcedure?.isFinished ?? false)), "Conditions are already being evaluated (or have already finished being evaluated). It is too late to add a dependency and have it properly affect the Procedure. Instead, consider adding dependencies before adding the Procedure to a queue, or adding dependencies before all other existing dependencies have finished (for example: from a WillFinish observer on a dependency).")
            _evaluateConditionsProcedure?.addDependency(directDependency)
        }
        super.addDependency(directDependency)
    }

    func removeDirectDependency(_ directDependency: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        stateLock.withCriticalScope { () -> Void in
            protectedProperties.directDependencies.remove(directDependency)

            // occurs inside the stateLock to ensure that every removed dependency is
            // removed from the EvaluateConditions operation
            _evaluateConditionsProcedure?.removeDependency(directDependency)
        }
        super.removeDependency(directDependency)
    }

    public final override var dependencies: [Operation] {
        return Array(directDependencies)
    }

    /**
     Add another `Operation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to add dependencies before adding them to operation queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `Operation` instance.
     */
    public final override func addDependency(_ operation: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        addDirectDependency(operation)
    }

    /**
     Remove another `Operation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to manage dependencies before adding them to operation
     queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `Operation` instance.
     */
    public final override func removeDependency(_ operation: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        removeDirectDependency(operation)
    }

    /**
     Add a condition to the procedure. It is a programmatic error to call this method
     after the receiver has been added to a ProcedureQueue. Therefore, best practice
     is to manage conditions before adding a Procedure to a queue.

     - parameter condition: a `Condition` which must be satisfied for the procedure to be executed.
     */
    public final func addCondition(_ condition: Condition) {
        assert(state < .willEnqueue, "Cannot modify conditions after a Procedure has been added to a queue, current state: \(state).")
        synchronise { () -> Void in
            protectedProperties.conditions.insert(condition)
        }
    }
}

// MARK: - Internal Extensions

internal extension Procedure {

    func debugSynchronizedAssertIsExecuting(_ message: String = "Procedure is not yet finishing or finished.") {
        #if DEBUG
        synchronise {
            guard _state <= .executing else {
                assertionFailure(message)
                return
            }
        }
        #endif
    }

    /// Internal Assertions
    func debugSynchronizedAssertIsPending(_ message: String = "Procedure is no longer pending.") {
        #if DEBUG
        synchronise {
            guard _state <= .pending else {
                assertionFailure(message)
                return
            }
        }
        #endif
    }
}

// MARK: - Deprecations

public extension Procedure {

    @available(*, deprecated, renamed: "addObserver(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func add<Observer>(observer: Observer) where Observer: ProcedureObserver, Observer.Procedure: Procedure {
        addObserver(observer)
    }

    @available(*, deprecated, renamed: "addObserver(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    internal func add(anyObserver observer: AnyObserver<Procedure>) {
        addAnyObserver(observer)
    }

    @available(*, deprecated, renamed: "addDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add<Dependency: ProcedureProtocol>(dependency: Dependency) {
        addDependency(dependency)
    }

    @available(*, deprecated, renamed: "addDirectDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func add(directDependency: Operation) {
        addDirectDependency(directDependency)
    }

    @available(*, deprecated, renamed: "removeDirectDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func remove(directDependency: Operation) {
        removeDirectDependency(directDependency)
    }

    @available(*, deprecated, renamed: "addCondition(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(condition: Condition) {
        addCondition(condition)
    }
}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
