//
//  CloudKitOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - OPRCKOperation

public class OPRCKOperation<T where T: NSOperation, T: CKOperationType>: ComposedOperation<T> {

    init(operation composed: T, timeout: NSTimeInterval? = 300) {
        super.init(operation: composed)
        name = "OPRCKOperation<\(T.self)>"
        if let observer = timeout.map({ TimeoutObserver(timeout: $0) }) {
            addObserver(observer)
        }
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery<T where T: NSOperation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType> {
    public typealias V = OPRCKOperation<T>

    public typealias ConfigureOperationBlock = V -> Void
    public typealias ErrorResponse = (delay: Delay?, configure: ConfigureOperationBlock)
    public typealias Handler = (operation: T, error: T.Error, log: LoggerType, suggested: ErrorResponse) -> ErrorResponse?

    typealias Payload = RepeatedPayload<V>

    var defaultHandlers: [CKErrorCode: Handler]
    var customHandlers: [CKErrorCode: Handler]
    private var finallyConfigureRetryOperationBlock: ConfigureOperationBlock?

    init() {
        defaultHandlers = [:]
        customHandlers = [:]
        addDefaultHandlers()
    }

    internal func recoverWithInfo(info: RetryFailureInfo<V>, payload: Payload) -> ErrorResponse? {
        guard let (code, error) = cloudKitErrorsFromInfo(info) else { return .None }

        // We take the payload, if not nil, and return the delay, and configuration block
        let suggestion: ErrorResponse = (payload.delay, info.configure)

        guard let handler = customHandlers[code] ?? defaultHandlers[code],
              var response = handler(operation: info.operation.operation, error: error, log: info.log, suggested: suggestion)
        else {
            return .None
        }

        // The error handler responded with a suggested delay and configuration block.
        // If a finallyConfigureRetryOperationBlock is specified, add it to the configuration block.
        if let finallyConfigureRetryOperationBlock = finallyConfigureRetryOperationBlock {
            let config = response.configure
            response.configure = { operation in
                config(operation)
                finallyConfigureRetryOperationBlock(operation)
            }
        }

        return response
    }

    func addDefaultHandlers() {

        let exit: Handler = { _, error, log, _ in
            log.fatal("Exiting due to CloudKit Error: \(error)")
            return .None
        }

        setDefaultHandlerForCode(.InternalError, handler: exit)
        setDefaultHandlerForCode(.MissingEntitlement, handler: exit)
        setDefaultHandlerForCode(.InvalidArguments, handler: exit)
        setDefaultHandlerForCode(.ServerRejectedRequest, handler: exit)
        setDefaultHandlerForCode(.AssetFileNotFound, handler: exit)
        setDefaultHandlerForCode(.IncompatibleVersion, handler: exit)
        setDefaultHandlerForCode(.ConstraintViolation, handler: exit)
        setDefaultHandlerForCode(.BadDatabase, handler: exit)
        setDefaultHandlerForCode(.QuotaExceeded, handler: exit)
        setDefaultHandlerForCode(.OperationCancelled, handler: exit)

        let retry: Handler = { _, error, log, suggestion in
            return error.retryAfterDelay.map { ($0, suggestion.configure) } ?? suggestion
        }

        setDefaultHandlerForCode(.NetworkUnavailable, handler: retry)
        setDefaultHandlerForCode(.NetworkFailure, handler: retry)
        setDefaultHandlerForCode(.ServiceUnavailable, handler: retry)
        setDefaultHandlerForCode(.RequestRateLimited, handler: retry)
        setDefaultHandlerForCode(.AssetFileModified, handler: retry)
        setDefaultHandlerForCode(.BatchRequestFailed, handler: retry)
        setDefaultHandlerForCode(.ZoneBusy, handler: retry)
    }

    func setDefaultHandlerForCode(code: CKErrorCode, handler: Handler) {
        defaultHandlers.updateValue(handler, forKey: code)
    }

    func setCustomHandlerForCode(code: CKErrorCode, handler: Handler) {
        customHandlers.updateValue(handler, forKey: code)
    }

    func setFinallyConfigureRetryOperationBlock(block: ConfigureOperationBlock?) {
        finallyConfigureRetryOperationBlock = block
    }

    internal func cloudKitErrorsFromInfo(info: RetryFailureInfo<OPRCKOperation<T>>) -> (code: CKErrorCode, error: T.Error)? {
        let mapped: [(CKErrorCode, T.Error)] = info.errors.flatMap { error in
            if let cloudKitError = error as? T.Error, code = cloudKitError.code {
                return (code, cloudKitError)
            }
            return .None
        }
        return mapped.first
    }
}

// MARK: - CloudKitOperation

/**
 # CloudKitOperation

 CloudKitOperation is a generic operation which can be used to configure and schedule
 the execution of Apple's CKOperation subclasses.

 ## Generics

 CloudKitOperation is generic over the type of the CKOperation. See Apple's documentation
 on their CloudKit NSOperation classes.

 ## Initialization

 CloudKitOperation is initialized with a block which should return an instance of the
 required operation. Note that some CKOperation subclasses have static methods to
 return standard instances. Given Swift's treatment of trailing closure arguments, this
 means that the following is a standard initialization pattern:

 ```swift
 let operation = CloudKitOperation { CKFetchRecordZonesOperation.fetchAllRecordZonesOperation() }
 ```

 This works because, the initializer only takes a trailing closure. The closure receives no arguments
 and is only one line, so the return is not needed.

 ## Configuration

 Most CKOperation subclasses need various properties setting before they are added to a queue. Sometimes
 these can be done via their initializers. However, it is also possible to set the properties directly.
 This can be done directly onto the CloudKitOperation. For example, given the above:

 ```swift
 let container = CKContainer.defaultContainer()
 operation.container = container
 operation.database = container.privateCloudDatabase
 ```

 This will set the container and the database through the CloudKitOperation into the wrapped CKOperation
 instance.

 ## Completion

 All CKOperation subclasses have a completion block which should be set. This completion block receives
 the "results" of the operation, and an `NSError` argument. However, CloudKitOperation features its own
 semi-automatic error handling system. Therefore, the only completion block needed is one which receives
 the "results". Essentially, all that is needed is to manage the happy path of the operation. For all
 CKOperation subclasses, this can be configured directly on the CloudKitOperation instance, using a
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

 However, CloudKitOperation is a subclass of RetryOperation, which is actually a GroupOperation subclass,
 and when a child operation finishes with an error, RetryOperation will consult its error handler, and
 attempt to retry the operation.

 In the case of CloudKitOperation, the error handler, which is configured internally has automatic
 support for many common error kinds. When the CKOperation receives an error, the CKErrorCode is extracted,
 and the handler consults a CloudKitRecovery instance to check for a particular way to handle that error
 code. In some cases, this will result in a tuple being returned. The tuple is an optional Delay, and
 a new instance of the CKOperation class.

 This is why the initializer takes a block which returns an instance of the CKOperation subclass, rather
 than just an instance directly. In addition, any configuration set on the operation is captured and
 applied again to new instances of the CKOperation subclass.

 The delay is used to automatically respect any wait periods returned in the CloudKit NSError object. If
 none are given, a random time delay between 0.1 and 1.0 seconds is used.

 If the error recovery does not have a handler, or the handler returns nil (no tuple), the CloudKitOperation
 will finish (with the errors).

 ### Custom Error Handling

 To provide bespoke error handling, further configure the CloudKitOperation by calling setErrorHandlerForCode.
 For example:

 ```swift
 operation.setErrorHandlerForCode(.PartialFailure) { error, log, suggested in
    return suggested
 }
 ```

 Note that the error handler receives the received error, a logger object, and the suggested tuple, which
 could be modified before being returned. Alternatively, return nil to not retry.

*/
public final class CloudKitOperation<T where T: NSOperation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: RetryOperation<OPRCKOperation<T>> {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    internal var recovery: CloudKitRecovery<T>

    internal var operation: T {
        return current.operation
    }

    public var errorHandlers: [CKErrorCode: ErrorHandler] {
        return recovery.customHandlers
    }

    public convenience init(timeout: NSTimeInterval? = 300, strategy: WaitStrategy = .Random((0.1, 1.0)), _ body: () -> T?) {
        self.init(timeout: timeout, strategy: strategy, generator: AnyGenerator(body: body))
    }

    init<G where G: GeneratorType, G.Element == T>(timeout: NSTimeInterval? = 300, strategy: WaitStrategy = .Random((0.1, 1.0)), generator gen: G) {

        // Creates a delay between retries
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }

        // Maps the generator to wrap the target operation.
        let generator = MapGenerator(gen) { operation -> OPRCKOperation<T> in
            return OPRCKOperation(operation: operation, timeout: timeout)
        }

        // Creates a CloudKitRecovery object
        let _recovery = CloudKitRecovery<T>()

        // Creates a Retry Handler using the recovery object
        let handler: Handler = { [weak _recovery] info, payload in
            guard let recovery = _recovery, (delay, configure) = recovery.recoverWithInfo(info, payload: payload) else { return .None }
            return RepeatedPayload(delay: delay, operation: payload.operation, configure: configure)
        }

        recovery = _recovery
        super.init(delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }

    public func setErrorHandlerForCode(code: CKErrorCode, handler: ErrorHandler) {
        recovery.setCustomHandlerForCode(code, handler: handler)
    }

    public func setErrorHandlers(handlers: [CKErrorCode: ErrorHandler]) {
        recovery.customHandlers = handlers
    }

    // When an error occurs, CloudKitOperation executes the appropriate error handler (as long as the completion block is set).
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
    public func setFinallyConfigureRetryOperationBlock(block: (retryOperation: OPRCKOperation<T>) -> Void) {
        recovery.setFinallyConfigureRetryOperationBlock(block)
    }
}

// MARK: - BatchedCloudKitOperation

class CloudKitOperationGenerator<T where T: NSOperation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: GeneratorType {

    typealias ConfigureBlock = CloudKitOperation<T> -> Void

    let recovery: CloudKitRecovery<T>

    var timeout: NSTimeInterval?
    var generator: AnyGenerator<T>
    var more: Bool = true

    var configureNextOperationBlock: ConfigureBlock?
    var lastOperationConfigure: ConfigureBlock = { _ in }

    init<G where G: GeneratorType, G.Element == T>(timeout: NSTimeInterval? = 300, generator: G) {
        self.timeout = timeout
        self.generator = AnyGenerator(generator)
        self.recovery = CloudKitRecovery<T>()
    }

    func next() -> CloudKitOperation<T>? {
        guard more else { return .None }
        let operation = CloudKitOperation(timeout: timeout, generator: generator)
        operation.recovery = recovery
        return operation
    }

    func setConfigureNextOperationBlock(block: ConfigureBlock?) {
        configureNextOperationBlock = block
    }
}

/**
 # BatchedCloudKitOperation

 BatchedCloudKitOperation is a generic operation which can be used to configure and schedule
 the execution of a batch of an Apple CKOperation subclass that returns "moreComing".

 Internally, BatchedCloudKitOperation composes CloudKitOperations. Its job is to repeat
 instances of CloudKitOperation while moreComing == true.

 ## Initialization

 BatchedCloudKitOperation is initialized just like CloudKitOperation.

 For supported CKOperations, it is possible to swap CloudKitOperation for BatchedCloudKitOperation:

 ```swift
 // this:
 let operation = CloudKitOperation { CKFetchRecordChangesOperation() }
 // becomes:
 let operation = BatchedCloudKitOperation { CKFetchRecordChangesOperation() }
 ```

 ## Configuration

 Most CKOperation subclasses need various properties setting before they are added to a queue. Sometimes
 these can be done via their initializers. However, it is also possible to set the properties directly.
 This can be done directly onto the BatchedCloudKitOperation, just like CloudKitOperation.

 For example, given the above:

 ```swift
 let container = CKContainer.defaultContainer()
 operation.container = container
 operation.database = container.privateCloudDatabase
 ```

 This will set the container and the database through the BatchedCloudKitOperation into each underlying
 CloudKitOperation-wrapped CKOperation instance in the batch.

 ### Configuring Follow-Up Operations in the Batch

 For most batched CKOperations, you will want/need to change some state for the "next" operation.
 You can do this using setConfigureNextOperationBlock().

 For example, given the above:

 ```swift
 operation.setConfigureNextOperationBlock { nextOperation in
    // the next operation must receive an updated serverChangeToken from the last operation
    nextOperation.previousServerChangeToken = lastServerChangeToken
 }
 ```

 where `lastServerChangeToken` is the serverChangeToken most recently received by the operation's
 `fetchRecordChangesCompletionBlock`. (See the following section on completion.)

 ## Completion

 Since BatchedCloudKitOperation composes CloudKitOperations, you must follow the same guidelines from
 CloudKitOperation to always set the completion block.

 For example, given the above:

 ```swift
 operation.setFetchRecordChangesCompletionBlock { serverChangeToken, clientChangeTokenData in
 // Do something, such as storing the new serverChangeToken
 }
 ```

 For CloudKitOperation's automatic error handling to kick in, the happy path must be set (as above).

 **IMPORTANT:**

 Because BatchedCloudKitOperation composes CloudKitOperations, your completion handler **may be called
 multiple times** (i.e. once for each underlying CloudKitOperation that is completed in the batch).

 Therefore, you MUST ensure that your completion handler does not make assumptions about the completion
 status of the BatchedCloudKitOperation.

 If you need to handle the completion of the BatchedCloudKitOperation itself, use a Will/DidFinishObserver.

 ### Error Handling

 See the documentation for CloudKitOperation Error Handling.

 BatchedCloudKitOperation provides a convenience setErrorHandlerForCode method, which sets the error
 handling for every CloudKitOperation in the batch.

 */
public class BatchedCloudKitOperation<T where T: NSOperation, T: CKBatchedOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: RepeatedOperation<CloudKitOperation<T>> {

    typealias PayLoad = RepeatedPayload<CloudKitOperation<T>>
    typealias ConfigurationHandler = (CloudKitOperation<T>) -> PayLoad.ConfigureBlock?

    public var enableBatchProcessing: Bool
    var generator: CloudKitOperationGenerator<T>

    public var operation: T {
        return current.operation
    }

    public convenience init(enableBatchProcessing enable: Bool = true, _ body: () -> T?) {
        self.init(generator: AnyGenerator(body: body), enableBatchProcessing: enable)
    }

    init<G where G: GeneratorType, G.Element == T>(timeout: NSTimeInterval? = 300, generator gen: G, enableBatchProcessing enable: Bool = true) {

        enableBatchProcessing = enable

        // Creates a CloudKitOperationGenerator object
        let _generator = CloudKitOperationGenerator(timeout: timeout, generator: gen)

        // Creates a Configuration Handler for next operations using the CloudKitOperationGenerator
        let newConfigurationHandler: ConfigurationHandler = { [unowned _generator] (nextOperation) -> PayLoad.ConfigureBlock? in
            guard let configureNextOperationBlock = _generator.configureNextOperationBlock else {
                return .None
            }

            let lastOperationConfigure: PayLoad.ConfigureBlock = _generator.lastOperationConfigure
            let configure: PayLoad.ConfigureBlock = { operation in
                lastOperationConfigure(operation)
                configureNextOperationBlock(operation)
            }
            return configure
        }

        generator = _generator

        // Creates a standard fixed delay between batches (not reties)
        let strategy: WaitStrategy = .Fixed(0.1)
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }
        let tuple = TupleGenerator(primary: generator, secondary: delay)
        let mapped = MapGenerator(tuple) { RepeatedPayload(delay: $0.0, operation: $0.1, configure: newConfigurationHandler($0.1)) }
        super.init(generator: AnyGenerator(mapped))
    }

    public override func willFinishOperation(operation: NSOperation) {
        if let cloudKitOperation = operation as? CloudKitOperation<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
            generator.lastOperationConfigure = configure
        }
        super.willFinishOperation(operation)
    }

    public func setErrorHandlerForCode(code: CKErrorCode, handler: CloudKitOperation<T>.ErrorHandler) {
        generator.recovery.setCustomHandlerForCode(code, handler: handler)
    }

    // Set a block that can configure the next internal CloudKitOperation (i.e. if moreComing == true)
    // The operation passed-into the block will be the next operation, *already configured like the previous operation*.
    // Use this block to make any additional required changes.
    //
    // For example:
    //      - BatchedCloudKitOperation<CKFetchNotificationChangesOperation>, for updating:
    //          - `previousServerChangeToken`
    //              - with the last changeToken received by the fetchNotificationChangesCompletionBlock
    //
    public func setConfigureNextOperationBlock(block: (nextOperation: CloudKitOperation<T>) -> Void) {
        generator.setConfigureNextOperationBlock(block)
    }
}
