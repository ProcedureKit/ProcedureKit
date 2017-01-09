//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation

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

    private init() { }
}

/**
 Type to express the intent of the user in regards to executing an Operation instance

 - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
 */
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

open class Procedure: Operation, ProcedureProtocol {

    private var _isTransitioningToExecuting = false
    private var _isHandlingCancel = false
    private var _isCancelled = false  // should always be set by .cancel()

    private var _isHandlingFinish: Bool = false

    fileprivate let isAutomaticFinishingDisabled: Bool

    // A weak reference to the ProcedureQueue onto which this Procedure was added
    private weak var _queue: ProcedureQueue?

    // Stored pending finish information
    // (used if a Procedure is cancelled and finish() is called prior to the queue
    // starting the Procedure - see `shouldFinish`)
    fileprivate struct FinishingInfo {
        var receivedErrors: [Error]
        var source: ProcedureKit.FinishingFrom
    }
    fileprivate var _pendingFinish: FinishingInfo? = nil

    // only accessed from within the EventQueue
    private var pendingAutomaticFinish: FinishingInfo? = nil
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
    public var userIntent: UserIntent = .none {
        didSet {
            setQualityOfService(fromUserIntent: userIntent)
        }
    }

    @available(OSX 10.10, iOS 8.0, tvOS 8.0, watchOS 2.0, *)
    open override var qualityOfService: QualityOfService {
        get { return super.qualityOfService }
        set {
            super.qualityOfService = newValue
            eventQueue.qualityOfService = newValue.qos
        }
    }

    internal let identifier = UUID()

    internal class ProcedureQueueContext { }
    internal let queueAddContext = ProcedureQueueContext()

    deinit {
        // ensure that the Protected Properies are deinitialized within the lock
        _stateLock.withCriticalScope {
            self.protectedProperties = nil
        }
    }

    // MARK: State

    // the state variable to be used *within* the stateLock
    private var _state = ProcedureKit.State.initialized {
        willSet(newState) {
            _log.verbose(message: "\(_state) -> \(newState)")
            assert(_state.canTransition(to: newState, whenCancelled: _isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity). Ensure that Procedure instances are added to a ProcedureQueue not an OperationQueue.")
        }
    }

    fileprivate let _stateLock = PThreadMutex()

    // the state variable to be used *outside* the stateLock
    fileprivate var state: ProcedureKit.State {
        get {
            return _stateLock.withCriticalScope { _state }
        }
        set(newState) {
            _stateLock.withCriticalScope {
                _state = newState
            }
        }
    }

    /// Boolean indicator for whether the Procedure has been enqueued
    final public var isEnqueued: Bool {
        return _stateLock.withCriticalScope { _isEnqueued }
    }

    /// Boolean indicator for whether the Procedure is pending
    final public var isPending: Bool {
        return _stateLock.withCriticalScope { _isPending }
    }

    /// Boolean indicator for whether the Procedure is currently executing or not
    final public override var isExecuting: Bool {
        return _stateLock.withCriticalScope { _isExecuting }
    }

    /// Boolean indicator for whether the Procedure has finished or not
    final public override var isFinished: Bool {
        return _stateLock.withCriticalScope { _isFinished }
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
        return _stateLock.withCriticalScope { _isCancelled }
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

    // MARK: Protected Internal Properties

    // Grouped in a class to allow for easily deinitializing in `deinit`.
    fileprivate class ProtectedProperties {
        var log: LoggerProtocol = Logger()
        var errors = [Error]()
        var observers = [AnyObserver<Procedure>]()
        var directDependencies = Set<Operation>()
        var conditions = Set<Condition>()
    }
    fileprivate var protectedProperties: ProtectedProperties? = ProtectedProperties()

    // the errors variable to be used *within* the stateLock
    private var _errors: [Error] {
        return protectedProperties!.errors
    }

    // the log variable to be used *within* the stateLock
    private var _log: LoggerProtocol {
        get {
            let operationName = self.operationName
            return LoggerContext(parent: protectedProperties!.log, operationName: operationName)
        }
    }

    // MARK: Errors

    public var errors: [Error] {
        return _stateLock.withCriticalScope { _errors }
    }

    // MARK: Log

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
    final public var log: LoggerProtocol {
        get {
            let operationName = self.operationName
            return _stateLock.withCriticalScope { LoggerContext(parent: protectedProperties!.log, operationName: operationName) }
        }
        set {
            _stateLock.withCriticalScope {
                protectedProperties!.log = newValue
            }
        }
    }

    // MARK: Observers

    final internal var observers: [AnyObserver<Procedure>] {
        get {
            return _stateLock.withCriticalScope { protectedProperties!.observers }
        }
    }


    // MARK: Dependencies & Conditions

    internal var directDependencies: Set<Operation> {
        get { return _stateLock.withCriticalScope { protectedProperties!.directDependencies } }
    }

    internal fileprivate(set) var evaluateConditionsProcedure: EvaluateConditions? = nil

    internal var indirectDependencies: Set<Operation> {
        return Set(conditions
            .flatMap { $0.directDependencies }
            .filter { !directDependencies.contains($0) }
        )
    }

    /// - returns conditions: the Set of Condition instances attached to the operation
    public var conditions: Set<Condition> {
        get { return _stateLock.withCriticalScope { protectedProperties!.conditions } }
    }

    // MARK: - Initialization

    public override init() {
        isAutomaticFinishingDisabled = false
        super.init()
        name = String(describing: type(of: self))
    }

    // MARK: - Disable Automatic Finishing

    /**
     Ability to override Operation's built-in finishing behavior, if a
     subclass requires full control over when finish() is called.

     Used for GroupOperation to implement proper .Finished state-handling
     (only finishing after all child operations have finished).

     The default behavior of Operation is to automatically call finish()
     when:
     (a) the Operation is cancelled prior to it starting
         (in which case, the Operation will skip calling execute())
     (b) when willExecuteObservers log errors

     To ensure that an Operation subclass does not finish until the
     subclass calls finish():
     call `super.init(disableAutomaticFinishing: true)` in the init.

     IMPORTANT: If disableAutomaticFinishing == TRUE, the subclass is
     responsible for calling finish() in *ALL* cases, including when the
     operation is cancelled.

     You can react to cancellation using WillCancelObserver/DidCancelObserver
     and/or checking periodically during execute with something like:

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
    }

    // MARK: - Execution

    public final func willEnqueue(on queue: ProcedureQueue) {
        _stateLock.withCriticalScope {
            _state = .willEnqueue
            _queue = queue
        }
    }

    public final func pendingQueueStart() {
        state = .pending
    }

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    public final override func start() {
        // Don't call super.start
        
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

        let hasPendingFinish = _stateLock.withCriticalScope { () -> FinishingInfo? in
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

    /// Do not call main() directly on a Procedure. Add the Procedure to a ProcedureQueue or call start().
    public final override func main() {
        assertionFailure("Do not call main() directly on a Procedure. Add the Procedure to a ProcedureQueue.")
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    private final func _main() {

        debugAssertIsOnEventQueue()

        assert(state >= .started, "Procedure.main() is being called when Procedure.start() has not been called. Do not call main() directly. Add the Procedure to a ProcedureQueue.")

        log.verbose(message: "[observers]: WillExecute")

        // Call the WillExecute observers
        let willExecuteObserversGroup = dispatchObservers(pendingEvent: PendingEvent.executeEvent) { observer, pendingEvent in
            observer.will(execute: self, futureExecute: pendingEvent)
        }

        // After the WillExecute observers have all completed, proceed to Step 2 of main()
        // Inherit the current QoS level to ensure that the QoS level of start() persists through to execute()
        optimizedDispatchEventNotify(group: willExecuteObserversGroup, inheritQoS: true) {
            self._main_step2()
        }
    }

    private final func _main_step2() {

        debugAssertIsOnEventQueue()

        // Prevent concurrent execution
        func getNextState() -> ProcedureKit.State? {
            return _stateLock.withCriticalScope {

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
                guard (_errors.isEmpty && !_isCancelled) || isAutomaticFinishingDisabled else {
                    return .finishing
                }

                // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
                _isTransitioningToExecuting = true
                return .executing
            }
        }

        // Check the state again, as it could have changed in another queue via finish
        func getNextStateAgain() -> ProcedureKit.State? {
            return _stateLock.withCriticalScope {
                guard _state <= .started else { return nil }

                guard !_isHandlingFinish else {
                    // a finish is pending, simply exit from processing execute
                    return nil
                }

                _state = .executing
                _isTransitioningToExecuting = false

                if _isCancelled && !isAutomaticFinishingDisabled && !_isHandlingFinish {
                    // Procedure was cancelled, and automatic finishing is enabled.
                    // Because execute() has not yet been called, handle finish here.
                    return .finishing
                }
                return .executing
            }
        }
            
        log.verbose(message: "[event]: Continue Pending Execute")

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
        let nextState2 = getNextStateAgain()

        didChangeValue(forKey: .executing)

        guard nextState2 != .finishing else {
            // The Procedure should transition to finishing
            // (for example, if cancelled prior to execute())
            queueAutomaticFinish(from: .main)
            return
        }

        guard nextState2 == .executing else { return }

        log.notice(message: "Will Execute")

        // Call the execute() function (which should be overriden in Procedure subclasses)
        execute()

        // Dispatch DidExecute observers
        log.verbose(message: "[observers]: DidExecute")
        let _ = dispatchObservers(pendingEvent: PendingEvent.postDidExecuteEvent) { observer, _ in
            observer.did(execute: self)
        }
        
        // Log that execute() has returned
        log.notice(message: "Did Execute")
    }

    /// Procedure subclasses must override `execute()`.
    open func execute() {
        print("\(self) must override `execute()`.")
        finish()
    }

    @discardableResult public final func produce(operation: Operation, before pendingEvent: PendingEvent? = nil) throws -> ProcedureFuture {
        precondition(state > .initialized, "Cannot add operation which is not being scheduled on a queue")
        guard let queue = _stateLock.withCriticalScope(block: { return _queue }) else {
            throw ProcedureKitError.noQueue()
        }

        let promise = ProcedurePromise()

        log.notice(message: ".produce() | Will add \(operation.operationName)")

        // Dispatch the innards of produce() onto the EventQueue
        dispatchEvent {
            self._produce(operation: operation, onQueue: queue, before: pendingEvent, promise: promise)
        }

        return promise.future
    }

    private func _produce(operation: Operation, onQueue queue: ProcedureQueue, before pendingEvent: PendingEvent? = nil, promise: ProcedurePromise) {
        debugAssertIsOnEventQueue()

        log.verbose(message: ".produce() | [observers]: WillAddOperation(\(operation.operationName))")

        // Dispatch WillAddOperation observers
        let willAddObserversGroup = dispatchObservers(pendingEvent: PendingEvent.addOperationEvent) { observer, _ in
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

        log.verbose(message: ".produce() | [event]: AddOperation(\(operation.operationName)) to queue.")

        // Add the new produced operation to the ProcedureQueue on which this Procedure was added
        queue.add(operation: operation, withContext: queueAddContext).then(on: self) { _ in

            // After adding to the queue completes, proceed to step 3 of handling produce()
            self._produce_step3(operation: operation, onQueue: queue, before: pendingEvent, promise: promise)
        }
    }

    private func _produce_step3(operation: Operation, onQueue queue: ProcedureQueue, before pendingEvent: PendingEvent? = nil, promise: ProcedurePromise) {

        if let pendingEvent = pendingEvent {
            // Ensure that the PendingEvent occurs sometime after this point
            pendingEvent.doBeforeEvent {
                log.verbose(message: "ProcedureQueue.add(\(operation.operationName)) called prior to (\(pendingEvent)).")
            }
        }

        log.notice(message: ".produce() | Did add \(operation.operationName)")

        log.verbose(message: ".produce() | [observers]: DidAddOperation(\(operation.operationName))")

        // Complete the promise, since the produced operation has been added to the queue
        promise.complete()

        // Dispatch DidAddOperation observers
        let _ = self.dispatchObservers(pendingEvent: PendingEvent.postDidAddEvent) { observer, _ in
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

    open func procedureDidCancel(withErrors: [Error]) { }

    public final func cancel(withErrors errors: [Error]) {
        _cancel(withAdditionalErrors: errors)
    }

    public final override func cancel() {
        _cancel(withAdditionalErrors: [])
    }

    // used by GroupProcedure to bypass dispatching to the event queue for its cancellation handling
    internal func _procedureDidCancel() {
        // no-op
    }

    private enum ShouldCancelResult {
        case shouldCancel
        case alreadyFinishingOrFinished
        case alreadyCancelling
        case alreadyCancelled
    }
    private var shouldCancel: ShouldCancelResult {
        return _stateLock.withCriticalScope {
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

    private final func _cancel(withAdditionalErrors additionalErrors: [Error], promise: ProcedurePromise? = nil) {

        let shouldCancel = self.shouldCancel
        guard shouldCancel == .shouldCancel else {
            promise?.complete()//(withFailure: shouldCancel.error ?? ProcedureKitError.unknown)
            return
        }

        // Immediately (and possibly concurrently with the EventQueue) set the `isCancelled`
        // state of the Procedure to true, sending appropriate KVO.
        
        willChangeValue(forKey: .cancelled)

        let resultingErrors = _stateLock.withCriticalScope { () -> [Error] in
            if !additionalErrors.isEmpty {
                protectedProperties!.errors.append(contentsOf: additionalErrors)
            }
            _isCancelled = true
            return protectedProperties!.errors
        }

        log.notice(message: "Will cancel with \(!additionalErrors.isEmpty ? "errors: \(additionalErrors)" : "no errors").")

        didChangeValue(forKey: .cancelled)

        // Call super to trigger .isReady state change on cancel as well as isReady KVO notification
        super.cancel()

        // Micro-optimization for built-in Procedures that can safely handle cancellation off the EventQueue
        _procedureDidCancel()

        // Trigger DidCancel function & observers on the event queue
        dispatchEvent {

            // procedureDidCancel(withErrors:) override
            self.procedureDidCancel(withErrors: resultingErrors)

            // DidCancel observers
            self.log.verbose(message: "[observers]: DidCancel")
            let didCancelObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.postDidCancelEvent) { observer, _ in
                observer.did(cancel: self, withErrors: resultingErrors)
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
                    self.finish(withErrors: pendingAutomaticFinish.receivedErrors, from: pendingAutomaticFinish.source)
                }
            }

            promise?.complete()
        }
    }


    // MARK: - Finishing

    open func procedureWillFinish(withErrors: [Error]) { }

    open func procedureDidFinish(withErrors: [Error]) { }

    /**
     Finish method which must be called eventually after an operation has
     begun executing, unless it is cancelled.

     This method may not be overridden. To handle finishing, override
     `procedureWillFinish(withErrors:)` or `procedureDidFinish(withErrors:)`
     or use a WillFinish / DidFinish observer.

     - parameter errors: an array of `Error`, which defaults to empty.
     */
    public func finish(withErrors errors: [Error] = []) {
        log.verbose(message: "finish() called")
        finish(withErrors: errors, from: .finish)
    }

    // Used to queue an automatic finish from Procedure.start()/main()
    // (i.e. if a Procedure should automatically finish prior to executing if, for example,
    // it is cancelled prior to executing)
    private func queueAutomaticFinish(from source: ProcedureKit.FinishingFrom) {
        
        debugAssertIsOnEventQueue() // only ever called from a block on the EventQueue
        assert(pendingAutomaticFinish == nil)
        
        if finishedHandlingCancel {
            // DidCancel observers have already been run, and given a chance to call finish() themselves.
            // Thus, it is safe to call finish() directly here (which will queue a finish attempt at the
            // end of the EventQueue):
            finish(withErrors: [], from: source)
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
            pendingAutomaticFinish = FinishingInfo(receivedErrors: [], source: source)
        }
    }

    private final func shouldFinish(withErrors receivedErrors: [Error], from source: ProcedureKit.FinishingFrom) -> FinishingInfo? {
        return _stateLock.withCriticalScope {
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
                _pendingFinish = FinishingInfo(receivedErrors: receivedErrors, source: source)
                return nil
            }

            return FinishingInfo(receivedErrors: receivedErrors, source: source)
        }
    }

    private final func finish(withErrors receivedErrors: [Error], from source: ProcedureKit.FinishingFrom) {
        guard let finishingInfo = shouldFinish(withErrors: receivedErrors, from: source) else {
            log.verbose(message: "An earlier call to finish \((isFinished) ? "has already succeeded." : "is pending. The Procedure will finish from the first call.") This call will have no effect: finish(withErrors: \(receivedErrors))")
            return
        }

        _finish(withInfo: finishingInfo)
    }

    private final func _finish(withInfo info: FinishingInfo) {
        dispatchEvent {
            self._finishImpl(withInfo: info)
        }
    }

    private final func _finishImpl(withInfo info: FinishingInfo) {

        debugAssertIsOnEventQueue()

        assert(state <= .executing)

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
        let resultingErrors: [Error] = _stateLock.withCriticalScope {
            _state = .finishing
            if !info.receivedErrors.isEmpty {
                protectedProperties!.errors.append(contentsOf: info.receivedErrors)
            }
            return protectedProperties!.errors
        }

        if changedExecutingState {
            didChangeValue(forKey: .executing)
        }

//        let messageSuffix = !resultingErrors.isEmpty ? "errors: \(resultingErrors)" : "no errors"

        log.notice(message: "Will finish with \(!resultingErrors.isEmpty ? "errors: \(resultingErrors)" : "no errors").")

        procedureWillFinish(withErrors: resultingErrors)

        let willFinishObserversGroup = dispatchObservers(pendingEvent: PendingEvent.finishEvent) {
            $0.will(finish: self, withErrors: resultingErrors, futureFinish: $1)
        }

        optimizedDispatchEventNotify(group: willFinishObserversGroup, block: {
            // Once all the WillFinishObservers have completed, continue processing finish
            
            self.log.verbose(message: "[event]: Resuming pending finish")
            
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
            self._stateLock.withCriticalScope { self._state = .finished }
            self.didChangeValue(forKey: .finished)

            // Call the Procedure.procedureDidFinish(withErrors:) override
            self.procedureDidFinish(withErrors: resultingErrors)

            // Dispatch the DidFinishObservers
            let didFinishObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.postFinishEvent) { observer, _ in
                observer.did(finish: self, withErrors: resultingErrors)
            }

            self.optimizedDispatchEventNotify(group: didFinishObserversGroup, block: {
                // Once all the DidFinishObservers have completed, log a final notice

                self.log.notice(message: "Did finish with \(!resultingErrors.isEmpty ? "errors: \(resultingErrors)" : "no errors").")
            })
        })
    }

    // MARK: - Observers

    /**
     Add an observer to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    open func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Procedure {
        assert(state < .pending, "Adding observers to a Procedure after it has been added to a queue is an inherent race condition, and risks missing events.")

        dispatchEvent {

            self.debugAssertIsOnEventQueue()

            // Add the observer to the internal observers array
            self._stateLock.withCriticalScope {
                self.protectedProperties!.observers.append(AnyObserver(base: observer))
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
    /// NOTE: Only call this if already on the eventQueue.
    ///
    /// - Parameters:
    ///   - pendingEvent: the Procedure's PendingEvent that occurs after all the observers have completed their work
    ///   - block: a block that will be called for every observer, on the appropriate queue/thread
    /// - Returns: a DispatchGroup that will be signaled (ready) when the PendingEvent is ready (i.e. when
    //             all of the observers have completed their work)
    internal func dispatchObservers(pendingEvent: (Procedure) -> PendingEvent, block: @escaping (AnyObserver<Procedure>, PendingEvent) -> ()) -> DispatchGroup {
        debugAssertIsOnEventQueue() // This function should only be called if already on the EventQueue

        let iterator = observers.makeIterator()
        let pendingEvent = pendingEvent(self)

        processObservers(iterator: iterator, futureEvent: pendingEvent, block: block)
        return pendingEvent.group
    }

    typealias ObserverIterator = IndexingIterator<[AnyObserver<Procedure>]>
    private func processObservers(iterator: ObserverIterator, futureEvent: PendingEvent, block: @escaping (AnyObserver<Procedure>, PendingEvent) -> ()) {
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

// MARK: Dependencies

public extension Procedure {

    public final func add<Dependency: ProcedureProtocol>(dependency: Dependency) {
        guard let op = dependency as? Operation else {
            assertionFailure("Adding dependencies which do not subclass Foundation.Operation is not supported.")
            return
        }
        add(dependency: op)
    }
}

// MARK: - Event Queue

internal extension Procedure {

    /// Asynchronously dispatches an event for execution on the Procedure's EventQueue.
    ///
    /// - Parameters:
    ///   - block: a block to execute on the EventQueue
    internal func dispatchEvent(minimumQoS: DispatchQoS? = nil, block: @escaping () -> ()) {
        eventQueue.dispatchEventBlockInternal(minimumQoS: minimumQoS, block: block)
    }

    // Only to be called when already on the eventQueue
    internal func optimizedDispatchEventNotify(group: DispatchGroup, inheritQoS: Bool = false, block: @escaping () -> ()) {
        debugAssertIsOnEventQueue()
        
        if group.wait(timeout: .now()) == DispatchTimeoutResult.success {
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

    internal func debugAssertIsOnEventQueue() {
        eventQueue.debugAssertIsOnQueue()
    }
}

// MARK: Conditions

extension Procedure {

    final class EvaluateConditions: GroupProcedure, InputProcedure, OutputProcedure {

        var input: Pending<[Condition]> = .pending
        var output: Pending<ConditionResult> = .pending

        init(conditions: Set<Condition>) {
            let ops = Array(conditions)
            input = .ready(ops)
            super.init(operations: ops)
        }

        override func procedureWillFinish(withErrors errors: [Error]) {
            output = .ready(process(withErrors: errors))
        }

        private func process(withErrors errors: [Error]) -> ConditionResult {
            guard errors.isEmpty else {
                return .failure(ProcedureKitError.FailedConditions(errors: errors))
            }
            guard let conditions = input.value else {
                fatalError("Conditions must be set before the evaluation is performed.")
            }
            return conditions.reduce(.success(false)) { lhs, condition in
                // Unwrap the condition's output
                guard let rhs = condition.output.value else { return lhs }

                log.verbose(message: "evaluating \(lhs) with \(rhs)")

                switch (lhs, rhs) {
                // both results are failures
                case let (.failure(error), .failure(anotherError)):
                    if let error = error as? ProcedureKitError.FailedConditions {
                        return .failure(error.append(error: anotherError))
                    }
                    else if let anotherError = anotherError as? ProcedureKitError.FailedConditions {
                        return .failure(anotherError.append(error: error))
                    }
                    else {
                        return .failure(ProcedureKitError.FailedConditions(errors: [error, anotherError]))
                    }
                // new condition failed - so return it
                case (_, .failure(_)):
                    return rhs
                // first condition is ignored - so return the new one
                case (.success(false), _):
                    return rhs
                default:
                    return lhs
                }
            }
        }
    }

    func evaluateConditions() -> Procedure {

        func createEvaluateConditionsProcedure() -> EvaluateConditions {
            // Set the procedure on each condition
            conditions.forEach {
                $0.procedure = self
                $0.log.enabled = self.log.enabled
                $0.log.severity = self.log.severity
            }

            let evaluator = EvaluateConditions(conditions: conditions)
            evaluator.name = "\(operationName) Evaluate Conditions"

            super.addDependency(evaluator)
            return evaluator
        }

        assert(state < .pending, "Dependencies cannot be modified after a Procedure has been added to a queue, current state: \(state).")

        let evaluator = createEvaluateConditionsProcedure()

        // Add the direct dependencies of the procedure as direct dependencies of the evaluator
        directDependencies.forEach {
            evaluator.add(dependency: $0)
        }

        // Add an observer to the evaluator to see if any of the conditions failed.
        evaluator.addWillFinishBlockObserver { [weak self] evaluator, _, _ in
            guard let result = evaluator.output.value else { return }

            switch result {
            case .success(true):
                break
            case .success(false):
                self?.cancel()
            case let .failure(error):
                if let failedConditions = error as? ProcedureKitError.FailedConditions {
                    self?.cancel(withErrors: failedConditions.errors)
                }
                else {
                    self?.cancel(withError: error)
                }
            }
        }

        return evaluator
    }

    func add(dependencyOnPreviousMutuallyExclusiveProcedure procedure: Procedure) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        super.addDependency(procedure)
    }

    func add(directDependency: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        _stateLock.withCriticalScope { () -> Void in
            protectedProperties!.directDependencies.insert(directDependency)
        }
        super.addDependency(directDependency)
    }

    func remove(directDependency: Operation) {
        precondition(state < .started, "Dependencies cannot be modified after a Procedure has started, current state: \(state).")
        _stateLock.withCriticalScope { () -> Void in
            protectedProperties!.directDependencies.remove(directDependency)
        }
        super.removeDependency(directDependency)
    }

    public final override var dependencies: [Operation] {
        return Array(directDependencies.union(indirectDependencies))
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
        add(directDependency: operation)
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
        remove(directDependency: operation)
    }

    /**
     Add a condition to the procedure. It is a programmatic error to call this method
     after the receiver has been added to a ProcedureQueue. Therefore, best practice
     is to manage conditions before adding a Procedure to a queue.

     - parameter condition: a `Condition` which must be satisfied for the procedure to be executed.
     */
    public final func add(condition: Condition) {
        assert(state < .willEnqueue, "Cannot modify conditions after a Procedure has been added to a queue, current state: \(state).")
        _stateLock.withCriticalScope { () -> Void in
            protectedProperties!.conditions.insert(condition)
        }
    }
}

// MARK: - Unavailable

public extension Procedure {

    @available(*, unavailable, renamed: "procedureDidCancel(withErrors:)", message: "procedureWillCancel is no longer available. Use procedureDidCancel.")
    public func procedureWillCancel(withErrors: [Error]) { }

}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
