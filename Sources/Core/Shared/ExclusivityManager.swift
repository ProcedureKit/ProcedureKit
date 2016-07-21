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

    private let queue = Queue.initiated.serial("me.danthorpe.Operations.Exclusivity")
    private var operations: [String: [Procedure]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func addOperation(_ operation: Procedure, category: String) -> Operation? {
        return dispatch_sync(queue: queue) { self._addOperation(operation, category: category) }
    }

    func removeOperation(_ operation: Procedure, category: String) {
        queue.async {
            self._removeOperation(operation, category: category)
        }
    }

    private func _addOperation(_ operation: Procedure, category: String) -> Operation? {
        operation.log.verbose(">>> \(category)")

        operation.addObserver(DidFinishObserver { [unowned self] op, _ in
            self.removeOperation(op, category: category)
        })

        var operationsWithThisCategory = operations[category] ?? []

        let previous = operationsWithThisCategory.last

        if let previous = previous {
            operation.addDependencyOnPreviousMutuallyExclusiveOperation(previous)
        }

        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory

        return previous
    }

    private func _removeOperation(_ operation: Procedure, category: String) {
        operation.log.verbose("<<< \(category)")

        if let operationsWithThisCategory = operations[category], let index = operationsWithThisCategory.index(of: operation) {
            var mutableOperationsWithThisCategory = operationsWithThisCategory
            mutableOperationsWithThisCategory.remove(at: index)
            operations[category] = mutableOperationsWithThisCategory
        }
    }
}

extension ExclusivityManager {

    /// This should only be used as part of the unit testing
    /// and in v2+ will not be publically accessible
    internal func __tearDownForUnitTesting() {
        queue.sync {
            for (category, operations) in self.operations {
                for operation in operations {
                    operation.cancel()
                    self._removeOperation(operation, category: category)
                }
            }
        }
    }
}
