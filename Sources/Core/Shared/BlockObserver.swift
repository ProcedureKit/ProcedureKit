//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public typealias DidAttachToOperationBlock = (operation: OldOperation) -> Void

/**
 WillStartObserver is an observer which will execute a
 closure when the operation starts.
 */
public struct WillExecuteObserver: OperationWillExecuteObserver {
    public typealias BlockType = (operation: OldOperation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(willExecute: BlockType) {
        self.block = willExecute
    }

    /// Conforms to `OperationWillStartObserver`, executes the block
    public func willExecuteOperation(_ operation: OldOperation) {
        block(operation: operation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}

@available(*, unavailable, renamed: "WillExecuteObserver")
public typealias StartedObserver = WillExecuteObserver

/**
 WillCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct WillCancelObserver: OperationWillCancelObserver {
    public typealias BlockType = (operation: OldOperation, errors: [ErrorProtocol]) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(willCancel: BlockType) {
        self.block = willCancel
    }

    /// Conforms to `OperationWillCancelObserver`, executes the block
    public func willCancelOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        block(operation: operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 DidCancelObserver is an observer which will execute a
 closure when the operation cancels.
 */
public struct DidCancelObserver: OperationDidCancelObserver {
    public typealias BlockType = (operation: OldOperation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didCancel: BlockType) {
        self.block = didCancel
    }

    /// Conforms to `OperationDidCancelObserver`, executes the block
    public func didCancelOperation(_ operation: OldOperation) {
        block(operation: operation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}

@available(*, unavailable, renamed: "DidCancelObserver")
public typealias CancelledObserver = DidCancelObserver


/**
 ProducedOperationObserver is an observer which will execute a
 closure when the operation produces another observer.
 */
public struct ProducedOperationObserver: OperationDidProduceOperationObserver {
    public typealias BlockType = (operation: OldOperation, produced: Operation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didProduce: BlockType) {
        self.block = didProduce
    }

    /// Conforms to `OperationDidProduceOperationObserver`, executes the block
    public func operation(_ operation: OldOperation, didProduceOperation newOperation: Operation) {
        block(operation: operation, produced: newOperation)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 WillFinishObserver is an observer which will execute a
 closure when the operation is about to finish.
 */
public struct WillFinishObserver: OperationWillFinishObserver {
    public typealias BlockType = (operation: OldOperation, errors: [ErrorProtocol]) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(willFinish: BlockType) {
        self.block = willFinish
    }

    /// Conforms to `OperationWillFinishObserver`, executes the block
    public func willFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        block(operation: operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}


/**
 DidFinishObserver is an observer which will execute a
 closure when the operation did just finish.
 */
public struct DidFinishObserver: OperationDidFinishObserver {
    public typealias BlockType = (operation: OldOperation, errors: [ErrorProtocol]) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter didStart: the `DidStartBlock`
     - returns: an observer.
     */
    public init(didFinish: BlockType) {
        self.block = didFinish
    }

    /// Conforms to `OperationDidFinishObserver`, executes the block
    public func didFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        block(operation: operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}

@available(*, unavailable, renamed: "DidFinishObserver")
public typealias FinishedObserver = DidFinishObserver

/**
 A `OperationObserver` which accepts three different blocks for start,
 produce and finish.
 */
public struct BlockObserver: OperationObserver {

    let willExecute: WillExecuteObserver?
    let willCancel: WillCancelObserver?
    let didCancel: DidCancelObserver?
    let didProduce: ProducedOperationObserver?
    let willFinish: WillFinishObserver?
    let didFinish: DidFinishObserver?

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     A `OperationObserver` which accepts three different blocks for start,
     produce and finish.

     The arguments all default to `.None` which means that the most
     typical use case for observing when the operation finishes. e.g.

     operation.addObserver(BlockObserver { _, errors in
     // The operation finished, maybe with errors,
     // which you should handle.
     })

     - parameter startHandler, a optional block of type OldOperation -> Void
     - parameter cancellationHandler, a optional block of type OldOperation -> Void
     - parameter produceHandler, a optional block of type (OldOperation, NSOperation) -> Void
     - parameter finishHandler, a optional block of type (OldOperation, [ErrorType]) -> Void
     */
    public init(willExecute: WillExecuteObserver.BlockType? = .none, willCancel: WillCancelObserver.BlockType? = .none, didCancel: DidCancelObserver.BlockType? = .none, didProduce: ProducedOperationObserver.BlockType? = .none, willFinish: WillFinishObserver.BlockType? = .none, didFinish: DidFinishObserver.BlockType? = .none) {
        self.willExecute = willExecute.map { WillExecuteObserver(willExecute: $0) }
        self.willCancel = willCancel.map { WillCancelObserver(willCancel: $0) }
        self.didCancel = didCancel.map { DidCancelObserver(didCancel: $0) }
        self.didProduce = didProduce.map { ProducedOperationObserver(didProduce: $0) }
        self.willFinish = willFinish.map { WillFinishObserver(willFinish: $0) }
        self.didFinish = didFinish.map { DidFinishObserver(didFinish: $0) }
    }

    /// Conforms to `OperationWillExecuteObserver`
    public func willExecuteOperation(_ operation: OldOperation) {
        willExecute?.willExecuteOperation(operation)
    }

    /// Conforms to `OperationWillCancelObserver`
    public func willCancelOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        willCancel?.willCancelOperation(operation, errors: errors)
    }

    /// Conforms to `OperationDidCancelObserver`
    public func didCancelOperation(_ operation: OldOperation) {
        didCancel?.didCancelOperation(operation)
    }

    /// Conforms to `OperationDidProduceOperationObserver`
    public func operation(_ operation: OldOperation, didProduceOperation newOperation: Operation) {
        didProduce?.operation(operation, didProduceOperation: newOperation)
    }

    /// Conforms to `OperationWillFinishObserver`
    public func willFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        willFinish?.willFinishOperation(operation, errors: errors)
    }

    /// Conforms to `OperationDidFinishObserver`
    public func didFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        didFinish?.didFinishOperation(operation, errors: errors)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: OldOperation) {
        didAttachToOperation?(operation: operation)
    }
}
