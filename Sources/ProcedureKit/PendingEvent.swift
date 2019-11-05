//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/// `PendingEvent` encapsulates a reference to a future `Procedure` event, and can be used
/// to ensure that asynchronous tasks are executed to completion *before* the future event.
///
/// While a reference to the `PendingEvent` exists, the event will not occur.
///
/// You cannot instantiate your own `PendingEvent` instances - only the framework
/// itself creates and provides (in certain circumstances) PendingEvents.
///
/// A common use-case is when handling a WillExecute or WillFinish observer callback.
/// ProcedureKit will provide your observer with a `PendingExecuteEvent` or a `PendingFinishEvent`.
///
/// If you must dispatch an asynchronous task from within your observer, but want to
/// ensure that the observed `Procedure` does not execute / finish until your asynchronous task
/// completes, you can use the Pending(Execute/Finish)Event like so:
///
/// ```swift
/// procedure.addWillFinishObserver { procedure, errors, pendingFinish in
///     DispatchQueue.global().async {
///         pendingFinish.doBeforeEvent {
///             // do something asynchronous
///             // this block is guaranteed to complete before the procedure finishes
///         }
//      }
/// }
/// ```
///
/// Some of the built-in `Procedure` functions take an optional "before:" parameter,
/// to which a `PendingEvent` can be directly passed. For example:
///
/// ```swift
/// procedure.addWillFinishObserver { procedure, errors, pendingFinish in
///     // produce a new operation before the procedure finishes
///     procedure.produce(BlockOperation { /* do something */ }, before: pendingFinish)
/// }
/// ```
///
final public class PendingEvent: CustomStringConvertible {
    public enum Kind: CustomStringConvertible {
        case postDidAttach
        case addOperation
        case postDidAddOperation
        case execute
        case postDidExecute
        case postDidCancel
        case finish
        case postDidFinish

        public var description: String {
            switch self {
            case .postDidAttach: return "PostDidAttach"
            case .addOperation: return "AddOperation"
            case .postDidAddOperation: return "PostAddOperation"
            case .execute: return "Execute"
            case .postDidExecute: return "PostExecute"
            case .postDidCancel: return "PostDidCancel"
            case .finish: return "Finish"
            case .postDidFinish: return "PostFinish"
            }
        }
    }

    internal let event: Kind
    internal let group: DispatchGroup
    fileprivate let procedure: ProcedureProtocol
    private let isDerivedEvent: Bool
    internal init(forProcedure procedure: ProcedureProtocol, withGroup group: DispatchGroup = DispatchGroup(), withEvent event: Kind) {
        self.group = group
        self.procedure = procedure
        self.event = event
        self.isDerivedEvent = false
        group.enter()
    }

    // Ensures that a block is executed prior to the event described by the `PendingEvent`
    public func doBeforeEvent(block: () -> Void) {
        group.enter()
        block()
        group.leave()
    }

    // Ensures that the call to this function will occur prior to the event described by the `PendingEvent`
    public func doThisBeforeEvent() {
        group.enter()
        group.leave()
    }

    deinit {
        debugProceed()
        group.leave()
    }

    private func debugProceed() {
        (procedure as? Procedure)?.log.verbose.message("(\(self)) is ready to proceed")
    }

    public var description: String {
        return "Pending\(event.description) for: \(procedure.procedureName)"
    }
}

internal extension PendingEvent {
    static let postDidAttach: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .postDidAttach) }
    static let addOperation: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .addOperation) }
    static let postDidAdd: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .postDidAddOperation) }
    static let execute: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .execute) }
    static let postDidExecute: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .postDidExecute) }
    static let postDidCancel: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .postDidCancel) }
    static let finish: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .finish) }
    static let postFinish: (Procedure) -> PendingEvent = { PendingEvent(forProcedure: $0, withEvent: .postDidFinish) }

}

public typealias PendingExecuteEvent = PendingEvent
public typealias PendingFinishEvent = PendingEvent
public typealias PendingAddOperationEvent = PendingEvent
