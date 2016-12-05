//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(watchOS)

import SystemConfiguration

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
    func shouldRetry(forResponseWithHTTPStatusCode statusCode: HTTPStatusCode) -> Bool
}

public struct DefaultNetworkResilience: NetworkResilience {

    public let maximumNumberOfAttempts: Int

    public let backoffStrategy: WaitStrategy

    public let requestTimeout: TimeInterval?

    public init(maximumNumberOfAttempts: Int = 3, backoffStrategy: WaitStrategy = .incrementing(initial: 2, increment: 2), requestTimeout: TimeInterval? = 8.0) {
        self.maximumNumberOfAttempts = maximumNumberOfAttempts
        self.backoffStrategy = backoffStrategy
        self.requestTimeout = requestTimeout
    }

    public func shouldRetry(forResponseWithHTTPStatusCode statusCode: HTTPStatusCode) -> Bool {
        switch statusCode {
        case let code where code.isServerError:
            return true
        case .requestTimeout, .tooManyRequests:
            return true
        default:
            return false
        }
    }
}

public enum ProcedureKitNetworkResiliencyError: Error {
    case receivedErrorStatusCode(HTTPStatusCode)
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

        let networkResponse = info.operation.makeNetworkResponse()

        // Check to see if we should wait for a network reachability change before retrying
        if shouldWaitForReachabilityChange(givenNetworkResponse: networkResponse) {
            let waiter = NetworkReachabilityWaitProcedure(reachability: reachability, via: connectivity)
            payload.operation.add(dependency: waiter)
            info.addOperations(waiter)
            return RepeatProcedurePayload(operation: payload.operation, delay: nil, configure: payload.configure)
        }

        // Check if the resiliency behavior indicates a retry
        guard shouldRetry(givenNetworkResponse: networkResponse) else { return nil }

        return payload
    }

    func shouldWaitForReachabilityChange(givenNetworkResponse networkResponse: ProcedureKitNetworkResponse) -> Bool {
        guard let networkError = networkResponse.error else { return false }
        return networkError.waitForReachabilityChangeBeforeRetrying
    }

    func shouldRetry(givenNetworkResponse networkResponse: ProcedureKitNetworkResponse) -> Bool {

        // Check that we've actually got a network error & suggested delay
        if let networkError = networkResponse.error {

            // Check to see if we have a transient or timeout network error - retry with suggested delay
            if networkError.isTransientError || networkError.isTimeoutError {
                return true
            }
        }

        // Check to see if we have an http error code
        guard let statusCode = networkResponse.httpStatusCode, statusCode.isClientError || statusCode.isServerError else {
            return false
        }

        // Query the network resilience type to determine the behavior.
        return resilience.shouldRetry(forResponseWithHTTPStatusCode: statusCode)
    }
}

open class NetworkProcedure<T: Procedure>: RetryProcedure<T>, OutputProcedure where T: NetworkOperation, T: OutputProcedure, T.Output: HTTPPayloadResponseProtocol {

    public typealias Output = T.Output

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

    open override func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        var networkErrors = errors

        // Ultimately, always call super to correctly manage the operation lifecycle.
        defer { super.procedureQueue(queue, willFinishOperation: operation, withErrors: networkErrors) }

        // Check that the operation is the current one.
        guard operation == current else { return }

        // If we have any errors let RetryProcedure (super) deal with it by returning here
        guard errors.isEmpty else { return }

        // Create a network response from the network operation
        let networkResponse = current.makeNetworkResponse()

        // Check to see if this network response should be retried
        guard recovery.shouldRetry(givenNetworkResponse: networkResponse), let statusCode = networkResponse.httpStatusCode else { return }

        // Create resiliency error
        let error: ProcedureKitNetworkResiliencyError = .receivedErrorStatusCode(statusCode)

        // Set the network errors
        networkErrors = [error]
    }
}

#endif

public extension InputProcedure where Input: Equatable {

    @discardableResult func injectPayload<Dependency: OutputProcedure>(fromNetwork dependency: Dependency) -> Self where Dependency.Output: HTTPPayloadResponseProtocol, Dependency.Output.Payload == Input {
        return injectResult(from: dependency) { http in
            guard let payload = http.payload else { throw ProcedureKitError.requirementNotSatisfied() }
            return payload
        }
    }
}
