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

public class OPRCKOperation<T where T: Operation, T: CKOperationType>: ComposedOperation<T> {

    init(operation composed: T, timeout: TimeInterval? = 300) {
        super.init(operation: composed)
        name = "OPRCKOperation<\(T.self)>"
        if let observer = timeout.map({ TimeoutObserver(timeout: $0) }) {
            addObserver(observer)
        }
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery<T where T: Operation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType> {
    public typealias V = OPRCKOperation<T>

    public typealias ErrorResponse = (delay: Delay?, configure: (V) -> Void)
    public typealias Handler = (error: T.Error, log: LoggerType, suggested: ErrorResponse) -> ErrorResponse?

    typealias Payload = (Delay?, V)

    var defaultHandlers: [CKErrorCode: Handler]
    var customHandlers: [CKErrorCode: Handler]

    init() {
        defaultHandlers = [:]
        customHandlers = [:]
        addDefaultHandlers()
    }

    internal func recoverWithInfo(_ info: RetryFailureInfo<V>, payload: Payload) -> ErrorResponse? {

        guard let (code, error) = cloudKitErrorsFromInfo(info) else { return .none }

        // We take the payload, if not nil, and return the delay, and configuration block
        let suggestion: ErrorResponse = (payload.0, info.configure )
        var response: ErrorResponse? = .none

        response = defaultHandlers[code]?(error: error, log: info.log, suggested: suggestion)
        response = customHandlers[code]?(error: error, log: info.log, suggested: response ?? suggestion)

        return response

        // 5. Consider how we might pass the result of the default into the custom
    }

    func addDefaultHandlers() {

        let exit: Handler = { error, log, _ in
            log.fatal("Exiting due to CloudKit Error: \(error)")
            return .none
        }

        setDefaultHandlerForCode(.internalError, handler: exit)
        setDefaultHandlerForCode(.missingEntitlement, handler: exit)
        setDefaultHandlerForCode(.invalidArguments, handler: exit)
        setDefaultHandlerForCode(.serverRejectedRequest, handler: exit)
        setDefaultHandlerForCode(.assetFileNotFound, handler: exit)
        setDefaultHandlerForCode(.incompatibleVersion, handler: exit)
        setDefaultHandlerForCode(.constraintViolation, handler: exit)
        setDefaultHandlerForCode(.badDatabase, handler: exit)
        setDefaultHandlerForCode(.quotaExceeded, handler: exit)
        setDefaultHandlerForCode(.operationCancelled, handler: exit)

        let retry: Handler = { error, log, suggestion in
            return error.retryAfterDelay.map { ($0, suggestion.configure) } ?? suggestion
        }

        setDefaultHandlerForCode(.networkUnavailable, handler: retry)
        setDefaultHandlerForCode(.networkFailure, handler: retry)
        setDefaultHandlerForCode(.serviceUnavailable, handler: retry)
        setDefaultHandlerForCode(.requestRateLimited, handler: retry)
        setDefaultHandlerForCode(.assetFileModified, handler: retry)
        setDefaultHandlerForCode(.batchRequestFailed, handler: retry)
        setDefaultHandlerForCode(.zoneBusy, handler: retry)
    }

    func setDefaultHandlerForCode(_ code: CKErrorCode, handler: Handler) {
        defaultHandlers.updateValue(handler, forKey: code)
    }

    func setCustomHandlerForCode(_ code: CKErrorCode, handler: Handler) {
        customHandlers.updateValue(handler, forKey: code)
    }

    internal func cloudKitErrorsFromInfo(_ info: RetryFailureInfo<OPRCKOperation<T>>) -> (code: CKErrorCode, error: T.Error)? {
        let mapped: [(CKErrorCode, T.Error)] = info.errors.flatMap { error in
            if let cloudKitError = error as? T.Error, code = cloudKitError.code {
                return (code, cloudKitError)
            }
            return .none
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
public final class CloudKitOperation<T where T: Operation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: RetryOperation<OPRCKOperation<T>> {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    internal var recovery: CloudKitRecovery<T>

    internal var operation: T {
        return current.operation
    }

    public convenience init(_ body: () -> T?) {
        self.init(generator: AnyIterator(body))
    }

    init<G where G: IteratorProtocol, G.Element == T>(timeout: TimeInterval? = 300, generator gen: G) {

        // Creates a standard random delay between retries
        let strategy: WaitStrategy = .random((0.1, 1.0))
        let delay = MapGenerator(strategy.generator()) { Delay.by($0) }

        // Maps the generator to wrap the target operation.
        let generator = MapGenerator(gen) { operation -> OPRCKOperation<T> in
            return OPRCKOperation(operation: operation, timeout: timeout)
        }

        // Creates a CloudKitRecovery object
        let _recovery = CloudKitRecovery<T>()

        // Creates a Retry Handler using the recovery object
        let handler: Handler = { [weak _recovery] info, payload in
            guard let _recovery = _recovery, (delay, configure) = _recovery.recoverWithInfo(info, payload: payload) else { return .none }
            let (_, operation) = payload
            configure(operation)
            return (delay, operation)
        }

        recovery = _recovery
        super.init(delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }

    public func setErrorHandlerForCode(_ code: CKErrorCode, handler: ErrorHandler) {
        recovery.setCustomHandlerForCode(code, handler: handler)
    }

    override func childOperation(_ child: Foundation.Operation, didFinishWithErrors errors: [ErrorProtocol]) {
        if !(child is OPRCKOperation<T>) {
            super.childOperation(child, didFinishWithErrors: errors)
        }
    }
}

// MARK: - BatchedCloudKitOperation

class CloudKitOperationGenerator<T where T: Operation, T: CKOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: IteratorProtocol {

    let recovery: CloudKitRecovery<T>

    var timeout: TimeInterval?
    var generator: AnyIterator<T>
    var more: Bool = true

    init<G where G: IteratorProtocol, G.Element == T>(timeout: TimeInterval? = 300, generator: G) {
        self.timeout = timeout
        self.generator = AnyIterator(generator)
        self.recovery = CloudKitRecovery<T>()
    }

    func next() -> CloudKitOperation<T>? {
        guard more else { return .none }
        let operation = CloudKitOperation(timeout: timeout, generator: generator)
        operation.recovery = recovery
        return operation
    }
}

public class BatchedCloudKitOperation<T where T: Operation, T: CKBatchedOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType>: RepeatedOperation<CloudKitOperation<T>> {

    public var enableBatchProcessing: Bool
    var generator: CloudKitOperationGenerator<T>

    public var operation: T {
        return current.operation
    }

    public convenience init(enableBatchProcessing enable: Bool = true, _ body: () -> T?) {
        self.init(generator: AnyIterator(body), enableBatchProcessing: enable)
    }

    init<G where G: IteratorProtocol, G.Element == T>(timeout: TimeInterval? = 300, generator gen: G, enableBatchProcessing enable: Bool = true) {

        enableBatchProcessing = enable
        generator = CloudKitOperationGenerator(timeout: timeout, generator: gen)

        // Creates a standard fixed delay between batches (not reties)
        let strategy: WaitStrategy = .fixed(0.1)
        let delay = MapGenerator(strategy.generator()) { Delay.by($0) }
        let tuple = TupleGenerator(primary: generator, secondary: delay)

        super.init(generator: AnyIterator(tuple))
    }

    public override func willFinishOperation(_ operation: Foundation.Operation, withErrors errors: [ErrorProtocol]) {
        if errors.isEmpty, let cloudKitOperation = operation as? CloudKitOperation<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
        }
        super.willFinishOperation(operation, withErrors: errors)
    }

    public func setErrorHandlerForCode(_ code: CKErrorCode, handler: CloudKitOperation<T>.ErrorHandler) {
        generator.recovery.setCustomHandlerForCode(code, handler: handler)
    }
}
