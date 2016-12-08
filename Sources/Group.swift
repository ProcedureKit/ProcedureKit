//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
open class GroupProcedure: Procedure, ProcedureQueueDelegate {

    internal struct GroupErrors {
        typealias ByOperation = Dictionary<Operation, Array<Error>>
        var fatal = [Error]()
        var attemptedRecovery: ByOperation = [:]

        var attemptedRecoveryErrors: [Error] {
            return Array(attemptedRecovery.values.flatMap { $0 })
        }

        var all: [Error] {
            get {
                var tmp: [Error] = fatal
                tmp.append(contentsOf: attemptedRecoveryErrors)
                return tmp
            }
        }
    }

    internal let queue = ProcedureQueue()

    fileprivate let finishing = BlockOperation { }

    fileprivate var groupErrors = Protector(GroupErrors())
    fileprivate var groupChildren: Protector<[Operation]>
    fileprivate var groupIsFinishing = false
    fileprivate var groupFinishLock = NSRecursiveLock()
    fileprivate var groupIsSuspended = false
    fileprivate var groupSuspendLock = NSLock()
    fileprivate var groupIsAddingOperations = DispatchGroup()
    fileprivate var groupCanFinish: CanFinishGroup!

    /// - returns: the operations which have been added to the queue
    final public var children: [Operation] {
        get { return groupChildren.read { $0 } }
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

        groupChildren = Protector(operations)

        /**
         GroupProcedure is responsible for calling `finish()` on cancellation
         once all of its childred have cancelled and finished, and its own
         finishing operation has finished.

         Therefore we disable `Procedure`'s automatic finishing mechanisms.
        */
        super.init(disableAutomaticFinishing: true)

        queue.isSuspended = true
        queue.underlyingQueue = underlyingQueue
        queue.delegate = self
        userIntent = operations.userIntent
        groupCanFinish = CanFinishGroup(group: self)

        addDidCancelBlockObserver { group, errors in
            if errors.isEmpty {
                group.children.forEach { $0.cancel() }
            }
            else {
                let (operations, procedures) = group.children.operationsAndProcedures
                operations.forEach { $0.cancel() }
                procedures.forEach { $0.cancel(withError: ProcedureKitError.parent(cancelledWithErrors: errors)) }
            }
        }
    }

    public convenience init(operations: Operation...) {
        self.init(operations: operations)
    }

    deinit {
        // To ensure that any remaining operations on the internal queue are released
        // we must cancelAllOperations and also ensure the queue is not suspended.
        queue.cancelAllOperations()
        queue.isSuspended = false

        // If you find that execution is stuck on the following line, one of the child
        // Operations/Procedures is likely not handling cancellation and finishing.
        queue.waitUntilAllOperationsAreFinished()
    }

    // MARK: - Execute

    open override func execute() {
        add(additional: children.filter { !queue.operations.contains($0) }, toOperationsArray: false)
        add(canFinishGroup: groupCanFinish)
        queue.addOperation(finishing)
        groupSuspendLock.withCriticalScope {
            if !groupIsSuspended { queue.isSuspended = false }
        }
    }

    // MARK: - Error recovery and child finishing

    /**
     This method is called when a child will finish with errors.

     Often an operation will finish with errors become some of its pre-requisites were not
     met. Errors of this nature should be recoverable. This can be done by re-trying the
     original operation, but with another operation which fulfil the pre-requisites as a
     dependency.

     If the errors were recovered from, return true from this method, else return false.

     Errors which are not handled will result in the GroupProcedure finishing with errors.

     - parameter child: the child operation which is finishing
     - parameter errors: an [ErrorType], the errors of the child operation
     - returns: a Boolean, return true if the errors were handled, else return false.
     */
    open func child(_ child: Operation, willAttemptRecoveryFromErrors errors: [Error]) -> Bool {
        return false
    }

    /**
     This method is only called when a child finishes without any errors.

     - parameter child: the Operation which will finish without errors
     */
    open func childWillFinishWithoutErrors(_ child: Operation) { /* no-op */ }

    // MARK - OperationQueueDelegate

    public func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Operation) {
        guard queue === self.queue else { return }

        if operation === finishing {
            finish(withErrors: errors)
            queue.isSuspended = true
        }
    }

    // MARK: - ProcedureQueueDelegate

    private var shouldAddOperation: Bool {
        return groupFinishLock.withCriticalScope {
            guard !groupIsFinishing else {
                assertionFailure("Cannot add new operations to a group after the group has started to finish.")
                return false
            }
            groupIsAddingOperations.enter()
            return true
        }
    }

    /**
     The group acts as its own queue's delegate. When an operation is added to the queue,
     assuming that the group is not yet finishing or finished, then we add the operation
     as a dependency to an internal "barrier" operation that separates executing from
     finishing state.

     The purpose of this is to keep the internal operation as a final child operation that executes
     when there are no more operations in the group operation, safely handling the transition of
     group operation state.
     */
    public func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation) {
        guard queue === self.queue && operation !== finishing else { return }

        assert(!finishing.isExecuting, "Cannot add new operations to a group after the group has started to finish.")
        assert(!finishing.isFinished, "Cannot add new operations to a group after the group has completed.")

        guard shouldAddOperation else { return }

        observers.forEach { $0.procedure(self, willAdd: operation) }

        groupCanFinish.addDependency(operation)

        groupFinishLock.withCriticalScope {
            groupIsAddingOperations.leave()
        }

        observers.forEach { $0.procedure(self, didAdd: operation) }
    }

    public func procedureQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation) {
        guard queue === self.queue && operation !== finishing else { return }

        assert(!finishing.isExecuting, "Cannot add new operations to a group after the group has started to finish.")
        assert(!finishing.isFinished, "Cannot add new operations to a group after the group has completed.")

        guard shouldAddOperation else { return }

        // Ensure that produced operations are added to the Group's
        // internal array (and cancelled if appropriate)

        groupChildren.append(operation)

        if isCancelled && !operation.isCancelled {
            operation.cancel()
        }

        groupFinishLock.withCriticalScope {
            groupIsAddingOperations.leave()
        }
    }

    /**
     The group acts as it's own queue's delegate. When an operation finishes, if the
     operation is the finishing operation, we finish the group operation here. Else, the group is
     notified that a child operation has finished.
     */
    public func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        guard queue === self.queue else { return }

        /// If the group is cancelled, exit early
        guard !isCancelled else { return }

        /// If the operation is a Procedure.EvaluateConditions - exit early.
        if operation is Procedure.EvaluateConditions { return }

        if !errors.isEmpty {
            if child(operation, willAttemptRecoveryFromErrors: errors) {
                child(operation, didAttemptRecoveryFromErrors: errors)
            }
            else {
                child(operation, didEncounterFatalErrors: errors)
            }
        }
        else if operation !== finishing {
            childWillFinishWithoutErrors(operation)
        }
    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [Error]) { }
}

// MARK: - GroupProcedure API

public extension GroupProcedure {

    /**
     Access the underlying queue of the GroupProcedure.

     - returns: the DispatchQueue of the groups private ProcedureQueue
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
            return groupSuspendLock.withCriticalScope { groupIsSuspended }
        }
        set {
            groupSuspendLock.withCriticalScope {
                groupIsSuspended = newValue
                queue.isSuspended = newValue
            }
        }
    }

    /**
     The default service level to apply to the GroupProcedure and its child operations.

     This property specifies the service level applied to the GroupProcedure itself, and to
     operation objects added to the GroupProcedure.

     If the added operation object has an explicit service level set, that value is used instead.

     For more, see the NSOperation and NSOperationQueue documentation for `qualityOfService`.
     */
    @available(OSX 10.10, iOS 8.0, tvOS 8.0, watchOS 2.0, *)
    final public override var qualityOfService: QualityOfService {
        get { return queue.qualityOfService }
        set {
            super.qualityOfService = newValue
            queue.qualityOfService = newValue
        }
    }

    /// Override of Procedure.userIntent
    final public override var userIntent: UserIntent {
        didSet {
            let (operations, procedures) = children.operationsAndProcedures
            operations.forEach { $0.setQualityOfService(fromUserIntent: userIntent) }
            procedures.forEach { $0.userIntent = userIntent }
        }
    }
}

// MARK: - Add Child API

public extension GroupProcedure {

    /**
     Add a single child Operation instance to the group
     - parameter child: an Operation instance
    */
    final func add(child: Operation) {
        add(children: child)
    }

    /**
     Add children Operation instances to the group
     - parameter children: a variable number of Operation instances
     */
    final func add(children: Operation...) {
        add(children: children)
    }

    /**
     Add a sequence of Operation instances to the group
     - parameter children: a sequence of Operation instances
     */
    final func add<Children: Collection>(children: Children) where Children.Iterator.Element: Operation {
        add(additional: children, toOperationsArray: true)
    }

    private var shouldAddChildren: Bool {
        return groupFinishLock.withCriticalScope {
            log.verbose(message: "checking to see if we can add child operations.")
            guard !groupIsFinishing else { return false }
            groupIsAddingOperations.enter()
            return true
        }
    }

    final fileprivate func add<Additional: Collection>(additional: Additional, toOperationsArray shouldAddToProperty: Bool) where Additional.Iterator.Element: Operation {
        // Exit early if there are no children in the collection
        guard !additional.isEmpty else { return }

        // Check to see if should add child operations, depending on finishing state
        guard shouldAddChildren else {
            let message = !finishing.isFinished ? "started to finish" : "completed"
            assertionFailure("Cannot add new children to a group after the group has \(message).")
            return
        }

        log.verbose(message: "is adding child operations to the queue.")

        // Check for the group being cancelled, and cancel the children
        var didHandleCancelled = false
        if isCancelled {
            additional.forEach { $0.cancel() }
            didHandleCancelled = true
        }

        // Set the log severity on each child procedure
        let severity = log.severity
        additional.forEachProcedure { $0.log.severity = severity }

        // Add the children to the queue
        queue.add(operations: additional)

        // Add the children to group property
        if shouldAddToProperty {
            let childrenToAdd: [Operation] = Array(additional)
            groupChildren.append(contentsOf: childrenToAdd)
        }

        // Check again for the group being cancelled, and cancel the children if necessary
        if !didHandleCancelled && isCancelled {
            // It is possible that the cancellation happened before adding the
            // additional operations to the operations array.
            // Thus, ensure that all additional operations are cancelled.
            additional.forEach { if !$0.isCancelled { $0.cancel() } }
        }

        // Leave the is adding operation group
        groupFinishLock.withCriticalScope {
            groupIsAddingOperations.leave()
            log.verbose(message: "finished adding child operations to the queue.")
        }
    }
}

// MARK: - Error Handling & Recovery

public extension GroupProcedure {

    internal var attemptedRecoveryErrors: [Error] {
        return groupErrors.read { $0.attemptedRecoveryErrors }
    }

    public override var errors: [Error] {
        get { return groupErrors.read { $0.fatal } }
        set {
            groupErrors.write { (ward: inout GroupErrors) in
                ward.fatal = newValue
            }
        }
    }

    final public func append(fatalError error: Error) {
        append(fatalErrors: [error])
    }

    final public func child(_ child: Operation, didEncounterFatalError error: Error) {
        log.warning(message: "\(child.operationName) did encounter fatal error: \(error).")
        append(fatalError: error)
    }

    final public func append(fatalErrors errors: [Error]) {
        groupErrors.write { (ward: inout GroupErrors) in
            ward.fatal.append(contentsOf: errors)
        }
    }

    final public func child(_ child: Operation, didEncounterFatalErrors errors: [Error]) {
        log.warning(message: "\(child.operationName) did encounter \(errors.count) fatal errors.")
        append(fatalErrors: errors)
    }

    public func child(_ child: Operation, didAttemptRecoveryFromErrors errors: [Error]) {
        groupErrors.write { (ward: inout GroupErrors) in
            ward.attemptedRecovery[child] = errors
        }
    }

    fileprivate var attemptedRecovery: GroupErrors.ByOperation {
        return groupErrors.read { $0.attemptedRecovery }
    }

    final public func childDidRecoverFromErrors(_ child: Operation) {
        if let _ = attemptedRecovery[child] {
            log.notice(message: "successfully recovered from errors in \(child)")
            groupErrors.write { (ward: inout GroupErrors) in
                ward.attemptedRecovery.removeValue(forKey: child)
            }
        }
    }

    final public func childDidNotRecoverFromErrors(_ child: Operation) {
        log.notice(message: "failed to recover from errors in \(child)")
        groupErrors.write { (ward: inout GroupErrors) in
            if let errors = ward.attemptedRecovery.removeValue(forKey: child) {
                ward.fatal.append(contentsOf: errors)
            }
        }
    }
}

// MARK: - Finishing

fileprivate extension GroupProcedure {

    fileprivate final class CanFinishGroup: Operation {

        private weak var group: GroupProcedure?
        private var _isFinished = false
        private var _isExecuting = false

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

                group.log.verbose(message: "executing can finish group operation.")

                // All operations that were added as a side-effect of anything up to
                // WillFinishObservers of prior operations should have been executed.
                //
                // Handle an edge case caused by concurrent calls to Group.add(children:)

                let isWaiting: Bool = group.groupFinishLock.withCriticalScope {

                    // Is anything currently adding operations?
                    guard group.groupIsAddingOperations.wait(timeout: DispatchTime.now()) == .success else {
                        // Operations are actively being added to the group
                        // Wait for this to complete before proceeding.
                        //
                        // Register to dispatch a new call to execute() in the future, after the
                        // wait completes (i.e. after concurrent calls to Group.add(children:)
                        // have completed), and return from this call to execute() without finishing
                        // the operation.
                        group.log.verbose(message: "cannot finish now, as group is currently adding children.")

                        let dispatchQueue = DispatchQueue.global(qos: group.qualityOfService.qosClass)
                        group.groupIsAddingOperations.notify(queue: dispatchQueue, execute: execute)

                        return true
                    }

                    // Check whether new children were added prior to the lock
                    // by checking for child operations that are not finished.

                    let active = group.children.filter({ !$0.isFinished })
                    if !active.isEmpty {

                        // Children were added after this CanFinishOperation became
                        // ready, but before it executed or before the lock could be acquired.

                        group.log.verbose(message: "cannot finish now, as there are children still active.")

                        // The GroupProcedure should wait for these children to finish
                        // before finishing. Add the oustanding children as
                        // dependencies to a new CanFinishGroup, and add that as the
                        // Group's new CanFinishGroup.

                        let newCanFinishGroup = GroupProcedure.CanFinishGroup(group: group)

                        active.forEach { newCanFinishGroup.addDependency($0) }

                        group.groupCanFinish = newCanFinishGroup

                        group.add(canFinishGroup: newCanFinishGroup)
                    }
                    else {
                        // There are no additional children to handle.
                        // Ensure that no new operations can be added.

                        group.log.verbose(message: "can now finish.")

                        group.groupIsFinishing = true
                    }

                    return false
                } // End of isWaiting

                guard !isWaiting else { return }
            }

            isExecuting = false
            isFinished = true
        }

        override private(set) var isExecuting: Bool {
            get { return _isExecuting }
            set {
                willChangeValue(forKey: .executing)
                _isExecuting = newValue
                didChangeValue(forKey: .executing)
            }
        }

        override private(set) var isFinished: Bool {
            get { return _isFinished }
            set {
                willChangeValue(forKey: .finished)
                _isFinished = newValue
                didChangeValue(forKey: .finished)
            }
        }
    }

    fileprivate func add(canFinishGroup: CanFinishGroup) {
        finishing.addDependency(canFinishGroup)
        queue.add(canFinishGroup: canFinishGroup)
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

// MARK: - Unavailable

public extension GroupProcedure {

    @available(*, unavailable, renamed: "children")
    var operations: [Operation] { return children }

    @available(*, unavailable, renamed: "isSuspended")
    final var suspended: Bool { return isSuspended }

    @available(*, unavailable, renamed: "add(child:)")
    func addOperation(operation: Operation) { }

    @available(*, unavailable, renamed: "add(children:)")
    func addOperations(operations: Operation...) { }

    @available(*, unavailable, renamed: "add(children:)")
    func addOperations(additional: [Operation]) { }

}
