//
//  ExclusivityManager.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

internal class ExclusivityManager {

    static let sharedInstance = ExclusivityManager()

    private let queue = Queue.Initiated.serial("me.danthorpe.Operations.Exclusivity")
    private var operations: [String: [Operation]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func addOperation(operation: Operation, category: String) -> NSOperation? {
        return dispatch_sync(queue) { self._addOperation(operation, category: category) }
    }

    private func _addOperation(operation: Operation, category: String) -> NSOperation? {

        let operationsWithThisCategory = operations[category] ?? []

        let previous = operationsWithThisCategory.last

        if let previous = previous {
            operation.addDependencyOnPreviousMutuallyExclusiveOperation(previous)
        }

        // This observer will add the operation to the category
        operation.addObserver(WillExecuteObserver(willExecute: addOperationToCategory(category)))

        // This observer will remove the operation from the category
        operation.addObserver(DidFinishObserver(didFinish: removeOperationFromCategory(category)))

        return previous
    }

    private func addOperationToCategory(category: String) -> Operation -> Void {
        return { [unowned self] operation in
            dispatch_sync(self.queue) {
                operation.log.verbose(">>> \(category)")
                var operationsWithThisCategory = self.operations[category] ?? []
                operationsWithThisCategory.append(operation)
                self.operations[category] = operationsWithThisCategory
            }
        }
    }

    private func removeOperationFromCategory(category: String) -> (Operation, [ErrorType]) -> Void {
        return { [unowned self] operation, _ in
            dispatch_async(self.queue) {

                if let operationsWithThisCategory = self.operations[category], index = operationsWithThisCategory.indexOf(operation) {
                    var mutableOperationsWithThisCategory = operationsWithThisCategory
                    mutableOperationsWithThisCategory.removeAtIndex(index)
                    self.operations[category] = mutableOperationsWithThisCategory
                }

                operation.log.verbose("<<< \(category)")
            }
        }
    }
}

extension ExclusivityManager {

    /// This should only be used as part of the unit testing
    /// and in v2+ will not be publically accessible
    internal func __tearDownForUnitTesting() {
        dispatch_sync(queue) {
            for (category, operations) in self.operations {
                let remove = self.removeOperationFromCategory(category)
                for operation in operations {
                    operation.cancel()
                    remove(operation, [])
                }
            }
        }
    }
}
