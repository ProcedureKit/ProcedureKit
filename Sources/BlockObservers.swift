//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/// Protocol for block based procedure observers
public protocol BlockProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /// - returns: an optional DidAttachToProcedureBlock
    var didAttachToProcedure: ((P) -> Void)? { get }
}

public extension BlockProcedureObserver {

    /// Default implementation of ProcedureObserver method
    public func didAttach(to procedure: P) {
        didAttachToProcedure?(procedure)
    }
}

/**
 WillExecuteObserver is an observer which will execute a
 closure when the operation starts.
 */
public struct WillExecuteObserver<P: Procedure>: BlockProcedureObserver, WillExecuteProcedureObserver {
    public typealias Block = (P) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter willExecute: the `Block`
     - returns: an observer.
     */
    public init(willExecute: Block) {
        self.block = willExecute
    }

    /// Conforms to `WillExecuteProcedureObserver`, executes the block
    public func will(execute procedure: P) {
        block(procedure)
    }
}

/**
 WillCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct WillCancelObserver<P: Procedure>: BlockProcedureObserver, WillCancelProcedureObserver {
    public typealias Block = (P, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter willCancel: the `Block`
     - returns: an observer.
     */
    public init(willCancel: Block) {
        self.block = willCancel
    }

    /// Conforms to `WillCancelProcedureObserver`, executes the block
    public func will(cancel procedure: P, errors: [Error]) {
        block(procedure, errors)
    }
}

/**
 DidCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct DidCancelObserver<P: Procedure>: BlockProcedureObserver, DidCancelProcedureObserver {
    public typealias Block = (P) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter didCancel: the `Block`
     - returns: an observer.
     */
    public init(didCancel: Block) {
        self.block = didCancel
    }

    /// Conforms to `OperationDidCancelObserver`, executes the block
    public func did(cancel procedure: P) {
        block(procedure)
    }
}

/**
 DidProduceOperationObserver is an observer which will execute a
 closure when the operation produces another observer.
 */
public struct DidProduceOperationObserver<P: Procedure>: BlockProcedureObserver, DidProduceOperationProcedureObserver {
    public typealias Block = (P, Operation) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter didProduce: the `Block`
     - returns: an observer.
     */
    public init(didProduce: Block) {
        self.block = didProduce
    }

    /// Conforms to `OperationDidProduceOperationObserver`, executes the block
    public func procedure(_ procedure: P, didProduce newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/**
 WillFinishObserver is an observer which will execute a
 closure when the operation is about to finish.
 */
public struct WillFinishObserver<P: Procedure>: BlockProcedureObserver, WillFinishProcedureObserver {
    public typealias Block = (P, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter willFinish: the `Block`
     - returns: an observer.
     */
    public init(willFinish: Block) {
        self.block = willFinish
    }

    /// Conforms to `OperationWillFinishObserver`, executes the block
    public func will(finish procedure: P, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/**
 DidFinishObserver is an observer which will execute a
 closure when the operation did just finish.
 */
public struct DidFinishObserver<P: Procedure>: BlockProcedureObserver, DidFinishProcedureObserver {
    public typealias Block = (P, [Error]) -> Void

    private let block: Block

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToProcedure: ((P) -> Void)? = nil

    /**
     Initialize the observer with a block.

     - parameter didFinish: the `Block`
     - returns: an observer.
     */
    public init(didFinish: Block) {
        self.block = didFinish
    }

    /// Conforms to `OperationDidFinishObserver`, executes the block
    public func did(finish procedure: P, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}



public extension Procedure {

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
