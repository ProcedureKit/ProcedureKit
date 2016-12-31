//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

class AnyObserverBox_<Procedure: ProcedureProtocol>: ProcedureObserver {
    func didAttach(to procedure: Procedure) { _abstractMethod() }
    func will(execute procedure: Procedure) { _abstractMethod() }
    func did(execute procedure: Procedure) { _abstractMethod() }
    func will(cancel procedure: Procedure, withErrors: [Error]) { _abstractMethod() }
    func did(cancel procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
    func procedure(_ procedure: Procedure, willAdd newOperation: Operation) { _abstractMethod() }
    func procedure(_ procedure: Procedure, didAdd newOperation: Operation) { _abstractMethod() }
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

    override func did(execute procedure: Base.Procedure) {
        base.did(execute: procedure)
    }

    override func will(cancel procedure: Base.Procedure, withErrors errors: [Error]) {
        base.will(cancel: procedure, withErrors: errors)
    }

    override func did(cancel procedure: Base.Procedure, withErrors errors: [Error]) {
        base.did(cancel: procedure, withErrors: errors)
    }

    override func procedure(_ procedure: Base.Procedure, willAdd newOperation: Operation) {
        base.procedure(procedure, willAdd: newOperation)
    }

    override func procedure(_ procedure: Base.Procedure, didAdd newOperation: Operation) {
        base.procedure(procedure, didAdd: newOperation)
    }

    override func will(finish procedure: Base.Procedure, withErrors errors: [Error]) {
        base.will(finish: procedure, withErrors: errors)
    }

    override func did(finish procedure: Base.Procedure, withErrors errors: [Error]) {
        base.did(finish: procedure, withErrors: errors)
    }
}

public struct AnyObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private typealias Erased = AnyObserverBox_<Procedure>

    private var box: Erased

    init<Base: ProcedureObserver>(base: Base) where Procedure == Base.Procedure {
        box = AnyObserverBox(base)
    }

    public func didAttach(to procedure: Procedure) {
        box.didAttach(to: procedure)
    }

    public func will(execute procedure: Procedure) {
        box.will(execute: procedure)
    }

    public func did(execute procedure: Procedure) {
        box.did(execute: procedure)
    }

    public func will(cancel procedure: Procedure, withErrors errors: [Error]) {
        box.will(cancel: procedure, withErrors: errors)
    }

    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        box.did(cancel: procedure, withErrors: errors)
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        box.procedure(procedure, willAdd: newOperation)
    }

    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        box.procedure(procedure, didAdd: newOperation)
    }

    public func will(finish procedure: Procedure, withErrors errors: [Error]) {
        box.will(finish: procedure, withErrors: errors)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        box.did(finish: procedure, withErrors: errors)
    }
}
