//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public typealias DidAttachToProcedureBlock = (Procedure) -> Void

/// Protocol for block based procedure observers
public protocol BlockProcedureObserver: ProcedureObserver {

    /// - returns: an optional DidAttachToProcedureBlock
    var didAttachToProcedure: DidAttachToProcedureBlock? { get }
}

public extension BlockProcedureObserver {

    /// Default implementation of ProcedureObserver method
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }
}

/**
 WillExecuteObserver is an observer which will execute a
 closure when the operation starts.
 */
public struct WillExecuteObserver: BlockProcedureObserver, WillExecuteProcedureObserver {
    public typealias Block = (Procedure) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter willExecute: the `Block`
     - returns: an observer.
     */
    public init(willExecute: Block) {
        self.block = willExecute
    }

    /// Conforms to `WillExecuteProcedureObserver`, executes the block
    public func will(execute procedure: Procedure) {
        block(procedure)
    }
}

/**
 WillCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct WillCancelObserver: BlockProcedureObserver, WillCancelProcedureObserver {
    public typealias Block = (Operation, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter willCancel: the `Block`
     - returns: an observer.
     */
    public init(willCancel: Block) {
        self.block = willCancel
    }

    /// Conforms to `WillCancelProcedureObserver`, executes the block
    public func will(cancel procedure: Procedure, errors: [Error]) {
        block(procedure, errors)
    }
}

/**
 DidCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct DidCancelObserver: BlockProcedureObserver, DidCancelProcedureObserver {
    public typealias Block = (Procedure) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter didCancel: the `Block`
     - returns: an observer.
     */
    public init(didCancel: Block) {
        self.block = didCancel
    }

    /// Conforms to `OperationDidCancelObserver`, executes the block
    public func did(cancel procedure: Procedure) {
        block(procedure)
    }
}

/**
 DidProduceOperationObserver is an observer which will execute a
 closure when the operation produces another observer.
 */
public struct DidProduceOperationObserver: BlockProcedureObserver, DidProduceOperationProcedureObserver {
    public typealias Block = (Procedure, Operation) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter didProduce: the `Block`
     - returns: an observer.
     */
    public init(didProduce: Block) {
        self.block = didProduce
    }

    /// Conforms to `OperationDidProduceOperationObserver`, executes the block
    public func procedure(_ procedure: Procedure, didProduce newOperation: Operation) {
        block(procedure, newOperation)
    }
}

@available(*, unavailable, renamed: "DidProduceOperationObserver")
public typealias ProducedOperationObserver = DidProduceOperationObserver

/**
 WillFinishObserver is an observer which will execute a
 closure when the operation is about to finish.
 */
public struct WillFinishObserver: BlockProcedureObserver, WillFinishProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter willFinish: the `Block`
     - returns: an observer.
     */
    public init(willFinish: Block) {
        self.block = willFinish
    }

    /// Conforms to `OperationWillFinishObserver`, executes the block
    public func will(finish procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/**
 DidFinishObserver is an observer which will execute a
 closure when the operation did just finish.
 */
public struct DidFinishObserver: BlockProcedureObserver, DidFinishProcedureObserver {
    public typealias Block = (Procedure, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: DidAttachToProcedureBlock? = nil

    /**
     Initialize the observer with a block.

     - parameter didFinish: the `Block`
     - returns: an observer.
     */
    public init(didFinish: Block) {
        self.block = didFinish
    }

    /// Conforms to `OperationDidFinishObserver`, executes the block
    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}



public extension Procedure {

    func addWillExecuteBlockObserver(block: WillExecuteObserver.Block) {
        add(observer: WillExecuteObserver(willExecute: block))
    }

    func addWillCancelBlockObserver(block: WillCancelObserver.Block) {
        add(observer: WillCancelObserver(willCancel: block))
    }

    func addDidCancelBlockObserver(block: DidCancelObserver.Block) {
        add(observer: DidCancelObserver(didCancel: block))
    }

    func addDidProduceOperationBlockObserver(block: DidProduceOperationObserver.Block) {
        add(observer: DidProduceOperationObserver(didProduce: block))
    }

    func addWillFinishBlockObserver(block: WillFinishObserver.Block) {
        add(observer: WillFinishObserver(willFinish: block))
    }

    func addDidFinishBlockObserver(block: DidFinishObserver.Block) {
        add(observer: DidFinishObserver(didFinish: block))
    }
}
