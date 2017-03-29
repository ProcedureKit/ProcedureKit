//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

class AnyObserverBox_<Procedure: ProcedureProtocol>: ProcedureObserver {
    func didAttach(to procedure: Procedure) { _abstractMethod() }
    func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) { _abstractMethod() }
    func did(execute procedure: Procedure) { _abstractMethod() }
    func did(cancel procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
    func procedure(_ procedure: Procedure, willAdd newOperation: Operation) { _abstractMethod() }
    func procedure(_ procedure: Procedure, didAdd newOperation: Operation) { _abstractMethod() }
    func will(finish procedure: Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) { _abstractMethod() }
    func did(finish procedure: Procedure, withErrors errors: [Error]) { _abstractMethod() }
    var eventQueue: DispatchQueueProtocol? { _abstractMethod(); return nil }
}

class AnyObserverBox<Base: ProcedureObserver>: AnyObserverBox_<Base.Procedure> {
    private var base: Base

    init(_ base: Base) {
        self.base = base
    }

    override func didAttach(to procedure: Base.Procedure) {
        base.didAttach(to: procedure)
    }

    override func will(execute procedure: Base.Procedure, pendingExecute: PendingExecuteEvent) {
        base.will(execute: procedure, pendingExecute: pendingExecute)
    }

    override func did(execute procedure: Base.Procedure) {
        base.did(execute: procedure)
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

    override func will(finish procedure: Base.Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) {
        base.will(finish: procedure, withErrors: errors, pendingFinish: pendingFinish)
    }

    override func did(finish procedure: Base.Procedure, withErrors errors: [Error]) {
        base.did(finish: procedure, withErrors: errors)
    }

    override var eventQueue: DispatchQueueProtocol? {
        return base.eventQueue
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

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        box.will(execute: procedure, pendingExecute: pendingExecute)
    }

    public func did(execute procedure: Procedure) {
        box.did(execute: procedure)
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

    public func will(finish procedure: Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) {
        box.will(finish: procedure, withErrors: errors, pendingFinish: pendingFinish)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        box.did(finish: procedure, withErrors: errors)
    }

    public var eventQueue: DispatchQueueProtocol? {
        return box.eventQueue
    }
}
