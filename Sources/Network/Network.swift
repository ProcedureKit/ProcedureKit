//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import SystemConfiguration

public enum NetworkRetryBehavior {
    case fail
    case retryWithDelay(Delay)
}

public protocol NetworkResilience {

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
     Some HTTP status codes should be treated as errors, and
     retried

     - parameter statusCode: an Int
     - returns: a Bool, to indicate that the
     */
    func retryBehavior(forResponseWithHTTPStatusCode statusCode: HTTPStatusCode, withSuggestedDelay: Delay) -> NetworkRetryBehavior
}

public struct DefaultNetworkResilience: NetworkResilience {

    public let maximumNumberOfAttempts: Int

    public let backoffStrategy: WaitStrategy

    public let requestTimeout: TimeInterval?

    public func retryBehavior(forResponseWithHTTPStatusCode statusCode: HTTPStatusCode, withSuggestedDelay delay: Delay) -> NetworkRetryBehavior {
        switch statusCode {
        case let code where code.isServerError:
            return .retryWithDelay(delay)
        case .requestTimeout, .tooManyRequests:
            return .retryWithDelay(delay)
        default:
            return .fail
        }
    }

    public init(maximumNumberOfAttempts: Int = 3, backoffStrategy: WaitStrategy = .incrementing(initial: 2, increment: 2), requestTimeout: TimeInterval? = 8.0) {
        self.maximumNumberOfAttempts = maximumNumberOfAttempts
        self.backoffStrategy = backoffStrategy
        self.requestTimeout = requestTimeout
    }
}

class NetworkReachabilityWaitProcedure: Procedure {

    let reachability: SystemReachability
    let connectivity: Reachability.Connectivity

    init(reachability: SystemReachability, via connectivity: Reachability.Connectivity = .any) {
        self.reachability = reachability
        self.connectivity = connectivity
        super.init()
    }

    override func execute() {
        reachability.whenReachable(via: connectivity) { [weak self] in self?.finish() }
    }
}

class NetworkRecovery<T: Operation> where T: NetworkOperation {

    let resilience: NetworkResilience
    let connectivity: Reachability.Connectivity
    var reachability: SystemReachability = Reachability.Manager.shared

    var max: Int { return resilience.maximumNumberOfAttempts }

    var wait: WaitStrategy { return resilience.backoffStrategy }

    init(resilience: NetworkResilience, connectivity: Reachability.Connectivity) {
        self.resilience = resilience
        self.connectivity = connectivity
    }

    func recover(withInfo info: RetryFailureInfo<T>, payload: RepeatProcedurePayload<T>) -> RepeatProcedurePayload<T>? {

        // Check to see if we should wait for a network reachability change before retrying
        if shouldWaitForReachabilityChange(givenInfo: info) {
            let waiter = NetworkReachabilityWaitProcedure(reachability: reachability, via: connectivity)
            payload.operation.add(dependency: waiter)
            info.addOperations(waiter)
            return RepeatProcedurePayload(operation: payload.operation, delay: nil, configure: payload.configure)
        }

        // Determine the retry behavior
        switch retryBehavior(givenInfo: info, delay: payload.delay) {
        case let .retryWithDelay(delay):
            return payload.set(delay: delay)
        case .fail:
            return nil
        }
    }

    func shouldWaitForReachabilityChange(givenInfo info: RetryFailureInfo<T>) -> Bool {
        guard let networkError = info.operation.networkError else { return false }
        return networkError.waitForReachabilityChangeBeforeRetrying
    }

    func retryBehavior(givenInfo info: RetryFailureInfo<T>, delay: Delay?) -> NetworkRetryBehavior {

        // Check that we've actually got a network error & suggested delay
        guard let networkError = info.operation.networkError, let delay = delay else { return .fail }

        // Check to see if we have a transient or timeout network error - retry with suggested delay
        if networkError.isTransientError || networkError.isTimeoutError {
            return .retryWithDelay(delay)
        }

        // Check to see if we have an http error code
        guard let statusCode = networkError.httpStatusCode, statusCode.isClientError || statusCode.isServerError else {
            return .fail
        }

        // Query the network resilience type to determine the behavior.
        return resilience.retryBehavior(forResponseWithHTTPStatusCode: statusCode, withSuggestedDelay: delay)
    }
}

open class NetworkProcedure<T: Procedure>: RetryProcedure<T> where T: NetworkOperation {

    let recovery: NetworkRecovery<T>

    internal var reachability: SystemReachability {
        get { return recovery.reachability }
        set { recovery.reachability = newValue }
    }

    public init<OperationIterator>(dispatchQueue: DispatchQueue? = nil, resilience: NetworkResilience = DefaultNetworkResilience(), connectivity: Reachability.Connectivity = .any, iterator base: OperationIterator) where OperationIterator: IteratorProtocol, OperationIterator.Element == T {
        recovery = NetworkRecovery<T>(resilience: resilience, connectivity: connectivity)
        super.init(dispatchQueue: dispatchQueue, max: recovery.max, wait: recovery.wait, iterator: base, retry: recovery.recover(withInfo:payload:))
        if let timeout = resilience.requestTimeout {
            appendConfigureBlock { $0.add(observer: TimeoutObserver(by: timeout)) }
        }
    }

    public convenience init(dispatchQueue: DispatchQueue = DispatchQueue.default, resilience: NetworkResilience = DefaultNetworkResilience(), connectivity: Reachability.Connectivity = .any, body: @escaping () -> T?) {
        self.init(dispatchQueue: dispatchQueue, resilience: resilience, connectivity: connectivity, iterator: AnyIterator(body))
    }
}
