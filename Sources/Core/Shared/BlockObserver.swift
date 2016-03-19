//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public typealias DidAttachToOperationBlock = (operation: Operation) -> Void

/**
 StartedObserver is an observer which will execute a
 closure when the operation starts.
*/
public struct StartedObserver: OperationDidStartObserver {
    public typealias BlockType = (operation: Operation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
    */
    public init(didStart: BlockType) {
        self.block = didStart
    }

    /// Conforms to `OperationDidStartObserver`, executes the block
    public func didStartOperation(operation: Operation) {
        block(operation: operation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 CancelledObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct CancelledObserver: OperationDidCancelObserver {
    public typealias BlockType = (operation: Operation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didCancel: BlockType) {
        self.block = didCancel
    }

    /// Conforms to `OperationDidCancelObserver`, executes the block
    public func didCancelOperation(operation: Operation) {
        block(operation: operation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 ProducedOperationObserver is an observer which will execute a
 closure when the operation produces another observer.
 */
public struct ProducedOperationObserver: OperationDidProduceOperationObserver {
    public typealias BlockType = (operation: Operation, produced: NSOperation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didProduce: BlockType) {
        self.block = didProduce
    }

    /// Conforms to `OperationDidProduceOperationObserver`, executes the block
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        block(operation: operation, produced: newOperation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 WillFinishObserver is an observer which will execute a
 closure when the operation is about to finish.
 */
public struct WillFinishObserver: OperationWillFinishObserver {
    public typealias BlockType = (operation: Operation, errors: [ErrorType]) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(willFinish: BlockType) {
        self.block = willFinish
    }

    /// Conforms to `OperationWillFinishObserver`, executes the block
    public func willFinishOperation(operation: Operation, errors: [ErrorType]) {
        block(operation: operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 DidFinishObserver is an observer which will execute a
 closure when the operation did just finish.
 */
public struct DidFinishObserver: OperationDidFinishObserver {
    public typealias BlockType = (operation: Operation, errors: [ErrorType]) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didFinish: BlockType) {
        self.block = didFinish
    }

    /// Conforms to `OperationDidFinishObserver`, executes the block
    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        block(operation: operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}

@available(*, unavailable, renamed="DidFinishObserver")
public typealias FinishedObserver = DidFinishObserver

/**
 A `OperationObserver` which accepts three different blocks for start,
 produce and finish.
 */
public struct BlockObserver: OperationObserver {

    let didStart: StartedObserver?
    let didCancel: CancelledObserver?
    let didProduce: ProducedOperationObserver?
    let willFinish: WillFinishObserver?
    let didFinish: DidFinishObserver?

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     A `OperationObserver` which accepts three different blocks for start,
     produce and finish.

     The arguments all default to `.None` which means that the most
     typical use case for observing when the operation finishes. e.g.

     operation.addObserver(BlockObserver { _, errors in
     // The operation finished, maybe with errors,
     // which you should handle.
     })

     - parameter startHandler, a optional block of type Operation -> Void
     - parameter cancellationHandler, a optional block of type Operation -> Void
     - parameter produceHandler, a optional block of type (Operation, NSOperation) -> Void
     - parameter finishHandler, a optional block of type (Operation, [ErrorType]) -> Void
     */
    public init(didStart: StartedObserver.BlockType? = .None, didCancel: CancelledObserver.BlockType? = .None, didProduce: ProducedOperationObserver.BlockType? = .None, willFinish: WillFinishObserver.BlockType? = .None, didFinish: DidFinishObserver.BlockType? = .None) {
        self.didStart = didStart.map { StartedObserver(didStart: $0) }
        self.didCancel = didCancel.map { CancelledObserver(didCancel: $0) }
        self.didProduce = didProduce.map { ProducedOperationObserver(didProduce: $0) }
        self.willFinish = willFinish.map { WillFinishObserver(willFinish: $0) }
        self.didFinish = didFinish.map { DidFinishObserver(didFinish: $0) }
    }

    /// Conforms to `OperationObserver`, executes the optional startHandler.
    public func didStartOperation(operation: Operation) {
        didStart?.didStartOperation(operation)
    }

    /// Conforms to `OperationObserver`, executes the optional cancellationHandler.
    public func didCancelOperation(operation: Operation) {
        didCancel?.didCancelOperation(operation)
    }

    /// Conforms to `OperationObserver`, executes the optional produceHandler.
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        didProduce?.operation(operation, didProduceOperation: newOperation)
    }

    /// Conforms to `OperationObserver`, executes the optional willFinish.
    public func willFinishOperation(operation: Operation, errors: [ErrorType]) {
        willFinish?.willFinishOperation(operation, errors: errors)
    }

    /// Conforms to `OperationObserver`, executes the optional didFinish.
    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        didFinish?.didFinishOperation(operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}
