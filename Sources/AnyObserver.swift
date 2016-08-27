//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

internal func _abstractMethod(file: StaticString = #file, line: UInt = #line) {
    fatalError("Method must be overriden", file: file, line: line)
}

class AnyObserverBox_<Procedure: ProcedureProcotol>: ProcedureObserver {
    func didAttach(to procedure: Procedure) { _abstractMethod() }
    func will(execute procedure: Procedure) { _abstractMethod() }
    func will(cancel procedure: Procedure, withErrors: [Error]) { _abstractMethod() }
    func did(cancel procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
    func procedure(_ procedure: Procedure, didProduce newOperation: Operation) { _abstractMethod() }
    func will(finish procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
    func did(finish procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
}

class AnyObserverBox<Base: ProcedureObserver>: AnyObserverBox_<Base.Procedure> {
    private var base: Base

    init(_ base: Base) {
        self.base = base
    }

    override func didAttach(to procedure: Base.Procedure) {
        base.didAttach(to: procedure)
    }

    override func will(execute procedure: Base.Procedure) {
        base.will(execute: procedure)
    }

    override func will(cancel procedure: Base.Procedure, withErrors errors: [Error]) {
        base.will(cancel: procedure, withErrors: errors)
    }

    override func did(cancel procedure: Base.Procedure, withErrors errors: [Error]) {
        base.did(cancel: procedure, withErrors: errors)
    }

    override func procedure(_ procedure: Base.Procedure, didProduce newOperation: Operation) {
        base.procedure(procedure, didProduce: newOperation)
    }

    override func will(finish procedure: Base.Procedure, withErrors errors: [Error]) {
        base.will(finish: procedure, withErrors: errors)
    }

    override func did(finish procedure: Base.Procedure, withErrors errors: [Error]) {
        base.did(finish: procedure, withErrors: errors)
    }
}

public struct AnyObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    private typealias ErasedObserver = AnyObserverBox_<Procedure>

    private var box: ErasedObserver

    init<Base: ProcedureObserver>(base: Base) where Procedure == Base.Procedure {
        box = AnyObserverBox(base)
    }

    public func didAttach(to procedure: Procedure) {
        box.didAttach(to: procedure)
    }

    public func will(execute procedure: Procedure) {
        box.will(execute: procedure)
    }

    public func will(cancel procedure: Procedure, withErrors errors: [Error]) {
        box.will(cancel: procedure, withErrors: errors)
    }

    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        box.did(cancel: procedure, withErrors: errors)
    }

    public func procedure(_ procedure: Procedure, didProduce newOperation: Operation) {
        box.procedure(procedure, didProduce: newOperation)
    }

    public func will(finish procedure: Procedure, withErrors errors: [Error]) {
        box.will(finish: procedure, withErrors: errors)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        box.did(finish: procedure, withErrors: errors)
    }
}
