//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import SystemConfiguration

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

class NetworkReachableRecovery<T: Operation> where T: NetworkOperation {

    let connectivity: Reachability.Connectivity
    var reachability: SystemReachability = Reachability.Manager.shared

    init(connectivity: Reachability.Connectivity) {
        self.connectivity = connectivity
    }

    func recover(withInfo info: RetryFailureInfo<T>, payload: RepeatProcedurePayload<T>) -> RepeatProcedurePayload<T>? {
        guard let networkError = info.operation.networkError, networkError.waitForReachabilityChangeBeforeRetrying else {
            return payload
        }
        let waiter = NetworkReachabilityWaitProcedure(reachability: reachability, via: connectivity)
        payload.operation.add(dependency: waiter)
        info.addOperations(waiter)
        return RepeatProcedurePayload(operation: payload.operation, delay: nil, configure: payload.configure)
    }
}

open class NetworkReachableProcedure<T: Operation>: RetryProcedure<T> where T: NetworkOperation {

    let recovery: NetworkReachableRecovery<T>

    internal var reachability: SystemReachability {
        get { return recovery.reachability }
        set { recovery.reachability = newValue }
    }

    public init<OperationIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, connectivity: Reachability.Connectivity = .any, iterator base: OperationIterator) where OperationIterator: IteratorProtocol, OperationIterator.Element == T {
        recovery = NetworkReachableRecovery<T>(connectivity: connectivity)
        super.init(dispatchQueue: dispatchQueue, max: max, wait: .random(minimum: 0.1, maximum: 0.5), iterator: base, retry: recovery.recover(withInfo:payload:))
    }

    public convenience init(dispatchQueue: DispatchQueue = DispatchQueue.default, max: Int? = nil, connectivity: Reachability.Connectivity = .any, body: @escaping () -> T?) {
        self.init(dispatchQueue: dispatchQueue, max: max, connectivity: connectivity, iterator: AnyIterator(body))
    }
}
