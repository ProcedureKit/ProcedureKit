//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

internal extension Operation {

    enum KeyPath: String {
        case cancelled = "isCancelled"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    func willChangeValue(forKey key: KeyPath) {
        willChangeValue(forKey: key.rawValue)
    }

    func didChangeValue(forKey key: KeyPath) {
        didChangeValue(forKey: key.rawValue)
    }
}

public extension Operation {

    /**
     Returns a non-optional `String` to use as the name
     of an Operation. If the `name` property is not
     set, this resorts to the class description.
     */
    var operationName: String {
        return name ?? "Unnamed Operation"
    }

    /**
     Returns a non-optional `String` to use as the name
     of an Operation. If the `name` property is not
     set, this resorts to the class description.
     */
    var procedureName: String {
        return operationName
    }

    func addCompletionBlock(block: @escaping () -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block()
            }
        }
        else {
            completionBlock = block
        }
    }

    /**
     Adds dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a sequencey of Operation instances
     */
    func addDependencies<Operations: Sequence>(_ dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(addDependency)
    }

    /**
     Adds dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a variable number of Operation instances
     */
    func addDependencies(_ dependencies: Operation...) {
        addDependencies(dependencies)
    }

    /**
     Removes dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a sequencey of Operation instances
     */
    func removeDependencies<Operations: Sequence>(_ dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(removeDependency)
    }

    /// Removes all dependencies from the operation
    func removeAllDependencies() {
        addDependencies(dependencies)
    }

    /**
     Add self as a dependency of a new operation and return both operations
     - parameter operation: the Operation instance to add the receiver as a dependency
     - returns: an array of both operations.
    */
    func then(do operation: Operation) -> [Operation] {
        assert(!isFinished, "Cannot add a finished operation as a dependency.")
        operation.addDependency(self)
        return [self, operation]
    }

    /**
     Add self as a dependency of a new operation via a throwing closure and return both operations
     - parameter block: a throwing closure which returns an optional Operation
     - returns: an array of both operations.
     */
    func then(do block: () throws -> Operation?) rethrows -> [Operation] {
        guard let operation = try block() else { return [self] }
        return then(do: operation)
    }
}


public extension Operation {

    @available(*, deprecated, renamed: "addDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func add<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        addDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "addDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func add(dependencies: Operation...) {
        addDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "addDependency(_:)", message: "This has been removed.")
    func add(dependency: Operation) {
        addDependency(dependency)
    }

    @available(*, deprecated, renamed: "addDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func remove<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        removeDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "removeDependency(_:)", message: "This has been removed.")
    func remove(dependency: Operation) {
        removeDependency(dependency)
    }
}
