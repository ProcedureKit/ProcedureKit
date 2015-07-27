//
//  ReachableOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
    Compose your `NSOperation` inside a `ReachableOperation` to
    ensure that it is executed when the desired connectivity is
    available.

    If the device is not reachable, the operation will observe
    the default route reachability, and add your operation as
    soon as the conditions are met.
*/
public class ReachableOperation<O: NSOperation>: GroupOperation {

    public let operation: O
    public let connectivity: Reachability.Connectivity
    private let reachability: SystemReachability
    private var token: String? = .None
    private var status: Reachability.NetworkStatus? = .None

    public convenience init(operation: O, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        self.init(operation: operation, connectivity: connectivity, reachability: Reachability.sharedInstance)
    }

    // Testing interface
    public init(operation: O, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachability) {
        self.operation = operation
        self.connectivity = connectivity
        self.reachability = reachability
        super.init(operations: [])

        token = reachability.addObserver { status in
            self.status = status
        }
    }

    public override func execute() {
        addOperation(evaluate())
        super.execute()
    }

    private func evaluate() -> NSOperation {
        if checkStatus() {
            if let token = token {
                reachability.removeObserverWithToken(token)
            }
            return operation
        }
        else {
            return checkStatusAgain()
        }
    }

    private func checkStatus() -> Bool {
        if let status = status {
            switch (connectivity, status) {
            case (_, .NotReachable), (.ViaWiFi, .Reachable(.ViaWWAN)):
                return false
            case (.AnyConnectionKind, _), (.ViaWWAN, _), (.ViaWiFi, .Reachable(.ViaWiFi)):
                return true
            default:
                return false
            }
        }
        return false
    }

    private func checkStatusAgain(delay: NSTimeInterval = 1.0) -> Operation {

        let reevaluate = BlockOperation { [weak self] (continueWithError: BlockOperation.ContinuationBlockType) in
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Default.queue) {
                if let weakSelf = self {
                    weakSelf.addOperation(weakSelf.evaluate())
                }
                continueWithError(error: nil)
            }
        }

        reevaluate.name = "Reevaluate Network Status"
        return reevaluate
    }
}


