//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
     Add a dependency to the operation, using Swift 3 API style
     - parameter dependency: the Operation to add as a dependency
    */
    func add(dependency: Operation) {
        addDependency(dependency)
    }

    /**
     Adds dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a variable number of Operation instances
     */
    func add(dependencies: Operation...) {
        add(dependencies: dependencies)
    }

    /**
     Adds dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a sequencey of Operation instances
     */
    func add<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(add(dependency:))
    }

    /**
     Remove dependency from the operation, using Swift 3 API style
     - parameter dependency: a sequencey of Operation instances
     */
    func remove(dependency: Operation) {
        removeDependency(dependency)
    }

    /**
     Removes dependencies to the operation, using Swift 3 API style
     - parameter dependencies: a sequencey of Operation instances
     */
    func remove<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(remove(dependency:))
    }

    /// Removes all dependencies from the operation
    func removeAllDependencies() {
        remove(dependencies: dependencies)
    }

    /**
     Add self as a dependency of a new operation and return both operations
     - parameter operation: the Operation instance to add the receiver as a dependency
     - returns: an array of both operations.
    */
    func then(do operation: Operation) -> [Operation] {
        assert(!isFinished, "Cannot add a finished operation as a dependency.")
        operation.add(dependency: self)
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
    
    /**
     Sets the quality of service of the Operation from `UserIntent`
     - parameter userIntent: a UserIntent value
     */
    @available(*, deprecated: 4.5.0, message: "Use underlying quality of service APIs instead.")
    func setQualityOfService(fromUserIntent userIntent: UserIntent) { }
}
