//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

// swiftlint:disable file_length

/**
 A `Procedure` subclass which enables the grouping
 of other procedures. Use `Group`s to associate
 related operations together, thereby creating higher
 levels of abstractions.
 */
open class Group: Procedure, ProcedureQueueDelegate {

    internal struct Errors {
        // TODO
    }

    internal let queue = ProcedureQueue()


    fileprivate let finishing = BlockOperation { }

    fileprivate var groupChildren: Protector<[Operation]>
    fileprivate var groupErrors = Protector(Errors())
    fileprivate var groupIsFinishing = false
    fileprivate var groupFinishLock = NSRecursiveLock()
    fileprivate var groupIsSuspended = false
    fileprivate var groupSuspendLock = NSLock()
    fileprivate var groupIsAddingOperations = DispatchGroup()



    /// - returns: the operations which have been added to the queue
    public private(set) var children: [Operation] {
        get { return groupChildren.read { $0 } }
        set { groupChildren.write { (ward: inout [Operation]) in ward = newValue } }
    }

    @available(*, unavailable, renamed: "children")
    public var operations: [Operation] { return children }










    /**
     Designated initializer for Group. Create a Group, a Procedure subclass with
     an array of Operation instances. Optionally provide the underlying dispatch
     queue for the group's internal ProcedureQueue.

     - parameter underlyingQueue: an optional DispatchQueue which defaults to nil, this
     parameter is set as the underlying queue of the group's own ProcedureQueue.
     - parameter operations: an array of Operation instances. Note that these do not
     have to be Procedure instances - you can use `Foundation.Operation` instances
     from other sources.
    */
    public init(underlyingQueue: DispatchQueue? = nil, operations: [Operation]) {

        groupChildren = Protector(operations)

        /**
         GroupOperation is responsible for calling `finish()` on cancellation
         once all of its childred have cancelled and finished, and its own
         finishing operation has finished.

         Therefore we disable `Procedure`'s automatic finishing mechanisms.
        */
        super.init(disableAutomaticFinishing: true)

        // TODO: CanFinishProcedure needs to be setup

        name = "Group"
        queue.isSuspended = true
        queue.underlyingQueue = underlyingQueue
        queue.delegate = self

        addDidCancelBlockObserver { group, errors in
            // TODO: Need to effectively cancel all child operations
        }
    }

    public convenience init(operations: Operation...) {
        self.init(operations: operations)
    }

    // MARK - OperationQueueDelegate

    public func operationQueue(_ queue: OperationQueue, willAddOperation operation: Operation) { /* no op */ }
    public func operationQueue(_ queue: OperationQueue, willFinishOperation operation: Operation) { /* no op */ }
    public func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Operation) { /* no op */ }

    // MARK: - ProcedureQueueDelegate

    public func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation) {

    }

    public func procedureQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation) {

    }

    public func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {

    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [Error]) {

    }
}

// MARK: - OperationQueue API

public extension Group {

    /**
     The maximum number of child operations that can execute at the same time.

     The value in this property affects only the operations that the current GroupOperation has
     executing at the same time. Other operation queues and GroupOperations can also execute
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
     A Boolean value indicating whether the Group is actively scheduling operations for execution.

     When the value of this property is false, the GroupOperation actively starts child operations
     that are ready to execute once the GroupOperation has been executed.

     Setting this property to true prevents the GroupOperation from starting any child operations,
     but already executing child operations continue to execute.

     You may continue to add operations to a GroupOperation that is suspended but those operations
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

    @available(*, unavailable, renamed: "isSuspended")
    final var suspended: Bool { return isSuspended }

    /**
     The default service level to apply to the GroupOperation and its child operations.

     This property specifies the service level applied to the GroupOperation itself, and to
     operation objects added to the GroupOperation.

     If the added operation object has an explicit service level set, that value is used instead.

     For more, see the NSOperation and NSOperationQueue documentation for `qualityOfService`.
     */
    @available(OSX 10.10, iOS 8.0, tvOS 8.0, watchOS 2.0, *)
    final override var qualityOfService: QualityOfService {
        get { return queue.qualityOfService }
        set {
            super.qualityOfService = newValue
            queue.qualityOfService = newValue
        }
    }
}

// MARL - Add Child API

public extension Group {

    /**
     Add a single child Operation instance to the group
     - parameter child: an Operation instance
    */
    func add(child: Operation) {
        add(children: child)
    }

    /**
     Add children Operation instances to the group
     - parameter children: a variable number of Operation instances
     */
    func add(children: Operation...) {
        add(children: children)
    }

    /**
     Add a sequence of Operation instances to the group
     - parameter children: a sequence of Operation instances
     */
    func add<Children: Collection>(children: Children) where Children.Iterator.Element: Operation {
        add(additional: children, toOperationsArray: true)
    }

    private var shouldAddChildren: Bool {
        return groupFinishLock.withCriticalScope {
            guard !groupIsFinishing else { return false }
            groupIsAddingOperations.enter()
            return true
        }
    }

    private func add<Additional: Collection>(additional: Additional, toOperationsArray shouldAddToProperty: Bool) where Additional.Iterator.Element: Operation {
        // Exit early if there are no children in the collection
        guard !additional.isEmpty else { return }

        // Check to see if should add child operations, depending on finishing state
        guard shouldAddChildren else {
            let message = !finishing.isFinished ? "started to finish" : "completed"
            assertionFailure("Cannot add new children to a group after the group has \(message).")
            return
        }

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
        }
    }
}
