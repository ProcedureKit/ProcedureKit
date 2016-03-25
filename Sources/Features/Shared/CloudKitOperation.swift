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

public class OPRCKOperation<T where T: NSOperation, T: CKOperationType>: ReachableOperation<T> {

    override init(_ operation: T, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        super.init(operation, connectivity: connectivity)
        name = "OPRCKOperation<\(T.self)>"
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery<T where T: NSOperation, T: CKOperationType> {
    public typealias V = OPRCKOperation<T>

    public typealias ErrorResponse = (delay: Delay?, configure: V -> Void)
    public typealias Handler = (error: NSError, log: LoggerType, suggested: ErrorResponse) -> ErrorResponse?

    typealias Payload = (Delay?, V)

    var defaultHandlers: [CKErrorCode: Handler]
    var customHandlers: [CKErrorCode: Handler]

    init() {
        defaultHandlers = [:]
        customHandlers = [:]
        addDefaultHandlers()
    }

    internal func recoverWithInfo(info: RetryFailureInfo<V>, payload: Payload) -> ErrorResponse? {

        guard let (code, error) = cloudKitErrorsFromInfo(info) else { return .None }

        // We take the payload, if not nil, and return the delay, and configuration block
        let suggestion: ErrorResponse = (payload.0, info.configure )
        var response: ErrorResponse? = .None

        response = defaultHandlers[code]?(error: error, log: info.log, suggested: suggestion)
        response = customHandlers[code]?(error: error, log: info.log, suggested: response ?? suggestion)

        return response

        // 5. Consider how we might pass the result of the default into the custom
    }

    func addDefaultHandlers() {

        let exit: Handler = { error, log, _ in
            log.fatal("Exiting due to CloudKit Error: \(error)")
            return .None
        }

        let retry: Handler = { error, log, suggestion in
            if let interval = (error.userInfo[CKErrorRetryAfterKey] as? NSNumber).map({ $0.doubleValue }) {
                return (Delay.By(interval), suggestion.configure)
            }
            return suggestion
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

    internal func cloudKitErrorsFromInfo(info: RetryFailureInfo<OPRCKOperation<T>>) -> (code: CKErrorCode, error: NSError)? {
        let mapped: [(CKErrorCode, NSError)] = info.errors.flatMap { error in
            let error = error as NSError
            if error.domain == CKErrorDomain, let code = CKErrorCode(rawValue: error.code) {
                return (code, error)
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
public final class CloudKitOperation<T where T: NSOperation, T: CKOperationType>: RetryOperation<OPRCKOperation<T>> {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    let recovery: CloudKitRecovery<T>

    var operation: T {
        return current.operation
    }

    public convenience init(_ body: () -> T?) {
        self.init(generator: AnyGenerator(body: body), connectivity: .AnyConnectionKind, reachability: ReachabilityManager(DeviceReachability()))
    }

    convenience init(connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, _ body: () -> T?) {
        self.init(generator: AnyGenerator(body: body), connectivity: .AnyConnectionKind, reachability: reachability)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {

        // Creates a standard random delay between retries
        let strategy: WaitStrategy = .Random((0.1, 1.0))
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }

        // Maps the generator to wrap the target operation.
        let generator = MapGenerator(gen) { operation -> OPRCKOperation<T> in
            let op = OPRCKOperation(operation, connectivity: connectivity)
            op.reachability = reachability
            return op
        }

        // Creates a CloudKitRecovery object
        let _recovery = CloudKitRecovery<T>()

        // Creates a Retry Handler using the recovery object
        let handler: Handler = { info, payload in
            guard let (delay, configure) = _recovery.recoverWithInfo(info, payload: payload) else { return .None }
            let (_, operation) = payload
            configure(operation)
            return (delay, operation)
        }

        recovery = _recovery
        super.init(delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }

    public func setErrorHandlerForCode(code: CKErrorCode, handler: ErrorHandler) {
        recovery.setCustomHandlerForCode(code, handler: handler)
    }

    override func childOperation(child: NSOperation, didFinishWithErrors errors: [ErrorType]) {
        if !(child is OPRCKOperation<T>) {
            super.childOperation(child, didFinishWithErrors: errors)
        }
    }
}

// MARK: - BatchedCloudKitOperation

class CloudKitOperationGenerator<T where T: NSOperation, T: CKOperationType>: GeneratorType {

    let connectivity: Reachability.Connectivity
    let reachability: SystemReachabilityType

    var generator: AnyGenerator<T>
    var more: Bool = true

    init<G where G: GeneratorType, G.Element == T>(generator: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        self.generator = AnyGenerator(generator)
        self.connectivity = connectivity
        self.reachability = reachability
    }

    func next() -> CloudKitOperation<T>? {
        guard more else { return .None }
        return CloudKitOperation(generator: generator, connectivity: connectivity, reachability: reachability)
    }
}

public class BatchedCloudKitOperation<T where T: NSOperation, T: CKBatchedOperationType>: RepeatedOperation<CloudKitOperation<T>> {

    public var enableBatchProcessing: Bool
    var generator: CloudKitOperationGenerator<T>

    public var operation: T {
        return current.operation
    }

    public convenience init(enableBatchProcessing enable: Bool = true, _ body: () -> T?) {
        self.init(generator: AnyGenerator(body: body), enableBatchProcessing: enable, connectivity: .AnyConnectionKind, reachability: ReachabilityManager(DeviceReachability()))
    }

    convenience init(enableBatchProcessing enable: Bool = true, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, _ body: () -> T?) {
        self.init(generator: AnyGenerator(body: body), enableBatchProcessing: enable, connectivity: connectivity, reachability: reachability)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, enableBatchProcessing enable: Bool = true, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        enableBatchProcessing = enable
        generator = CloudKitOperationGenerator(generator: gen, connectivity: connectivity, reachability: reachability)

        // Creates a standard fixed delay between batches (not reties)
        let strategy: WaitStrategy = .Fixed(0.1)
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }
        let tuple = TupleGenerator(primary: generator, secondary: delay)

        super.init(generator: AnyGenerator(tuple))
    }

    public override func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let cloudKitOperation = operation as? CloudKitOperation<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
        }
        super.willFinishOperation(operation, withErrors: errors)
    }
}
