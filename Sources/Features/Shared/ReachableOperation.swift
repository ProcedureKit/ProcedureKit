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
public class ReachableOperation<T: NSOperation>: ComposedOperation<T> {

    private let reachability: SystemReachabilityType
    private var token: String? = .None
    private var status: Reachability.NetworkStatus? = .None

    /// The required connectivity kind.
    public let connectivity: Reachability.Connectivity

    /**
     Composes an operation to ensure that is will definitely be executed as soon as
     the required kind of connectivity is achieved.
    
     - parameter [unlabeled] operation: any `NSOperation` type.
     - parameter connectivity: a `Reachability.Connectivity` value, defaults to `.AnyConnectionKind`.
    */
    public convenience init(_ operation: T, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        self.init(operation: operation, connectivity: connectivity, reachability: Reachability.sharedInstance)
    }

    init(operation: T, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        self.connectivity = connectivity
        self.reachability = reachability
        super.init(operation: operation)
        name = "Reachable Operation <\(operation.operationName)>"
    }

    public override func execute() {
        do {
            let _execute = super.execute
            self.token = try reachability.addObserver { [weak self] status in
                if let weakSelf = self, token = weakSelf.token {
                    if weakSelf.checkStatus(status) {
                        weakSelf.reachability.removeObserverWithToken(token)
                        _execute()
                    }
                }
            }
        }
        catch {
            log.fatal("Reachability Error: \(error)")
            finish(error)
        }
    }

    internal func checkStatus(status: Reachability.NetworkStatus) -> Bool {
        switch (connectivity, status) {
        case (_, .NotReachable):
            return false
        case (.AnyConnectionKind, _), (.ViaWWAN, _), (.ViaWiFi, .Reachable(.ViaWiFi)):
            return true
        default:
            return false
        }
    }
}

