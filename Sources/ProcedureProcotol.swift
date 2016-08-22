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

    func willEnqueue()

    func execute()

    func cancel()

    func cancel(withError: Error?)

    func cancel(withErrors: [Error])

    func finish(withErrors: [Error])

    // Observers

    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Self

    func procedureWillCancel(withErrors: [Error])

    func procedureDidCancel(withErrors: [Error])

}

public extension ProcedureProcotol {

    public func procedureWillCancel(withErrors: [Error]) { }

    public func procedureDidCancel(withErrors: [Error]) { }
}
