//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
 StartedObserver is an observer which will execute a
 closure when the operation starts.
*/
public struct StartedObserver: OperationDidStartObserver {
    public typealias BlockType = Operation -> Void

    private let block: BlockType

    /**
     Initialize the observer with a block.
     
     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
    */
    public init(didStart: BlockType) {
        self.block = didStart
    }

    /// Conforms to `OperationDidStartObserver`, executes the block
    public func operationDidStart(operation: Operation) {
        block(operation)
    }
}


/**
 CancelledObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct CancelledObserver: OperationDidCancelObserver {
    public typealias BlockType = Operation -> Void

    private let block: BlockType

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didCancel: BlockType) {
        self.block = didCancel
    }

    /// Conforms to `OperationDidCancelObserver`, executes the block
    public func operationDidCancel(operation: Operation) {
        block(operation)
    }
}

/**
 ProducedOperationObserver is an observer which will execute a
 closure when the operation produces another observer.
 */
public struct ProducedOperationObserver: OperationDidProduceOperationObserver {
    public typealias BlockType = (Operation, NSOperation) -> Void

    private let block: BlockType

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
        block(operation, newOperation)
    }
}

/**
 FinishedObserver is an observer which will execute a
 closure when the operation finishes.
 */
public struct FinishedObserver: OperationDidFinishObserver {
    public typealias BlockType = (Operation, [ErrorType]) -> Void

    private let block: BlockType

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didFinish: BlockType) {
        self.block = didFinish
    }

    /// Conforms to `OperationDidFinishObserver`, executes the block
    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        block(operation, errors)
    }
}



/**
 A `OperationObserver` which accepts three different blocks for start,
 produce and finish.
 */
public struct BlockObserver: OperationObserver {

    let didStart: StartedObserver?
    let didCancel: CancelledObserver?
    let didProduce: ProducedOperationObserver?
    let didFinish: FinishedObserver?

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
    public init(didStart: StartedObserver.BlockType? = .None, didCancel: CancelledObserver.BlockType? = .None, didProduce: ProducedOperationObserver.BlockType? = .None, didFinish: FinishedObserver.BlockType? = .None) {
        self.didStart = didStart.map { StartedObserver(didStart: $0) }
        self.didCancel = didCancel.map { CancelledObserver(didCancel: $0) }
        self.didProduce = didProduce.map { ProducedOperationObserver(didProduce: $0) }
        self.didFinish = didFinish.map { FinishedObserver(didFinish: $0) }
    }

    /// Conforms to `OperationObserver`, executes the optional startHandler.
    public func operationDidStart(operation: Operation) {
        didStart?.operationDidStart(operation)
    }

    /// Conforms to `OperationObserver`, executes the optional cancellationHandler.
    public func operationDidCancel(operation: Operation) {
        didCancel?.operationDidCancel(operation)
    }

    /// Conforms to `OperationObserver`, executes the optional produceHandler.
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        didProduce?.operation(operation, didProduceOperation: newOperation)
    }

    /// Conforms to `OperationObserver`, executes the optional finishHandler.
    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        didFinish?.operationDidFinish(operation, errors: errors)
    }
}


