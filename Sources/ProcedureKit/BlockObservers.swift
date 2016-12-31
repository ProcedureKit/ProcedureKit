//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public struct Observer<Procedure: ProcedureProtocol> {

    public typealias VoidBlock = (Procedure) -> Void
    public typealias ErrorsBlock = (Procedure, [Error]) -> Void
    public typealias ProducerBlock = (Procedure, Operation) -> Void

    public typealias DidAttach = VoidBlock
    public typealias WillExecute = VoidBlock
    public typealias DidExecute = VoidBlock
    public typealias WillCancel = ErrorsBlock
    public typealias DidCancel = ErrorsBlock
    public typealias WillAdd = ProducerBlock
    public typealias DidAdd = ProducerBlock
    public typealias WillFinish = ErrorsBlock
    public typealias DidFinish = ErrorsBlock

    private init() { }
}

public struct BlockObserver<Procedure: ProcedureProtocol>: ProcedureObserver {

    /// - returns: the block which is called when the observer is attached to a procedure
    public let didAttach: Observer<Procedure>.DidAttach?

    /// - returns: the block which is called when the attached procedure will execute
    public let willExecute: Observer<Procedure>.WillExecute?

    /// - returns: the block which is called when the attached procedure did execute
    public let didExecute: Observer<Procedure>.DidExecute?

    /// - returns: the block which is called when the attached procedure will cancel
    public let willCancel: Observer<Procedure>.WillCancel?

    /// - returns: the block which is called when the attached procedure did cancel
    public let didCancel: Observer<Procedure>.DidCancel?

    /// - returns: the block which is called when the attached procedure will add a new operation
    public let willAdd: Observer<Procedure>.WillAdd?

    /// - returns: the block which is called when the attached procedure did add a new operation
    public let didAdd: Observer<Procedure>.DidAdd?

    /// - returns: the block which is called when the attached procedure will finish
    public let willFinish: Observer<Procedure>.WillFinish?

    /// - returns: the block which is called when the attached procedure did finish
    public let didFinish: Observer<Procedure>.DidFinish?

    /// Creates a new BlockObserver.
    ///
    /// - parameter didAttach:   the block which will execute when the observer is attached to a procedure
    /// - parameter willExecute: the block which is called when the attached procedure will execute
    /// - parameter willCancel:  the block which is called when the attached procedure will cancel
    /// - parameter didCancel:   the block which is called when the attached procedure did cancel
    /// - parameter willAdd:     the block which is called when the attached procedure will add a new operation
    /// - parameter didAdd:      the block which is called when the attached procedure did add a new operation
    /// - parameter willFinish:  the block which is called when the attached procedure will finish
    /// - parameter didFinish:   the block which is called when the attached procedure did finish
    ///
    /// - returns: an immutable BlockObserver
    public init(
        didAttach: Observer<Procedure>.DidAttach? = nil,
        willExecute: Observer<Procedure>.WillExecute? = nil,
        didExecute: Observer<Procedure>.DidExecute? = nil,
        willCancel: Observer<Procedure>.WillCancel? = nil,
        didCancel: Observer<Procedure>.DidCancel? = nil,
        willAdd: Observer<Procedure>.WillAdd? = nil,
        didAdd: Observer<Procedure>.DidAdd? = nil,
        willFinish: Observer<Procedure>.WillFinish? = nil,
        didFinish: Observer<Procedure>.DidFinish? = nil) {
            self.didAttach = didAttach
            self.willExecute = willExecute
            self.didExecute = didExecute
            self.willCancel = willCancel
            self.didCancel = didCancel
            self.willAdd = willAdd
            self.didAdd = didAdd
            self.willFinish = willFinish
            self.didFinish = didFinish
    }

    public func didAttach(to procedure: Procedure) {
        didAttach?(procedure)
    }

    public func will(execute procedure: Procedure) {
        willExecute?(procedure)
    }

    public func did(execute procedure: Procedure) {
        didExecute?(procedure)
    }

    public func will(cancel procedure: Procedure, withErrors errors: [Error]) {
        willCancel?(procedure, errors)
    }

    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        didCancel?(procedure, errors)
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        willAdd?(procedure, newOperation)
    }

    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        didAdd?(procedure, newOperation)
    }

    public func will(finish procedure: Procedure, withErrors errors: [Error]) {
        willFinish?(procedure, errors)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        didFinish?(procedure, errors)
    }
}

/// WillExecuteObserver is an observer which will execute a
/// closure when the operation starts.
public struct WillExecuteObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillExecute

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /**
     Initialize the observer with a block.

     - parameter willExecute: the `Block`
     - returns: an observer.
     */
    public init(willExecute: @escaping Observer<Procedure>.WillExecute) {
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

/// DidExecuteObserver is an observer which will execute a
/// closure when the operation starts.
///
/// - notes: this observer will be invoked directly after the
/// `execute` returns.
///
/// - warning: there are no guarantees about when this observer
/// will be called, relative to the lifecycle of the procedure. It
/// is entirely possible that the procedure, will actually
/// have already finished be the time the observer is invoked. See
/// the conversation here which explains the reasoning behind it:
/// https://github.com/ProcedureKit/ProcedureKit/pull/554
public struct DidExecuteObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidExecute

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /**
     Initialize the observer with a block.

     - parameter didExecute: the `Block`
     - returns: an observer.
     */
    public init(didExecute: @escaping Observer<Procedure>.DidExecute) {
        self.block = didExecute
    }

    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Conforms to `DidExecuteProcedureObserver`, executes the block
    public func did(execute procedure: Procedure) {
        block(procedure)
    }
}

/// WillCancelObserver is an observer which will execute a
/// closure when the operation cancels.
public struct WillCancelObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillCancel

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter willCancel: the `Block`
    /// - returns: an observer.
    public init(willCancel: @escaping Observer<Procedure>.WillCancel) {
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
public struct DidCancelObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidCancel

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter didCancel: the `Block`
    /// - returns: an observer.
    public init(didCancel: @escaping Observer<Procedure>.DidCancel) {
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

/// WillAddOperationObserver is an observer which will execute a
/// closure when the operation will add another operation.
public struct WillAddOperationObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillAdd

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter willAdd: the `Block`
    /// - returns: an observer.
    public init(willAdd: @escaping Observer<Procedure>.WillAdd) {
        self.block = willAdd
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure will add another Operation.
    /// - parameter procedure: the procedure which will add another Operation.
    /// - parameter newOperation: the new Operation instance which will be added.
    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/// DidAddOperationObserver is an observer which will execute a
/// closure when the operation did add another operation.
public struct DidAddOperationObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidAdd

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter didAdd: the `Block`
    /// - returns: an observer.
    public init(didAdd: @escaping Observer<Procedure>.DidAdd) {
        self.block = didAdd
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did add another Operation.
    /// - parameter procedure: the procedure which did add another Operation.
    /// - parameter newOperation: the new Operation instance which was added.
    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/// WillFinishObserver is an observer which will execute a
/// closure when the operation is about to finish.
public struct WillFinishObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillFinish

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter willFinish: the `Block`
    /// - returns: an observer.
    public init(willFinish: @escaping Observer<Procedure>.WillFinish) {
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
public struct DidFinishObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidFinish

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach? = nil

    /// Initialize the observer with a block.
    /// - parameter didFinish: the `Block`
    /// - returns: an observer.
    public init(didFinish: @escaping Observer<Procedure>.DidFinish) {
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

public extension ProcedureProtocol {

    /// Adds a WillExecuteObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked before execute is called.
    func addWillExecuteBlockObserver(block: @escaping Observer<Self>.WillExecute) {
        add(observer: WillExecuteObserver(willExecute: block))
    }

    /// Adds a DidExecuteObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked after execute is called.
    func addDidExecuteBlockObserver(block: @escaping Observer<Self>.DidExecute) {
        add(observer: DidExecuteObserver(didExecute: block))
    }

    /// Adds a WillCancelObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked before the procedure cancels.
    func addWillCancelBlockObserver(block: @escaping Observer<Self>.WillCancel) {
        add(observer: WillCancelObserver(willCancel: block))
    }

    /// Adds a DidCancelObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked after the procedure cancels.
    func addDidCancelBlockObserver(block: @escaping Observer<Self>.DidCancel) {
        add(observer: DidCancelObserver(didCancel: block))
    }

    /// Adds a WillAddOperationObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked before the procedure adds another operation.
    func addWillAddOperationBlockObserver(block: @escaping Observer<Self>.WillAdd) {
        add(observer: WillAddOperationObserver(willAdd: block))
    }

    /// Adds a DidAddOperationObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked after the procedure adds another operation.
    func addDidAddOperationBlockObserver(block: @escaping Observer<Self>.DidAdd) {
        add(observer: DidAddOperationObserver(didAdd: block))
    }

    /// Adds a WillFinishObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked before the procedure finishes.
    func addWillFinishBlockObserver(block: @escaping Observer<Self>.WillFinish) {
        add(observer: WillFinishObserver(willFinish: block))
    }

    /// Adds a DidFinishObserver to the receiver using a provided block
    ///
    /// - Parameter block: the block which will be invoked after the procedure has finished.
    func addDidFinishBlockObserver(block: @escaping Observer<Self>.DidFinish) {
        add(observer: DidFinishObserver(didFinish: block))
    }
}
