//
//  ReachableOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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

        checkStatusAgain(delay: 0.0)
    }

    private func evaluate() {
        println("Evaluating...")
        if checkStatus() {
            println("  status: true")
            if let token = token {
                reachability.removeObserverWithToken(token)
            }
            addOperation(operation)
        }
        else {
            println("  status: false")
            checkStatusAgain()
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

    private func checkStatusAgain(delay: NSTimeInterval = 1.0) {

        let reevaluate = BlockOperation { [weak self] continuation in
            self?.evaluate()
        }

        if delay > 0.0 {
            reevaluate.addDependency(DelayOperation(interval: delay))
        }
        
        println("Will re-evaluate..")
        addOperation(reevaluate)
    }
}


