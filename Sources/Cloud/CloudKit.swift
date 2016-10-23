//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/**
 CKProcedure is a simple wrapper to compose `CKOperation` instances inside a procedure.
 */
public final class CKProcedure<T: Operation>: ComposedProcedure<T> where T: CKOperationProtocol {

    init(dispatchQueue: DispatchQueue? = nil, timeout: TimeInterval? = 30, operation: T) {
        super.init(dispatchQueue: dispatchQueue, operation: operation)
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

    internal init() {

    }

    func recover(withInfo info: RetryFailureInfo<WrappedOperation>, payload: Payload) -> Recovery? {
        return nil
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

    let recovery: CloudKitRecovery<T>

    init<Iterator: IteratorProtocol>(dispatchQueue: DispatchQueue = DispatchQueue.default, timeout: TimeInterval? = 30, strategy: WaitStrategy, iterator: Iterator) where T == Iterator.Element {

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
}
