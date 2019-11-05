//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/**
 A generic condition for describing operations that
 cannot be allowed to execute concurrently.
 */
public final class MutuallyExclusive<T>: Condition {

    /// Public constructor
    public init(category: String = "MutuallyExclusive<\(T.self)>") {
        super.init()
        name = "MutuallyExclusive<\(T.self)>"
        addToAttachedProcedure(mutuallyExclusiveCategory: category)
    }

    /// Required public override, but there is no evaluation, so it just completes with `.Satisfied`.
    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.success(true))
    }
}

/// Manages Exclusivity locks. A single shared instance (per-process) is used by the framework.
///
/// - NOTE: You should not interact with ExclusivityManager directly.
/// Instead, add `MutuallyExclusive` Conditions to Procedures.
///
/// - see: `MutuallyExclusive`
final public class ExclusivityManager {

    static let sharedInstance = ExclusivityManager()

    fileprivate let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Exclusivity", qos: DispatchQoS.userInitiated) // serial dispatch queue

    fileprivate let completeLocksQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.ExclusivityCompleteLocks", qos: DispatchQoS.userInitiated, attributes: [.concurrent])
    fileprivate var categoryQueues: [String: [DispatchGroup]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    /// Asynchronously requests a lock for a set of categories, and calls the completion block
    /// once it is acquired.
    ///
    /// The set of categories must not be empty.
    ///
    /// The completion block is *always* called asynchronously.
    ///
    /// - Parameters:
    ///   - categories: a Set of Strings - each String is treated as a unique lock identifier
    ///   - completion: a block called once the lock on every category is acquired
    internal func requestLock(for categories: Set<String>, completion: @escaping () -> Void) {
        guard !categories.isEmpty else {
            // No categories requested
            fatalError("A request for Mutual Exclusivity locks was made with no categories specified. This request is unnecessary.") // ProcedureKit internal programmer error
        }

        queue.async { self._requestLock(for: categories, completion: completion) }
    }

    private func _requestLock(for categories: Set<String>, completion: @escaping () -> Void) {
        assert(!categories.isEmpty)

        // Create a new dispatch group for this lock request
        let categoriesGroup = DispatchGroup()

        var unavailableCategories = 0
        // Add the procedure to each category's queue
        for category in categories {
            switch _requestLock(forCategory: category, withGroup: categoriesGroup) {
            case .immediatelyAvailable:
                // Do nothing - continue directly to the next category
                break
            case .waitingForLock:
                unavailableCategories += 1
            }
        }

        // If the lock was immediately acquired for all categories:
        if unavailableCategories == 0 {
            // call completion now
            //            completeLocksQueue.async {
            completion()
            //            }
        }
        else {
            // Otherwise, wait on the DispatchGroup created for this lock request

            // Enter it once for every category on which we must wait
            (0..<unavailableCategories).forEach { _ in categoriesGroup.enter() }

            // Schedule a notification when the lock for all those categories has been acquired
            categoriesGroup.notify(queue: completeLocksQueue) {
                completion()
            }
        }
    }

    private enum RequestLockResult {
        case immediatelyAvailable
        case waitingForLock
    }
    private func _requestLock(forCategory category: String, withGroup group: DispatchGroup) -> RequestLockResult {
        var queueForThisCategory = categoryQueues[category] ?? []
        let isFrontOfTheQueueForThisCategory = queueForThisCategory.isEmpty
        queueForThisCategory.append(group)
        categoryQueues[category] = queueForThisCategory

        return (isFrontOfTheQueueForThisCategory) ? .immediatelyAvailable : .waitingForLock
    }

    internal func unlock(categories: Set<String>) {
        queue.async { self._unlock(categories: categories) }
    }

    private func _unlock(categories: Set<String>) {
        for category in categories {
            _unlock(category: category)
        }
    }

    internal func _unlock(category: String) {
        guard var queueForThisCategory = categoryQueues[category] else { return }
        // Remove the first item in the queue for this category
        // (which should be the procedure that currently has the lock).
        assert(!queueForThisCategory.isEmpty)
        _ = queueForThisCategory.removeFirst()

        // If another operation is waiting on this particular lock
        if let nextOperationForLock = queueForThisCategory.first {
            // Leave its DispatchGroup (i.e. it "acquires" the lock for this category)
            nextOperationForLock.leave()
        }

        if !queueForThisCategory.isEmpty {
            categoryQueues[category] = queueForThisCategory
        }
        else {
            categoryQueues.removeValue(forKey: category)
        }
    }
}

public extension ExclusivityManager {

    /// This should only be used as part of the unit testing
    /// - WARNING: This immediately frees up any oustanding mutual exclusion.
    static func __tearDownForUnitTesting() {
        sharedInstance.__tearDownForUnitTesting()
    }

    /// This should only be used as part of the unit testing
    fileprivate func __tearDownForUnitTesting() {
        queue.sync {
            for (_, dispatchGroups) in categoryQueues {
                // Skip the first item in the category, because
                // it's the one that currently holds the lock.
                for group in dispatchGroups.suffix(from: 1) {
                    group.leave()
                }
            }
            categoryQueues.removeAll()
        }
    }
}
