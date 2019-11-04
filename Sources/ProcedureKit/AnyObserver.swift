//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

class AnyObserverBox_<Procedure: ProcedureProtocol>: ProcedureObserver {
    func didAttach(to procedure: Procedure) { _abstractMethod() }
    func didSetInputReady(on procedure: Procedure) { _abstractMethod() }
    func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) { _abstractMethod() }
    func did(execute procedure: Procedure) { _abstractMethod() }
    func did(cancel procedure: Procedure, with: Error?) { _abstractMethod() }
    func procedure(_ procedure: Procedure, willAdd newOperation: Operation) { _abstractMethod() }
    func procedure(_ procedure: Procedure, didAdd newOperation: Operation) { _abstractMethod() }
    func will(finish procedure: Procedure, with: Error?, pendingFinish: PendingFinishEvent) { _abstractMethod() }
    func did(finish procedure: Procedure, with: Error?) { _abstractMethod() }
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

    override func didSetInputReady(on procedure: Base.Procedure) {
        base.didSetInputReady(on: procedure)
    }

    override func will(execute procedure: Base.Procedure, pendingExecute: PendingExecuteEvent) {
        base.will(execute: procedure, pendingExecute: pendingExecute)
    }

    override func did(execute procedure: Base.Procedure) {
        base.did(execute: procedure)
    }

    override func did(cancel procedure: Base.Procedure, with error: Error?) {
        base.did(cancel: procedure, with: error)
    }

    override func procedure(_ procedure: Base.Procedure, willAdd newOperation: Operation) {
        base.procedure(procedure, willAdd: newOperation)
    }

    override func procedure(_ procedure: Base.Procedure, didAdd newOperation: Operation) {
        base.procedure(procedure, didAdd: newOperation)
    }

    override func will(finish procedure: Base.Procedure, with error: Error?, pendingFinish: PendingFinishEvent) {
        base.will(finish: procedure, with: error, pendingFinish: pendingFinish)
    }

    override func did(finish procedure: Base.Procedure, with error: Error?) {
        base.did(finish: procedure, with: error)
    }

    override var eventQueue: DispatchQueueProtocol? {
        return base.eventQueue
    }
}

/// Creates a ProcedureObserver that wraps another ProcedureObserver and transforms the input events from
/// the input Procedure type ("R") to the wrapped ProcedureObserver's expected Procedure type ("O") (via a
/// `procedureTransformBlock`).
///
/// This observer will fail at run-time if an event handler is called with a Procedure subclass that cannot
/// be converted to the wrapped ProcedureObserver's expected Procedure type (via the transform block).
///
/// Failures are logged as warnings to the event's input Procedure.
internal class TransformObserver<O: ProcedureProtocol, R: ProcedureProtocol>: ProcedureObserver {
    private typealias Erased = AnyObserverBox_<O>
    public typealias Procedure = R

    private var wrapped: Erased
    private var procedureTransformBlock: (R) -> O?
    init<Base: ProcedureObserver>(base: Base, procedureTransformBlock: @escaping (R) -> O? = { return $0 as? O }) where O == Base.Procedure {
        wrapped = AnyObserverBox(base)
        self.procedureTransformBlock = procedureTransformBlock
    }

    private enum Event {
        case didAttach
        case didSetInputReady
        case willExecute
        case didExecute
        case didCancel
        case willAdd
        case didAdd
        case willFinish
        case didFinish

        var string: String {
            switch self {
            case .didAttach: return "didAttach"
            case .didSetInputReady: return "didSetInputReady"
            case .willExecute: return "willExecute"
            case .didExecute: return "didExecute"
            case .didCancel: return "didCancel"
            case .willAdd: return "procedureWillAdd"
            case .didAdd: return "procedureDidAdd"
            case .willFinish: return "willFinish"
            case .didFinish: return "didFinish"
            }
        }
    }

    private func typedProcedure(_ procedure: R, event: Event) -> O? {
        guard let typedProcedure = procedureTransformBlock(procedure) else {
            procedure.log.warning.message("Observer will not receive event (\(event.string)). Unable to convert \(procedure) to the expected type \"\(String(describing: O.self))\"")
            return nil
        }
        return typedProcedure
    }

    func didAttach(to procedure: Procedure) {
        guard let baseProcedure = typedProcedure(procedure, event: .didAttach) else { return }
        wrapped.didAttach(to: baseProcedure)
    }

    func didSetInputReady(on procedure: Procedure) {
        guard let baseProcedure = typedProcedure(procedure, event: .didAttach) else { return }
        wrapped.didSetInputReady(on: baseProcedure)
    }

    func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        guard let baseProcedure = typedProcedure(procedure, event: .willExecute) else { return }
        wrapped.will(execute: baseProcedure, pendingExecute: pendingExecute)
    }

    func did(execute procedure: Procedure) {
        guard let baseProcedure = typedProcedure(procedure, event: .didExecute) else { return }
        wrapped.did(execute: baseProcedure)
    }

    func did(cancel procedure: Procedure, with error: Error?) {
        guard let baseProcedure = typedProcedure(procedure, event: .didCancel) else { return }
        wrapped.did(cancel: baseProcedure, with: error)
    }

    func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        guard let baseProcedure = typedProcedure(procedure, event: .willAdd) else { return }
        wrapped.procedure(baseProcedure, willAdd: newOperation)
    }

    func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        guard let baseProcedure = typedProcedure(procedure, event: .didAdd) else { return }
        wrapped.procedure(baseProcedure, didAdd: newOperation)
    }

    func will(finish procedure: Procedure, with error: Error?, pendingFinish: PendingFinishEvent) {
        guard let baseProcedure = typedProcedure(procedure, event: .willFinish) else { return }
        wrapped.will(finish: baseProcedure, with: error, pendingFinish: pendingFinish)
    }

    func did(finish procedure: Procedure, with error: Error?) {
        guard let baseProcedure = typedProcedure(procedure, event: .didFinish) else { return }
        wrapped.did(finish: baseProcedure, with: error)
    }

    var eventQueue: DispatchQueueProtocol? {
        return wrapped.eventQueue
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

    public func didSetInputReady(on procedure: Procedure) {
        box.didSetInputReady(on: procedure)
    }

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        box.will(execute: procedure, pendingExecute: pendingExecute)
    }

    public func did(execute procedure: Procedure) {
        box.did(execute: procedure)
    }

    public func did(cancel procedure: Procedure, with error: Error?) {
        box.did(cancel: procedure, with: error)
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        box.procedure(procedure, willAdd: newOperation)
    }

    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        box.procedure(procedure, didAdd: newOperation)
    }

    public func will(finish procedure: Procedure, with error: Error?, pendingFinish: PendingFinishEvent) {
        box.will(finish: procedure, with: error, pendingFinish: pendingFinish)
    }

    public func did(finish procedure: Procedure, with error: Error?) {
        box.did(finish: procedure, with: error)
    }

    public var eventQueue: DispatchQueueProtocol? {
        return box.eventQueue
    }
}
