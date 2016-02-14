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
    public convenience init(_ op: T, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        self.init(operation: op, connectivity: connectivity, reachability: ReachabilityManager.sharedInstance)
    }

    init(operation op: T, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        self.connectivity = connectivity
        self.reachability = reachability
        super.init(operation: op)
        name = "Reachable Operation <\(operation.operationName)>"
    }

    public override func execute() {
        reachability.whenConnected(connectivity, block: super.execute)
    }
}

