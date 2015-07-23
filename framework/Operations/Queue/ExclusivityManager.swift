//
//  ExclusivityManager.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ExclusivityManager {

    public static let sharedInstance = ExclusivityManager()

    private let queue = Queue.Initiated.serial("me.danthorpe.Operations.Exclusivity")
    private var operations: [String: [Operation]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func addOperation(operation: Operation, categories: [String]) {
        dispatch_sync(queue) {
            for category in categories {
                self._addOperation(operation, category: category)
            }
        }
    }

    func removeOperation(operation: Operation, categories: [String]) {
        dispatch_async(queue) {
            for category in categories {
                self._removeOperation(operation, category: category)
            }
        }
    }


    private func _addOperation(operation: Operation, category: String) {
        var operationsWithThisCategory = operations[category] ?? []

        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }

        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }

    private func _removeOperation(operation: Operation, category: String) {
        let matchingOperations = operations[category]

        if  var operationsWithThisCategory = matchingOperations,
            let index = find(operationsWithThisCategory, operation) {
                operationsWithThisCategory.removeAtIndex(index)
                operations[category] = operationsWithThisCategory
        }
    }
}

extension ExclusivityManager {

    /// This should only be used as part of the unit testing
    /// and in v2+ will not be publically accessible
    public func __tearDownForUnitTesting() {
        dispatch_sync(queue) {
            for (category, operations) in self.operations {
                for operation in operations {
                    operation.cancel()
                    self._removeOperation(operation, category: category)
                }
            }
        }
    }
}
