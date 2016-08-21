//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/// WillExecuteObserver is an observer which will execute a
/// closure when the operation starts.
public struct WillExecuteObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter willExecute: the `Block`
     - returns: an observer.
     */
    public init(willExecute: Block) {
        self.block = willExecute
    }

    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Conforms to `WillExecuteProcedureObserver`, executes the block
    public func will(execute procedure: Procedure) {
        block(procedure)
    }
}

/// WillCancelObserver is an observer which will execute a
/// closure when the operation cancels.
public struct WillCancelObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /// Initialize the observer with a block.
    /// - parameter willCancel: the `Block`
    /// - returns: an observer.
    public init(willCancel: Block) {
        self.block = willCancel
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure will be cancelled.
    /// - parameter cancel: the procedure which is cancelled.
    /// - parameter withErrors: the errors the procedure was cancelled with.
    public func will(cancel procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/// DidCancelObserver is an observer which will execute a
/// closure when the operation cancels.
public struct DidCancelObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /// Initialize the observer with a block.
    /// - parameter didCancel: the `Block`
    /// - returns: an observer.
    public init(didCancel: Block) {
        self.block = didCancel
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did cancel.
    /// - parameter cancel: the procedure which is cancelled.
    /// - parameter errors: the errors the procedure was cancelled with.
    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/// DidProduceOperationObserver is an observer which will execute a
/// closure when the operation produces another observer.
public struct DidProduceOperationObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure, Operation) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /// Initialize the observer with a block.
    /// - parameter didProduce: the `Block`
    /// - returns: an observer.
    public init(didProduce: Block) {
        self.block = didProduce
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure produces another Operation.
    /// - parameter procedure: the procedure which produced another Operation.
    /// - parameter newOperation: the new Operation instance which has been produced.
    public func procedure(_ procedure: Procedure, didProduce newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/// WillFinishObserver is an observer which will execute a
/// closure when the operation is about to finish.
public struct WillFinishObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /// Initialize the observer with a block.
    /// - parameter willFinish: the `Block`
    /// - returns: an observer.
    public init(willFinish: Block) {
        self.block = willFinish
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure will finish.
    /// - parameter procedure: the procedure which will finish.
    /// - parameter errors: the errors the procedure will finish with
    public func will(finish procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/**
 DidFinishObserver is an observer which will execute a
 closure when the operation did just finish.
 */
public struct DidFinishObserver<Procedure: ProcedureProcotol>: ProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((Procedure) -> Void)? = nil

    /// Initialize the observer with a block.
    /// - parameter didFinish: the `Block`
    /// - returns: an observer.
    public init(didFinish: Block) {
        self.block = didFinish
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did finish.
    /// - parameter procedure: the procedure which will finish.
    /// - parameter errors: the errors the procedure will finish with
    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}



public extension ProcedureProcotol {

    func addWillExecuteBlockObserver(block: WillExecuteObserver<Self>.Block) {
        add(observer: WillExecuteObserver(willExecute: block))
    }

    func addWillCancelBlockObserver(block: WillCancelObserver<Self>.Block) {
        add(observer: WillCancelObserver(willCancel: block))
    }

    func addDidCancelBlockObserver(block: DidCancelObserver<Self>.Block) {
        add(observer: DidCancelObserver(didCancel: block))
    }

    func addDidProduceOperationBlockObserver(block: DidProduceOperationObserver<Self>.Block) {
        add(observer: DidProduceOperationObserver(didProduce: block))
    }

    func addWillFinishBlockObserver(block: WillFinishObserver<Self>.Block) {
        add(observer: WillFinishObserver(willFinish: block))
    }

    func addDidFinishBlockObserver(block: DidFinishObserver<Self>.Block) {
        add(observer: DidFinishObserver(didFinish: block))
    }
}
