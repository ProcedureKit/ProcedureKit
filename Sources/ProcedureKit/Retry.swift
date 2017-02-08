//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

public struct RetryFailureInfo<T: Procedure> {

    /// - returns: the failed operation
    public let operation: T

    /// - returns: the errors the operation finished with
    public let errors: [Error]

    /// - returns: the previous errors of previous attempts
    public let historicalErrors: [Error]

    /// - returns: the number of attempts made so far
    public let count: Int

    /**
     This is a block which can be used to add Operation(s)
     to a queue. For example, perhaps it is necessary to
     retrying the task, but only until another operation
     has completed.

     This can be done by creating the operation, setting
     the dependency and adding it using the block.

     - returns: a block which accepts var arg Operation instances
    */
    public let addOperations: (Operation...) -> Void

    /// - returns: a logger (from the RetryProcedure)
    public let log: LoggerProtocol

    /**
     - returns: the block which is used to replace the
     configure block, which in turns configures the
     operation instances.
    */
    public let configure: (T) -> Void
}

public extension RetryFailureInfo {

    var errorCode: Int? {
        return (errors.first as? NSError)?.code
    }
}

internal class RetryIterator<T: Procedure>: IteratorProtocol {
    typealias Payload = RepeatProcedure<T>.Payload
    typealias Handler = RetryProcedure<T>.Handler
    typealias FailureInfo = RetryProcedure<T>.FailureInfo

    internal let handler: Handler
    internal var info: FailureInfo?
    private var iterator: AnyIterator<Payload>

    init<PayloadIterator: IteratorProtocol>(handler: @escaping Handler, iterator base: PayloadIterator) where PayloadIterator.Element == Payload {
        self.handler = handler
        self.iterator = AnyIterator(base)
    }

    func next() -> Payload? {
        guard let payload = iterator.next() else { return nil }
        guard let info = info else { return payload }
        return handler(info, payload)
    }
}

/**
 RetryProcedure is a RepeatProcedure subclass which can be used
 to automatically retry another instance of procedure T if the
 first instance finishes with errors. It is generic over T, a
 `Procedure` subclass.

 To support effective error recovery, in addition to a (T, Delay?)
 iterator, RetryProcedure is initialized with a block. This block
 will receive failure info, in addition to the next result (if not
 nil) of the payload iterator.

 Therefore, consumers can inspect the failure info, and adjust
 the delay, or re-configure the operation before it is retried.

 To exit with the error, this block can return nil.
 */
open class RetryProcedure<T: Procedure>: RepeatProcedure<T> {
    public typealias Handler = (FailureInfo, Payload) -> Payload?
    public typealias FailureInfo = RetryFailureInfo<T>

    let retry: RetryIterator<T>

    public init<PayloadIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, iterator base: PayloadIterator, retry block: @escaping Handler) where PayloadIterator: IteratorProtocol, PayloadIterator.Element == Payload {
        retry = RetryIterator(handler: block, iterator: base)
        super.init(dispatchQueue: dispatchQueue, max: max, iterator: retry)
    }

    public init<OperationIterator, DelayIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, delay: DelayIterator, iterator base: OperationIterator, retry block: @escaping Handler) where OperationIterator: IteratorProtocol, DelayIterator: IteratorProtocol, OperationIterator.Element == T, DelayIterator.Element == Delay {
        let payloadIterator = MapIterator(PairIterator(primary: base, secondary: delay)) { Payload(operation: $0.0, delay: $0.1) }
        retry = RetryIterator(handler: block, iterator: payloadIterator)
        super.init(dispatchQueue: dispatchQueue, max: max, iterator: retry)
    }

    public init<OperationIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, wait: WaitStrategy, iterator base: OperationIterator, retry block: @escaping Handler) where OperationIterator: IteratorProtocol, OperationIterator.Element == T {
        let payloadIterator = MapIterator(PairIterator(primary: base, secondary: Delay.iterator(wait.iterator))) { Payload(operation: $0.0, delay: $0.1) }
        retry = RetryIterator(handler: block, iterator: payloadIterator)
        super.init(dispatchQueue: dispatchQueue, max: max, iterator: retry)
    }

    open override func childWillFinishWithoutErrors(_ child: Operation) {
        // no-op
        // To ensure that we do not retry/repeat successful procedures
    }

    open override func child(_ child: Operation, willAttemptRecoveryFromErrors errors: [Error]) -> Bool {
        eventQueue.debugAssertIsOnQueue()
        guard child === current else { return false }
        var returnValue = false
        defer {
            let message = returnValue ? "will attempt" : "will not attempt"
            log.notice(message: "\(message) recovery from errors: \(errors) in operation: \(child)")
        }
        retry.info = createFailureInfo(for: current, errors: errors)
        returnValue = _addNextOperation()
        retry.info = .none
        return returnValue
    }

    open override func child(_ child: Operation, didAttemptRecoveryFromErrors errors: [Error]) {
        eventQueue.debugAssertIsOnQueue()
        if let previous = previous, child === current {
            childDidNotRecoverFromErrors(previous)
        }
        super.child(child, didAttemptRecoveryFromErrors: errors)
    }

    open override func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, withErrors errors: [Error]) -> ProcedureFuture? {
        if errors.isEmpty, let previous = previous, procedure === current {
            childDidRecoverFromErrors(previous)
        }
        return super.procedureQueue(queue, willFinishProcedure: procedure, withErrors: errors)
    }

    internal func createFailureInfo(for operation: T, errors: [Error]) -> FailureInfo {
        return FailureInfo(
            operation: operation,
            errors: errors,
            historicalErrors: attemptedRecoveryErrors,
            count: count,
            addOperations: { self.add(children: $0, before: nil); return },
            log: log,
            configure: configure
        )
    }
}
