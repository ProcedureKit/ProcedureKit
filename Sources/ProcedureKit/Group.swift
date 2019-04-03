//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length

import Foundation
import Dispatch

/**
 A `Procedure` subclass which enables the grouping
 of other procedures. Use `Group`s to associate
 related operations together, thereby creating higher
 levels of abstractions.
 */
open class GroupProcedure: Procedure {

    public typealias TransformChildErrorBlockType = (Procedure, inout Error?) -> Void

    internal let queue = ProcedureQueue()
    internal var queueDelegate: GroupQueueDelegate!

    fileprivate let initialChildren: [Operation]
    fileprivate var groupCanFinish: CanFinishGroup!
    fileprivate var groupStateLock = PThreadMutex()

    @discardableResult
    fileprivate func synchronise<T>(block: () -> T) -> T {
        return groupStateLock.withCriticalScope(block: block)
    }

    // Protected private properties
    fileprivate var _groupChildren: [Operation] // swiftlint:disable:this variable_name
    fileprivate var _groupIsFinishing = false // swiftlint:disable:this variable_name
    fileprivate var _groupIsSuspended = false // swiftlint:disable:this variable_name
    fileprivate var _groupTransformChildErrorBlock: TransformChildErrorBlockType?

    /// - returns: the operations which have been added to the queue
    final public var children: [Operation] {
        return synchronise { _groupChildren }
    }

    /**
     The default service level to apply to the GroupProcedure and its child operations.
     
     This property specifies the service level applied to the GroupProcedure itself, and to
     operation objects added to the GroupProcedure.
     
     If the added operation object has an explicit service level set, that value is used instead.
     
     For more, see the NSOperation and NSOperationQueue documentation for `qualityOfService`.
     */
    @available(OSX 10.10, iOS 8.0, tvOS 8.0, watchOS 2.0, *)
    open override var qualityOfService: QualityOfService {
        get { return queue.qualityOfService }
        set {
            super.qualityOfService = newValue
            queue.qualityOfService = newValue
        }
    }

    /**
     - WARNING: Do not call `finish()` on a GroupProcedure or a GroupProcedure subclass.
     A GroupProcedure finishes when all of its children finish.
     It is an anti-pattern to call `finish()` directly on a GroupProcedure.

     To cause a GroupProcedure to finish more quickly, without waiting for all of its 
     children to complete, call `cancel()`. The Group will then cancel all of its
     children and finish as soon as they have handled cancellation / finished.
    */
    final public override func finish(with error: Error? = nil) {
        assertionFailure("Do not call finish() on a GroupProcedure or a GroupProcedure subclass. GroupProcedure will automatically finish when all of its children finish.")
        // no-op
    }

    /**
     Designated initializer for GroupProcedure. Create a GroupProcedure with
     an array of Operation instances. Optionally provide the underlying dispatch
     queue for the group's internal ProcedureQueue.

     - parameter underlyingQueue: an optional DispatchQueue which defaults to nil, this
     parameter is set as the underlying queue of the group's own ProcedureQueue.
     - parameter operations: an array of Operation instances. Note that these do not
     have to be Procedure instances - you can use `Foundation.Operation` instances
     from other sources.
    */
    public init(dispatchQueue underlyingQueue: DispatchQueue? = nil, operations: [Operation]) {

        assert(operations.filter({
            if let procedure = $0 as? Procedure {
                return procedure.isEnqueued
            }
            else {
                return false
            }
        }).isEmpty,
        "Cannot initialize GroupProcedure with Procedures that have already been added to another queue / GroupProcedure: \(operations.filter({ if let procedure = $0 as? Procedure { return procedure.isEnqueued } else { return false } }))")

        _groupChildren = operations
        initialChildren = operations

        /**
         GroupProcedure is responsible for calling `finish()` on cancellation
         once all of its childred have cancelled and finished, and its own
         finishing operation has finished.

         Therefore we disable `Procedure`'s automatic finishing mechanisms.
        */
        super.init(disableAutomaticFinishing: true)

        queue.isSuspended = true
        queue.underlyingQueue = underlyingQueue
        queueDelegate = GroupQueueDelegate(self)
        queue.delegate = queueDelegate
        groupCanFinish = CanFinishGroup(group: self)
    }

    /// Create a GroupProcedure with a variadic array of Operation instances.
    ///
    /// - Parameter operations: a variadic array of `Operation` instances.
    public convenience init(operations: Operation...) {
        self.init(operations: operations)
    }

    deinit {
        // To ensure that any remaining operations on the internal queue are released
        // we must cancelAllOperations and also ensure the queue is not suspended.
        queue.cancelAllOperations()
        queue.isSuspended = false
    }

    // MARK: - Handling Cancellation

    // GroupProcedure child cancellation can be safely handled without dispatching to the EventQueue.
    //
    // This function is called internally by the Group's .cancel() (Procedure.cancel())
    // prior to dispatching DidCancel observers on the Group's EventQueue.
    override func _procedureDidCancel(with error: Error?) {
        guard let error = error else {
            children.forEach { $0.cancel() }
            return
        }

        let (operations, procedures) = children.operationsAndProcedures
        operations.forEach { $0.cancel() }
        procedures.forEach { $0.cancel(with: ProcedureKitError.parent(cancelledWithError: error)) }

        // the GroupProcedure ensures that `finish()` is called once all the
        // children have finished in its CanFinishGroup operation
    }

    // MARK: - Execute

    /// Adds the GroupProcedure's initial child Operations to its internal queue (and other setup).
    ///
    /// If the Group is not suspended, the child Operations will execute once they are ready.
    ///
    /// - important: When overriding GroupProcedure's `execute()`, always call `super.execute()`.
    open override func execute() {
        // Add the initial children to the Group's internal queue.
        // (This is delayed until execute to allow WillAdd/DidAdd observers set on the Group, post-init (but pre-execute),
        // to receive the initial children.)
        addAdditionalChildren(initialChildren, toOperationsArray: false, alreadyOnEventQueue: true)

        // Add the CanFinishGroup (which is used to provide concurrency-safety for adding children post-execute).
        add(canFinishGroup: groupCanFinish)

        // Unsuspend the Group's internal queue (unless the user has suspended the Group)
        groupStateLock.withCriticalScope {
            if !_groupIsSuspended { queue.isSuspended = false }
        }
    }

    // MARK: - GroupWillAddChild override

    /**
     This method is called when a child will be added to the Group.
     (It is called on the Group's EventQueue.)
     */
    open func groupWillAdd(child: Operation) { /* no-op */ }

    // MARK: - Customizing the Group's Child Error Handling

    /**
     This method is called when a child Procedure will finish (with / without an error).
     (It is called on the Group's EventQueue.)

     The default behavior is to append the child's errors, if any, to the Group's errors.

     When subclassing GroupProcedure, you can override this method to execute custom
     code in response to child Procedures finishing, or to override the default
     error-aggregating behavior.

     The child Procedure (and, thus, the Group) will not finish until this method returns.

     - parameter child: the child Procedure which is finishing
     - parameter errors: an [Error], the errors of the child Procedure
    */
    open func child(_ child: Procedure, willFinishWithError childError: Error?) {
        assert(!child.isFinished, "child(_:willFinishWithError:) called with a child that has already finished")
        guard let childError = childError else { return }

        // Default GroupProcedure error-handling is to collect
        // the first error related to a non-Procedure subclass.
        setErrorOnce(childError)
    }

    final public func setErrorOnce(_ childError: Error) {
        guard error == nil else { return }

        error = childError
    }

    @available(*, deprecated, renamed: "child(_:willFinishWithError:)", message: "Use child(_:,willFinishWithError:) instead.")
    open func child(_ childProcedure: Procedure, willFinishWithErrors errors: [Error]) {
        assertionFailure("Use child(_:willFinishWithError:) instead.")
        child(childProcedure, willFinishWithError: errors.first)
    }

    /**
     The transformChildErrorsBlock is called before the GroupProcedure handles child errors.
     (It is called on the Group's EventQueue.)

     The block is passed two parameters:
        - Procedure: the child Procedure that will finish
        - inout [Error]: the errors that the Group attributes to the child (on input: the errors that the child Procedure will finish with)

     The array of errors is an `inout` parameter, and may be modified directly.

     This enables the customization of the errors that the GroupProcedure (or GroupProcedure subclass) 
     attributes to the child and considers in its `child(_:willFinishWithErrors:)` function.

     - IMPORTANT: This only affects the child errors that the GroupProcedure (or GroupProcedure subclass)
     utilizes. It does not directly impact the child Procedure itself, nor the child Procedure's errors
     (if obtained or read directly from the child).
    */
    final public var transformChildErrorBlock: TransformChildErrorBlockType? {
        get { return synchronise { _groupTransformChildErrorBlock } }
        set {
            assert(!isExecuting, "Do not modify the child errors block after the Group has started.")
            synchronise { _groupTransformChildErrorBlock = newValue }
        }
    }
}

// MARK: - GroupProcedure API

public extension GroupProcedure {

    /**
     Access the underlying queue of the GroupProcedure.

     - returns: the underlying DispatchQueue of the groups private ProcedureQueue
    */
    final var dispatchQueue: DispatchQueue? {
        return queue.underlyingQueue
    }

    /**
     The maximum number of child operations that can execute at the same time.

     The value in this property affects only the operations that the current GroupProcedure has
     executing at the same time. Other operation queues and GroupProcedures can also execute
     their maximum number of operations in parallel.

     Reducing the number of concurrent operations does not affect any operations that are
     currently executing.

     Specifying the value NSOperationQueueDefaultMaxConcurrentOperationCount (which is recommended)
     causes the system to set the maximum number of operations based on system conditions.

     The default value of this property is NSOperationQueueDefaultMaxConcurrentOperationCount.
     */
    final var maxConcurrentOperationCount: Int {
        get { return queue.maxConcurrentOperationCount }
        set { queue.maxConcurrentOperationCount = newValue }
    }

    /**
     A Boolean value indicating whether the GroupProcedure is actively scheduling operations for execution.

     When the value of this property is false, the GroupProcedure actively starts child operations
     that are ready to execute once the GroupProcedure has been executed.

     Setting this property to true prevents the GroupProcedure from starting any child operations,
     but already executing child operations continue to execute.

     You may continue to add operations to a GroupProcedure that is suspended but those operations
     are not scheduled for execution until you change this property to false.

     The default value of this property is false.
     */
    final var isSuspended: Bool {
        get {
            return groupStateLock.withCriticalScope { _groupIsSuspended }
        }
        set {
            groupStateLock.withCriticalScope {
                log.verbose.message("isSuspended = \(newValue), (old value: \(_groupIsSuspended))")
                _groupIsSuspended = newValue
                queue.isSuspended = newValue
            }
        }
    }
}

public extension GroupProcedure {

    // MARK: - Add Child API

    /**
     Add a single child Operation instance to the group
     - parameter child: an Operation instance
    */
    final func addChild(_ child: Operation, before pendingEvent: PendingEvent? = nil) {
        addChildren(child, before: pendingEvent)
    }

    /**
     Add children Operation instances to the group
     - parameter children: a variable number of Operation instances
     */
    final func addChildren(_ children: Operation..., before pendingEvent: PendingEvent? = nil) {
        addChildren(children, before: pendingEvent)
    }

    /**
     Add a sequence of Operation instances to the group
     - parameter children: a sequence of Operation instances
     */
    final func addChildren<Children: Collection>(_ children: Children, before pendingEvent: PendingEvent? = nil) where Children.Iterator.Element: Operation {
        addAdditionalChildren(children, toOperationsArray: true, before: pendingEvent)
    }

    private func shouldAdd<Additional: Collection>(additional: Additional, toOperationsArray shouldAddToProperty: Bool) -> Bool where Additional.Iterator.Element: Operation {
        return groupStateLock.withCriticalScope {

            log.verbose.trace()

            guard !_groupIsFinishing else {
                assertionFailure("Cannot add new operations to a group after the group has started to finish.")
                return false
            }

            // Debug check whether any of the additional Procedures have already been added to another queue/Group.
            assert(additional.filter({ if let procedure = $0 as? Procedure { return procedure.isEnqueued } else { return false } }).isEmpty, "Cannot add Procedures to a GroupProcedure that have already been added to another queue / GroupProcedure: \(additional.filter({ if let procedure = $0 as? Procedure { return procedure.isEnqueued } else { return false } }))")

            // Add the new children as a dependencies of the internal GroupCanFinish operation
            groupCanFinish.addDependencies(additional)

            // Add the new children to the Group's internal `children` array
            if shouldAddToProperty {
                let childrenToAdd: [Operation] = Array(additional)
                _groupChildren.append(contentsOf: childrenToAdd)
            }

            return true
        }
    }

    /**
     Adds one or more operations to the Group.
    */
    final fileprivate func addAdditionalChildren<Additional: Collection>(_ additional: Additional, toOperationsArray shouldAddToProperty: Bool, before pendingEvent: PendingEvent? = nil, alreadyOnEventQueue: Bool = false) where Additional.Iterator.Element: Operation {

        // Exit early if there are no children in the collection
        guard !additional.isEmpty else { return }

        // Check to see if should add child operations, depending on finishing state
        // (Also enters the groupIsAddingOperations group)
        guard shouldAdd(additional: additional, toOperationsArray: shouldAddToProperty) else {
            let message = !isFinished ? "started to finish" : "completed"
            assertionFailure("Cannot add new children to a group after the group has \(message).")
            return
        }

        log.verbose.trace()
        log.verbose.message("is adding \(additional.count) child operations to the queue.")

        // If the Group is cancelled, cancel the additional operations
        if isCancelled {
            additional.forEach { if !$0.isCancelled { $0.cancel() } }
        }

        // Step 2:
        guard alreadyOnEventQueue else {
            dispatchEvent {
                self.addOperation_step2(additional: additional, before: pendingEvent)
            }
            return
        }
        addOperation_step2(additional: additional, before: pendingEvent)
    }

    fileprivate func addOperation_step2<Additional: Collection>(additional: Additional, before pendingEvent: PendingEvent?) where Additional.Iterator.Element: Operation {

        eventQueue.debugAssertIsOnQueue()

        log.verbose.trace()

        // groupWillAdd(child:) override
        additional.forEach { self.groupWillAdd(child: $0) }

        // WillAddOperation observers
        let willAddObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.addOperation) { observer, _ in
            additional.forEach {
                observer.procedure(self, willAdd: $0)
            }
        }

        optimizedDispatchEventNotify(group: willAddObserversGroup) {

            // Add to queue
            self.queue.addOperations(additional, withContext: self.queueAddContext).then(on: self) {

                if let pendingEvent = pendingEvent {
                    pendingEvent.doBeforeEvent {
                        self.log.verbose.message("Children (\(additional)) added prior to (\(pendingEvent)).")
                    }
                }

                // DidAddOperation observers
                let didAddObserversGroup = self.dispatchObservers(pendingEvent: PendingEvent.postDidAdd) { observer, _ in
                    additional.forEach {
                        observer.procedure(self, didAdd: $0)
                    }
                }

                self.optimizedDispatchEventNotify(group: didAddObserversGroup) {
                    self.log.verbose.message("finished adding child operations to the queue.")
                }
            }
        }
    }
}

// MARK: - GroupProcedure Private Queue Delegate

internal extension GroupProcedure {

    /**
     The group utilizes a GroupQueueDelegate to effectively act as its own delegate for its own
     internal queue, while keeping this implementation detail private.

     When an operation is added to the queue, assuming that the group is not yet finishing or 
     finished, then we add the operation as a dependency to an internal "barrier" operation that
     separates executing from finishing state.

     This serves to keep the internal operation as a final child operation that executes when
     there are no more operations in the group operation, safely handling the transition
     of group operation state.
     */

    class GroupQueueDelegate: ProcedureQueueDelegate {

        private weak var group: GroupProcedure?

        init(_ group: GroupProcedure) {
            self.group = group
        }

        func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation, context: Any?) -> ProcedureFuture? {
            guard let strongGroup = group else { return nil }
            guard queue === strongGroup.queue else { return nil }

            return strongGroup.willAdd(operation: operation, context: context)
        }

        func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
            guard let strongGroup = group else { return nil }
            guard queue === strongGroup.queue else { return nil }

            return strongGroup.willAdd(operation: procedure, context: context)
        }

        public func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, with error: Error?) -> ProcedureFuture? {
            guard let strongGroup = group else { return nil }
            guard queue === strongGroup.queue else { return nil }

            /// If the group is cancelled, exit early
            guard !strongGroup.isCancelled else { return nil }

            let promise = ProcedurePromise()
            strongGroup.dispatchEvent {

                defer { promise.complete() }

                var childError: Error? = error

                defer { strongGroup.child(procedure, willFinishWithError: childError) }

                guard let transformChildError = strongGroup.transformChildErrorBlock else { return }

                transformChildError(procedure, &childError)

                strongGroup.log.verbose.message("Child error for <\(procedure.operationName)> was transformed.")
            }
            return promise.future
        }
    }

    private func shouldAdd(operation: Operation) -> Bool {
        return groupStateLock.withCriticalScope {
            guard !_groupIsFinishing else {
                assertionFailure("Cannot add new operations to a group after the group has started to finish.")
                return false
            }

            // Add the new child as a dependency of the internal GroupCanFinish operation
            groupCanFinish.addDependency(operation)

            // Add the new child to the Group's internal children array
            _groupChildren.append(operation)
            return true
        }
    }

    /**
     - returns: a `ProcedureFuture` that is signaled once the Group has fully prepared for the operation to be added
                to its internal queue (including notifying all WillAdd observers)
     */
    private func willAdd(operation: Operation, context: Any?) -> ProcedureFuture? {

        if let context = context as? ProcedureQueueContext, context === queueAddContext {
            // The Procedure adding the operation to the Group's private queue is the Group itself
            //
            // which means it could only have come from:
            //      - self.add(child:)  (and convenience overloads)
            //
            // which will handle the setup-work for this operation in the context of the Group
            // (asynchronously) so there is nothing to do here - exit early

            return nil
        }

        // The Procedure adding the operation to the Group's private queue is *not* the Group.
        //
        // It could have come from:
        //      - a child.produce(operation:)
        //      - an Operation (NSOperation) subclass calling OperationQueue.current.addOperation()
        //        (which is not at all recommended, but is possible from an Operation subclass)
        //
        // In either case, the operation has not yet been handled in the context of the Group
        // (i.e. adding it as a child, adding it as a dependency on finishing, notifying Group
        // Will/DidAddOperation observers) thus it must be handled here:
        //

        assert(!isFinished, "Cannot add new operations to a group after the group has completed.")

        guard shouldAdd(operation: operation) else { return nil }

        let promise = ProcedurePromise()

        // If the Group is already cancelled, ensure that the new child is cancelled.
        if isCancelled && !operation.isCancelled {
            operation.cancel()
        }

        // Dispatch the next step (observers, etc) asynchronously on the Procedure EventQueue
        dispatchEvent {
            self.willAdd_step2(operation: operation, promise: promise)
        }

        return promise.future
    }

    private func willAdd_step2(operation: Operation, promise: ProcedurePromise) {
        eventQueue.debugAssertIsOnQueue()

        // groupWillAdd(child:) override
        groupWillAdd(child: operation)

        // WillAddOperation observers
        let willAddObserversGroup = dispatchObservers(pendingEvent: PendingEvent.addOperation) { observer, _ in
            observer.procedure(self, willAdd: operation)
        }

        optimizedDispatchEventNotify(group: willAddObserversGroup) {

            // Complete the promise
            promise.complete()

            // DidAddOperation observers
            _ = self.dispatchObservers(pendingEvent: PendingEvent.postDidAdd) { observer, _ in
                    observer.procedure(self, didAdd: operation)
            }

            // Note: no need to wait on DidAddOperation observers - nothing left to do.
        }
    }
}

// MARK: - Finishing

fileprivate extension GroupProcedure {

    final class CanFinishGroup: Operation {

        private weak var group: GroupProcedure?
        private var _isFinished = false
        private var _isExecuting = false
        private let stateLock = PThreadMutex()

        init(group: GroupProcedure) {
            self.group = group
            super.init()
        }

        fileprivate override func start() {

            // Override Operation.start() because this operation may have to
            // finish asynchronously (if it has to register to be notified when
            // operations are no longer being added concurrently).
            //
            // Since we override start(), it is important to send Operation
            // isExecuting / isFinished KVO notifications.
            //
            // (Otherwise, the operation may not be released, there may be
            // problems with dependencies, with the queue's handling of
            // maxConcurrentOperationCount, etc.)

            isExecuting = true

            main()
        }

        override func main() {
            execute()
        }

        func execute() {

            if let group = group {
                group.log.verbose.trace()
                group.log.verbose.message("executing can finish group operation.")

                // All operations that were added as a side-effect of anything up to
                // WillFinishObservers of prior operations should have been executed.
                //
                // Handle an edge case caused by concurrent calls to Group.add(children:)

                enum GroupCanFinishResult {
                    case canFinishNow
                    case waitingOnNewChildren(CanFinishGroup, [Operation])
                }

                let isWaiting: GroupCanFinishResult = group.groupStateLock.withCriticalScope {

                    // Check whether new children were added prior to the lock
                    // (i.e. after the queue decided to start the CanFinish operation)
                    // by checking for child operations that are not finished.

                    let active = group._groupChildren.filter({ !$0.isFinished })
                    if !active.isEmpty {

                        // Children were added after this CanFinishOperation became
                        // ready, but before it executed or before the lock could be acquired.

                        group.log.verbose.message("cannot finish now, as there are children still active.")

                        // The GroupProcedure should wait for these children to finish
                        // before finishing. Add the oustanding children as
                        // dependencies to a new CanFinishGroup, and add that as the
                        // Group's new CanFinishGroup.

                        let newCanFinishGroup = GroupProcedure.CanFinishGroup(group: group)
                        group.groupCanFinish = newCanFinishGroup
                        return .waitingOnNewChildren(newCanFinishGroup, active)
                    }
                    else {
                        // There are no additional children to handle.
                        // Ensure that no new operations can be added.

                        group.log.verbose.message("can now finish.")

                        group._groupIsFinishing = true

                        return .canFinishNow
                    }
                } // End of isWaiting

                switch isWaiting {
                case .canFinishNow:
                    // trigger an immediate finish of the parent Group
                    group._finishGroup()
                case .waitingOnNewChildren(let newCanFinishGroup, let newChildrenToWaitOn):
                    // add the new children as dependencies to the newCanFinishGroup,
                    // (which is already set as the `group.groupCanFinish` inside the lock
                    // above) and then add the newCanFinishGroup to the group's internal queue
                    newCanFinishGroup.addDependencies(newChildrenToWaitOn)
                    group.add(canFinishGroup: newCanFinishGroup)
                    // continue on to finish this CanFinishGroup operation
                    // (the newCanFinishGroup takes over responsibility)
                    break
                }
            }

            isExecuting = false
            isFinished = true
        }

        override private(set) var isExecuting: Bool {
            get { return stateLock.withCriticalScope { _isExecuting } }
            set {
                willChangeValue(forKey: .executing)
                stateLock.withCriticalScope { _isExecuting = newValue }
                didChangeValue(forKey: .executing)
            }
        }

        override private(set) var isFinished: Bool {
            get { return stateLock.withCriticalScope { _isFinished } }
            set {
                willChangeValue(forKey: .finished)
                stateLock.withCriticalScope { _isFinished = newValue }
                didChangeValue(forKey: .finished)
            }
        }
    }

    func add(canFinishGroup: CanFinishGroup) {
        queue.add(canFinishGroup: canFinishGroup)
    }
}

fileprivate extension GroupProcedure {

    func _finishGroup() {
        super.finish()
        queue.isSuspended = true
    }
}

fileprivate extension ProcedureQueue {

    func add(canFinishGroup: GroupProcedure.CanFinishGroup) {
        // Do not add observers (not needed - CanFinishGroup is an implementation detail of Group)
        // Do not add conditions (CanFinishGroup has none)
        // Call OperationQueue.addOperation() directly
        super.addOperation(canFinishGroup)
    }
}

// MARK: - Deprecations Unavailable

public extension GroupProcedure {

    @available(*, unavailable, renamed: "children")
    var operations: [Operation] { return children }

    @available(*, unavailable, renamed: "isSuspended")
    final var suspended: Bool { return isSuspended }

    @available(*, unavailable, renamed: "addChild(_:before:)")
    func addOperation(operation: Operation) { }

    @available(*, unavailable, renamed: "add(children:)")
    func addOperations(operations: Operation...) { }

    @available(*, unavailable, renamed: "add(children:)")
    func addOperations(additional: [Operation]) { }

    @available(*, unavailable, message: "GroupProcedure child error handling customization has been re-worked. Consider overriding child(_:willFinishWithError:).")
    final func childDidRecoverFromErrors(_ child: Operation) { }

    @available(*, unavailable, message: "GroupProcedure child error handling customization has been re-worked. Consider overriding child(_:willFinishWithError:).")
    final func childDidNotRecoverFromErrors(_ child: Operation) { }

    @available(*, unavailable, message: "GroupProcedure no longer collects all the child errors within itself")
    final func append(fatalError error: Error) { }

    @available(*, unavailable, message: "GroupProcedure no longer collects all the child errors within itself")
    final func append(fatalErrors errors: [Error]) { }

    @available(*, unavailable, message: "GroupProcedure no longer collects all the child errors within itself")
    final func append(error: Error, fromChild child: Operation? = nil) { }

    @available(*, unavailable, message: "GroupProcedure no longer collects all the child errors within itself")
    final func append(errors: [Error], fromChild child: Operation? = nil) { }

    @available(*, deprecated, renamed: "addChild(_:before:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(child: Operation, before pendingEvent: PendingEvent? = nil) {
        addChild(child, before: pendingEvent)
    }

    @available(*, deprecated, renamed: "addChildren(_:before:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(children: Operation..., before pendingEvent: PendingEvent? = nil) {
        addChildren(children, before: pendingEvent)
    }

    @available(*, deprecated, renamed: "addChildren(_:before:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add<Children: Collection>(children: Children, before pendingEvent: PendingEvent? = nil) where Children.Iterator.Element: Operation {
        addChildren(children, before: pendingEvent)
    }
}
