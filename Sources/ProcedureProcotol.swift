//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol ProcedureProcotol {

    var isExecuting: Bool { get }

    var isFinished: Bool { get }

    var isCancelled: Bool { get }

//    var errors: [Error] { get }

    // Execution

    func willEnqueue()

    func execute()

    func produce(operation: Operation)

    // Cancelling

    func cancel(withErrors: [Error])

    func procedureWillCancel(withErrors: [Error])

    func procedureDidCancel(withErrors: [Error])

    // Finishing

    func finish(withErrors: [Error])

    func procedureWillFinish(withErrors: [Error])

    func procedureDidFinish(withErrors: [Error])

    // Observers

    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Self

}

public extension ProcedureProcotol {

    public func cancel(withError error: Error?) {
        cancel(withErrors: error.map { [$0] } ?? [])
    }

    public func procedureWillCancel(withErrors: [Error]) { }

    public func procedureDidCancel(withErrors: [Error]) { }

    public func finish(withError error: Error? = nil) {
        finish(withErrors: error.map { [$0] } ?? [])
    }

    public func procedureWillFinish(withErrors: [Error]) { }

    public func procedureDidFinish(withErrors: [Error]) { }

}
