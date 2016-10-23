//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public protocol ResilientNetworkBehavior {

    /**
     The number of attempts to make for the
     network request. It represents the total number
     of attempts which should be made.

     - returns: a Int
     */
    var maximumNumberOfAttempts: Int { get }

    /**
     The timeout backoff wait strategy defines the time between
     retry attempts in the event of a network timout.
     Use `.Immediate` to indicate no time between retry attempts.

     - returns: a WaitStrategy
     */
    var timeoutBackoffStrategy: WaitStrategy { get }

    /**
     The error delay is a period to wait in the event of an erroneous
     http response status code.

     - returns: a Delay?
     */
    var errorDelay: Delay? { get }

    /**
     The subsequent attempt timeout defines a time period
     after a failed request during which time another
     request is considered a 2nd request (vs automatic
     retry attempt). After this time, requests are
     considered to be 1st attempts.

     - returns: a NSTimeInterval
     */
    var subsequentAttemptDelay: Delay { get }

    /**
     Some network response status codes should be treated as
     errors.

     - parameter statusCode: an Int
     - returns: a Bool, to indicate that the
     */
    func retryRequest(forResponseWithStatusCode statusCode: Int, errorCode: Int?) -> Bool
}

internal class ResilientNetworkRecovery<T: Operation> where T: ResultInjection, T.Result == HTTPResult<Data> {

    typealias ConfigurationBlock = (T) -> Void
    typealias Payload = RepeatProcedurePayload<T>
    typealias Recovery = (Delay?, ConfigurationBlock)

    let behavior: ResilientNetworkBehavior

    var max: Int { return behavior.maximumNumberOfAttempts }

    var wait: WaitStrategy { return behavior.timeoutBackoffStrategy }

    init(behavior: ResilientNetworkBehavior) {
        self.behavior = behavior
    }

    func recover(withInfo info: RetryFailureInfo<T>, payload: Payload) -> Recovery? {
        guard let response = info.operation.result.value?.response, behavior.retryRequest(forResponseWithStatusCode: response.statusCode, errorCode: info.errorCode) else { return nil }
        return (behavior.errorDelay ?? payload.delay, info.configure)
    }
}

public enum ProcedureKitNetworkResiliencyError: Error {
    case receivedErrorStatusCode(Int)
}

/**
 ResilientNetworkProcedure is a RetryProcedure subclass which together with ResilientNetworkBehavior
 protocol enables framework consumers to write _network resilient procedures_. Network resiliency
 refers to the practice of client and server working together in order to withstand network failures,
 network conjestion and other types of network errors.

 Typically this is most easily understood by a client not repeatedly requesting data in the event
 of an error from the server. Typically framework consumers will want to define their own rules
 for the client, such as how many retries should be attemted, or what backoff strategy between
 attempts, and which HTTP response error codes should be retried. This is business logic is
 encapsulated by the ResilientNetworkBehavior protocol. Clients should implement this on
 a type, which it uses to initialize the procedure with.

 For the actual network request, this can be any operation (which conforms to ResultInjection)
 where the result is (Data, HTTPURLResponse)?. For example, see NetworkDataProcedure.

 */
open class ResilientNetworkProcedure<T: Operation>: RetryProcedure<T> where T: ResultInjection, T.Result == HTTPResult<Data> {

    internal private(set) var recovery: ResilientNetworkRecovery<T>

    public init(dispatchQueue: DispatchQueue = DispatchQueue.default, behavior: ResilientNetworkBehavior, body: @escaping () -> T?) {

        let _recovery = ResilientNetworkRecovery<T>(behavior: behavior)

        let handler: Handler = { [weak _recovery] info, payload in
            guard
                let recovery = _recovery,
                let (delay, configure) = recovery.recover(withInfo: info, payload: payload)
            else { return nil }
            return RepeatProcedurePayload(operation: payload.operation, delay: delay, configure: configure)
        }

        recovery = _recovery

        super.init(dispatchQueue: dispatchQueue, max: recovery.max, wait: recovery.wait, iterator: AnyIterator(body), retry: handler)
    }

    open override func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        guard errors.isEmpty && operation === current,
            let code = response?.statusCode, recovery.behavior.retryRequest(forResponseWithStatusCode: code, errorCode: nil)
        else {
            super.procedureQueue(queue, willFinishOperation: operation, withErrors: errors)
            return
        }

        log.warning(message: "Identified erroneous error status code: \(code). Will trigger retry mechanism.")
        super.procedureQueue(queue, willFinishOperation: operation, withErrors: [ProcedureKitNetworkResiliencyError.receivedErrorStatusCode(code)])
    }
}

extension ResilientNetworkProcedure: ResultInjection {

    public var requirement: PendingValue<T.Requirement> {
        get { return current.requirement }
        set {
            current.requirement = newValue
            appendConfigureBlock { $0.requirement = newValue }
        }
    }

    public var result: PendingValue<T.Result> { return current.result }
}

public extension ResilientNetworkProcedure {

    /// - returns: the resultant Data
    var data: Data? { return result.value?.payload }

    /// - returns: the resultant Data
    var response: HTTPURLResponse? { return result.value?.response }
}
