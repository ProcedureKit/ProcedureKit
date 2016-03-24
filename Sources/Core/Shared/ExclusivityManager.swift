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
    private var operations: [String: [NSOperation]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func addOperation(operation: NSOperation, category: String) {
        dispatch_sync(queue) {
            self._addOperation(operation, category: category)
        }
    }

    func removeOperation(operation: NSOperation, category: String) {
        dispatch_async(queue) {
            self._removeOperation(operation, category: category)
        }
    }

    private func _addOperation(operation: NSOperation, category: String) {
        if let op = operation as? Operation {
            op.log.verbose(" >>> \(category)")
            op.addObserver(DidFinishObserver { [unowned self] op, _ in
                self.removeOperation(op, category: category)
            })
        }
        else {
            operation.addCompletionBlock { [unowned self, weak operation] in
                if let op = operation {
                    self.removeOperation(op, category: category)
                }
            }
        }

        var operationsWithThisCategory = operations[category] ?? []

        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }

        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }

    private func _removeOperation(operation: NSOperation, category: String) {
        if let op = operation as? Operation {
            op.log.verbose(" <<< \(category)")
        }

        if var operationsWithThisCategory = operations[category], let index = operationsWithThisCategory.indexOf(operation) {
            operationsWithThisCategory.removeAtIndex(index)
            operations[category] = operationsWithThisCategory
        }
    }
}

extension ExclusivityManager {

    /// This should only be used as part of the unit testing
    /// and in v2+ will not be publically accessible
    internal func __tearDownForUnitTesting() {
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
