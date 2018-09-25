//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

public protocol ProcedureProtocol: class {

    var procedureName: String { get }

    var status: ProcedureStatus { get }

    var isExecuting: Bool { get }

    var isFinished: Bool { get }

    var isCancelled: Bool { get }

    var error: Error? { get }

    var log: ProcedureLog { get }

    // Execution

    func willEnqueue(on: ProcedureQueue)

    func pendingQueueStart()

    func execute()

    @discardableResult func produce(operation: Operation, before: PendingEvent?) throws -> ProcedureFuture

    // Cancelling

    func cancel(with: Error?)

    func procedureDidCancel(with: Error?)

    // Finishing

    func finish(with: Error?)

    func procedureWillFinish(with: Error?)

    func procedureDidFinish(with: Error?)

    // Observers

    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Self

    // Dependencies

    func add<Dependency: ProcedureProtocol>(dependency: Dependency)


    // Deprecations

    @available(*, deprecated: 5.0.0, message: "Use cancel(with:) instead. This API will now just use the first error.")
    func cancel(withErrors: [Error])

    @available(*, deprecated: 5.0.0, message: "Use procedureDidCancel(with:) instead. This API will now just use the first error.")
    func procedureDidCancel(withErrors: [Error])

    @available(*, deprecated: 5.0.0, message: "Use finish(with:) instead. This API will now just use the first error.")
    func finish(withErrors: [Error])

    @available(*, deprecated: 5.0.0, message: "Use procedureWillFinish(with:) instead. This API will now just receive a single error.")
    func procedureWillFinish(withErrors: [Error])

    @available(*, deprecated: 5.0.0, message: "Use procedureDidFinish(with:) instead. This API will now just receive a single error.")
    func procedureDidFinish(withErrors: [Error])
}


/// Default ProcedureProtocol implementations
public extension ProcedureProtocol {

    /// Boolean indicator for whether the Procedure finished with an error
    var failed: Bool {
        return error != nil
    }

    func procedureDidCancel(with: Error?) { }

    func procedureWillFinish(with: Error?) { }

    func procedureDidFinish(with: Error?) { }

    // Deprecations

    func cancel(withErrors errors: [Error]) {
        cancel(with: errors.first)
    }

    func procedureDidCancel(withErrors errors: [Error]) {
        procedureDidCancel(with: errors.first)
    }

    func finish(withErrors errors: [Error]) {
        finish(with: errors.first)
    }

    func procedureWillFinish(withErrors errors: [Error]) {
        procedureWillFinish(with: errors.first)
    }

    func procedureDidFinish(withErrors errors: [Error]) {
        procedureDidFinish(with: errors.first)
    }

}
