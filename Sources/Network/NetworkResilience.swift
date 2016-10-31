//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public struct ResilientNetworkResponse {
    public enum ResilientNetworkError: Error {
        case requestTimeout
        case underlyingErrors([Error])
    }

    public let http: HTTPURLResponse?
    public let error: ResilientNetworkError?

    public var statusCode: HTTPStatusCode? {
        return http?.code
    }

    func set(http: HTTPURLResponse?) -> ResilientNetworkResponse {
        return ResilientNetworkResponse(http: http, error: error)
    }

    func set(error: ResilientNetworkError?) -> ResilientNetworkResponse {
        return ResilientNetworkResponse(http: http, error: error)
    }

    internal var underlyingErrors: [Error]? {
        if case let .some(.underlyingErrors(errors)) = error {
            return errors
        }
        return nil
    }

    internal var possiblyRequiresRetry: Bool {
        get {
            // Check for request timeout error
            if case .some(.requestTimeout) = error {
                return true
            }
            // status code is a client or server error
            else if let code = statusCode, code.isClientError || code.isServerError {
                return true
            }
            return underlyingErrors != nil
        }
    }
}

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
    var backoffStrategy: WaitStrategy { get }

    /**
     A request timeout, which if specified indicates the maximum
     amount of time to wait for a response.

     - returns: a TimeInterval
     */
    var requestTimeout: TimeInterval? { get }

    /**
     Some network response status codes should be treated as
     errors.

     - parameter statusCode: an Int
     - parameter errorCode: an Int? if returned from URLSession
     - returns: a Bool, to indicate that the
     */
    func shouldRetryRequest(forResponse response: ResilientNetworkResponse) -> Bool

    /**
     The behavior can modify the suggest delay before retrying a request.

     - parameter statusCode: an Int
     - parameter errorCode: an Int? if returned from URLSession
     - parameter delay: the suggested delay as determined by the backoffStrategy
     - returns: a Delay?
     */
    func retryRequestAfter(suggestedDelay delay: Delay, forResponse response: ResilientNetworkResponse) -> Delay?
}

internal class ResilientNetworkRecovery<T: Operation> where T: InputProcedure & OutputProcedure, T.Output == HTTPPayloadResponse<Data> {

    typealias ConfigurationBlock = (T) -> Void
    typealias Payload = RepeatProcedurePayload<T>
    typealias Recovery = (Delay?, ConfigurationBlock)

    let behavior: ResilientNetworkBehavior

    var max: Int { return behavior.maximumNumberOfAttempts }

    var wait: WaitStrategy { return behavior.backoffStrategy }

    init(behavior: ResilientNetworkBehavior) {
        self.behavior = behavior
    }

    func resilientNetworkResponse(fromHTTPURLResponse http: HTTPURLResponse?, errors: [Error]) -> ResilientNetworkResponse {
        // Create a network response
        var networkResponse = ResilientNetworkResponse(http: http, error: .underlyingErrors(errors))

        // Check to see if we timed out
        if let procedureKitError = errors.first as? ProcedureKitError {
            if case .timedOut(with: _) = procedureKitError.context {
                networkResponse = networkResponse.set(error: .requestTimeout)
            }
        }
        return networkResponse
    }

    func recover(withInfo info: RetryFailureInfo<T>, payload: Payload) -> Recovery? {
        guard let http = info.operation.result.value?.response else { return nil }
        let response = resilientNetworkResponse(fromHTTPURLResponse: http, errors: info.errors)
        guard
            let suggestedDelay = payload.delay,
            let delay = behavior.retryRequestAfter(suggestedDelay: suggestedDelay, forResponse: response)
        else { return nil }
        return (delay, info.configure)
    }
}

public enum ProcedureKitNetworkResiliencyError: Error {
    case receivedErrorStatusCode(HTTPStatusCode)
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
open class ResilientNetworkProcedure<T: Operation>: RetryProcedure<T>, InputProcedure, OutputProcedure where T: InputProcedure & OutputProcedure, T.Output == HTTPPayloadResponse<Data> {

    internal private(set) var recovery: ResilientNetworkRecovery<T>

    public init<NetworkIterator: IteratorProtocol>(dispatchQueue: DispatchQueue? = nil, behavior: ResilientNetworkBehavior, iterator: NetworkIterator) where T == NetworkIterator.Element {

        let _recovery = ResilientNetworkRecovery<T>(behavior: behavior)

        let handler: Handler = { [weak _recovery] info, payload in
            guard
                let recovery = _recovery,
                let (delay, configure) = recovery.recover(withInfo: info, payload: payload)
                else { return nil }
            return RepeatProcedurePayload(operation: payload.operation, delay: delay, configure: configure)
        }

        recovery = _recovery

        let requestTimeout = behavior.requestTimeout
        let tmp = MapIterator(iterator) { (procedure: T) -> T in
            if let timeout = requestTimeout {
                procedure.add(observer: TimeoutObserver(by: timeout))
            }
            return procedure
        }
        super.init(dispatchQueue: dispatchQueue, max: recovery.max, wait: recovery.wait, iterator: tmp, retry: handler)
    }

    public convenience init(dispatchQueue: DispatchQueue? = nil, behavior: ResilientNetworkBehavior, body: @escaping () -> T?) {
        self.init(dispatchQueue: dispatchQueue, behavior: behavior, iterator: AnyIterator(body))
    }

    open override func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        guard operation == current else { return }

        // Create a network response
        let networkResponse = recovery.resilientNetworkResponse(fromHTTPURLResponse: response, errors: errors)

        // Check the behaviour to see if we should retry this request
        guard networkResponse.possiblyRequiresRetry && recovery.behavior.shouldRetryRequest(forResponse: networkResponse) else {
            return
        }

        // Make sure that we have final errors
        let finalErrors: [Error] = networkResponse.error.map { [$0] } ?? []

        log.notice(message: "Behaviour indicates retry given errors: \(finalErrors)")
        super.procedureQueue(queue, willFinishOperation: operation, withErrors: finalErrors)
    }
}

public extension ResilientNetworkProcedure {

    /// - returns: the resultant Data
    var data: Data? { return output.success?.payload }

    /// - returns: the resultant Data
    var response: HTTPURLResponse? { return output.success?.response }
}
