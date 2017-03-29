//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import Dispatch
import CloudKit

/**
 CKProcedure is a simple wrapper to compose `CKOperation` instances inside a procedure.
 */
public final class CKProcedure<T: Operation>: ComposedProcedure<T> where T: CKOperationProtocol {

    init(dispatchQueue: DispatchQueue? = nil, timeout: TimeInterval? = 30, operation: T) {
        super.init(dispatchQueue: dispatchQueue, operation: operation)
        log.enabled = false
        if let observer = timeout.map({ TimeoutObserver(by: $0) }) {
            add(observer: observer)
        }
    }
}

// MARK: - CloudKitRecovery

public final class CloudKitRecovery<T: Operation> where T: CKOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public typealias WrappedOperation = CKProcedure<T>
    public typealias ConfigureBlock = (WrappedOperation) -> Void
    public typealias Recovery = (Delay?, ConfigureBlock)
    public typealias Payload = RepeatProcedurePayload<WrappedOperation>
    public typealias Handler = (T, T.AssociatedError, LoggerProtocol, Recovery) -> Recovery?

    var defaultHandlers: [CKError.Code: Handler] = [:]
    var customHandlers: [CKError.Code: Handler] = [:]
    private var finallyConfigureRetryOperationBlock: ConfigureBlock?

    internal init() {
        addDefaultHandlers()
    }

    func cloudKitErrors(fromInfo info: RetryFailureInfo<WrappedOperation>) -> (CKError.Code, T.AssociatedError)? {
        let mapped: [(CKError.Code, T.AssociatedError)] = info.errors.flatMap { error in
            guard
                let cloudKitError = error as? T.AssociatedError,
                let code = cloudKitError.code
            else { return nil }
            return (code, cloudKitError)
        }
        return mapped.first
    }

    func recover(withInfo info: RetryFailureInfo<WrappedOperation>, payload: Payload) -> Recovery? {
        guard let (code, error) = cloudKitErrors(fromInfo: info) else { return nil }

        let suggestion: Recovery = (payload.delay, info.configure)

        guard
            let handler = customHandlers[code] ?? defaultHandlers[code],
            var response = handler(info.operation.operation, error, info.log, suggestion)
        else { return nil }

        if let finallyConfigureBlock = finallyConfigureRetryOperationBlock {
            let previousConfigureBlock = response.1
            response.1 = { operation in
                previousConfigureBlock(operation)
                finallyConfigureBlock(operation)
            }
        }

        return response
    }

    func addDefaultHandlers() {

        let exit: Handler = { _, error, log, _ in
            log.fatal(message: "Exiting due to CloudKit Error: \(error)")
            return nil
        }

        set(defaultHandlerForCode: .internalError, handler: exit)
        set(defaultHandlerForCode: .missingEntitlement, handler: exit)
        set(defaultHandlerForCode: .invalidArguments, handler: exit)
        set(defaultHandlerForCode: .serverRejectedRequest, handler: exit)
        set(defaultHandlerForCode: .assetFileNotFound, handler: exit)
        set(defaultHandlerForCode: .incompatibleVersion, handler: exit)
        set(defaultHandlerForCode: .constraintViolation, handler: exit)
        set(defaultHandlerForCode: .badDatabase, handler: exit)
        set(defaultHandlerForCode: .quotaExceeded, handler: exit)
        set(defaultHandlerForCode: .operationCancelled, handler: exit)

        let retry: Handler = { _, error, log, suggestion in
            log.info(message: "Will retry after receiving error: \(error)")
            return error.retryAfterDelay.map { ($0, suggestion.1) } ?? suggestion
        }

        set(defaultHandlerForCode: .networkUnavailable, handler: retry)
        set(defaultHandlerForCode: .networkFailure, handler: retry)
        set(defaultHandlerForCode: .serviceUnavailable, handler: retry)
        set(defaultHandlerForCode: .requestRateLimited, handler: retry)
        set(defaultHandlerForCode: .assetFileModified, handler: retry)
        set(defaultHandlerForCode: .batchRequestFailed, handler: retry)
        set(defaultHandlerForCode: .zoneBusy, handler: retry)
    }

    func set(defaultHandlerForCode code: CKError.Code, handler: @escaping Handler) {
        defaultHandlers[code] = handler
    }

    func set(customHandlerForCode code: CKError.Code, handler: @escaping Handler) {
        customHandlers[code] = handler
    }

    func set(finallyConfigureRetryOperationBlock block: ConfigureBlock?) {
        finallyConfigureRetryOperationBlock = block
    }
}

// MARK: - CloudKitProcedure

/**
 # CloudKitProcedure

 CloudKitProcedure is a generic operation which can be used to configure and schedule
 the execution of Apple's CKOperation subclasses.

 ## Generics

 CloudKitProcedure is generic over the type of the CKOperation. See Apple's documentation
 on their CloudKit NSOperation classes.

 ## Initialization

 CloudKitProcedure is initialized with a block which should return an instance of the
 required operation. Note that some CKOperation subclasses have static methods to
 return standard instances. Given Swift's treatment of trailing closure arguments, this
 means that the following is a standard initialization pattern:

 ```swift
 let operation = CloudKitProcedure { CKFetchRecordZonesOperation.fetchAllRecordZonesOperation() }
 ```

 This works because, the initializer only takes a trailing closure. The closure receives no arguments
 and is only one line, so the return is not needed.

 ## Configuration

 Most CKOperation subclasses need various properties setting before they are added to a queue. Sometimes
 these can be done via their initializers. However, it is also possible to set the properties directly.
 This can be done directly onto the CloudKitProcedure. For example, given the above:

 ```swift
 let container = CKContainer.defaultContainer()
 operation.container = container
 operation.database = container.privateCloudDatabase
 ```

 This will set the container and the database through the CloudKitProcedure into the wrapped CKOperation
 instance.

 ## Completion

 All CKOperation subclasses have a completion block which should be set. This completion block receives
 the "results" of the operation, and an `NSError` argument. However, CloudKitProcedure features its own
 semi-automatic error handling system. Therefore, the only completion block needed is one which receives
 the "results". Essentially, all that is needed is to manage the happy path of the operation. For all
 CKOperation subclasses, this can be configured directly on the CloudKitProcedure instance, using a
 pattern of `setOperationKindCompletionBlock { }`. For example, given the above:

 ```swift
 operation.setFetchRecordZonesCompletionBlock { zonesByID in
 // Do something with the zonesByID
 }
 ```

 Note, that for the automatic error handling to kick in, the happy path must be set (as above).

 ### Error Handling

 When the completion block is set as above, any errors receives from the CKOperation subclass are
 intercepted, and instead of the provided block being executed, the operation finsihes with an error.

 However, CloudKitProcedure is a subclass of RetryOperation, which is actually a GroupOperation subclass,
 and when a child operation finishes with an error, RetryOperation will consult its error handler, and
 attempt to retry the operation.

 In the case of CloudKitProcedure, the error handler, which is configured internally has automatic
 support for many common error kinds. When the CKOperation receives an error, the CKErrorCode is extracted,
 and the handler consults a CloudKitRecovery instance to check for a particular way to handle that error
 code. In some cases, this will result in a tuple being returned. The tuple is an optional Delay, and
 a new instance of the CKOperation class.

 This is why the initializer takes a block which returns an instance of the CKOperation subclass, rather
 than just an instance directly. In addition, any configuration set on the operation is captured and
 applied again to new instances of the CKOperation subclass.

 The delay is used to automatically respect any wait periods returned in the CloudKit NSError object. If
 none are given, a random time delay between 0.1 and 1.0 seconds is used.

 If the error recovery does not have a handler, or the handler returns nil (no tuple), the CloudKitProcedure
 will finish (with the errors).

 ### Custom Error Handling

 To provide bespoke error handling, further configure the CloudKitProcedure by calling setErrorHandlerForCode.
 For example:

 ```swift
 operation.setErrorHandlerForCode(.PartialFailure) { error, log, suggested in
 return suggested
 }
 ```

 Note that the error handler receives the received error, a logger object, and the suggested tuple, which
 could be modified before being returned. Alternatively, return nil to not retry.

 */
public final class CloudKitProcedure<T: Operation>: RetryProcedure<CKProcedure<T>> where T: CKOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    let recovery: CloudKitRecovery<T>

    public var errorHandlers: [CKError.Code: ErrorHandler] {
        return recovery.customHandlers
    }

    public init<Iterator: IteratorProtocol>(dispatchQueue: DispatchQueue, timeout: TimeInterval?, strategy: WaitStrategy, iterator: Iterator) where T == Iterator.Element {

        // Create a delay between retries
        let delayIterator = Delay.iterator(strategy.iterator)

        let operationIterator = MapIterator(iterator) { CKProcedure(dispatchQueue: dispatchQueue, timeout: timeout, operation: $0) }

        let recovery = CloudKitRecovery<T>()

        let handler: Handler = { [weak recovery] info, payload in
            guard
                let recovery = recovery,
                let (delay, configure) = recovery.recover(withInfo: info, payload: payload)
            else { return nil }
            return RepeatProcedurePayload(operation: payload.operation, delay: delay, configure: configure)
        }

        self.recovery = recovery

        super.init(dispatchQueue: dispatchQueue, delay: delayIterator, iterator: operationIterator, retry: handler)
    }

    public convenience init(dispatchQueue: DispatchQueue = DispatchQueue.default, timeout: TimeInterval? = 30, strategy: WaitStrategy = .random(minimum: 0.1, maximum: 1.0), body: @escaping () -> T?) {
        self.init(dispatchQueue: dispatchQueue, timeout: timeout, strategy: strategy, iterator: AnyIterator(body))
    }

    public func set(errorHandlerForCode code: CKError.Code, handler: @escaping ErrorHandler) {
        recovery.set(customHandlerForCode: code, handler: handler)
    }

    public func set(errorHandlers: [CKError.Code: ErrorHandler]) {
        recovery.customHandlers = errorHandlers
    }

    // When an error occurs, CloudKitProcedure executes the appropriate error handler (as long as the completion block is set).
    // (By default, certain errors are automatically handled with a retry attempt, such as common network errors.)
    //
    // If the error handler specifies that the operation should retry, it also specifies a configuration block for the operation.
    // After the configuration block returned by the error handler configures the operation, the finallyConfigureRetryOperationBlock
    // will be passed the new ("retry") operation so it can further modify its properties.
    //
    // For example:
    //      - CKFetchDatabaseChangesOperation, for updating:
    //          - `previousServerChangeToken`
    //              - with the last changeToken received by the changeTokenUpdatedBlock prior to the error
    //                (assuming you have persisted the information received prior to the last changeToken update)
    //
    //      - CKFetchRecordZoneChangesOperation, for updating:
    //          - `recordZoneIDs`
    //              - to remove zones that were completely fetched prior to the error
    //                (assuming you have persisted the fetched data)
    //          - `optionsByRecordZoneID`
    //              - to update the previousServerChangeToken for zones that were partially fetched prior to the error
    //                (assuming you have persisted the successfully-fetched data)
    //
    public func set(finallyConfigureRetryOperationBlock block: CloudKitRecovery<T>.ConfigureBlock?) {
        recovery.set(finallyConfigureRetryOperationBlock: block)
    }
}
