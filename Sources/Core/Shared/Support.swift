//
//  Support.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

// MARK: - Queues

/**
A nice Swift wrapper around `dispatch_queue_create`. The cases
correspond to GCD's quality of service classes. To get the
main queue use like this:

    dispatch_async(Queue.Main.queue) {
       print("I'm on the main queue!")
    }
*/
public enum Queue {

    /// The main queue
    case main

    /// The default QOS
    case `default`

    /// Use for user initiated tasks which do not impact the UI. Such as data processing.
    case initiated

    /// Use for user initiated tasks which do impact the UI - e.g. a rendering pipeline.
    case interactive

    /// Use for non-user initiated task.
    case utility

    /// Backgound QOS is a severly limited class, should not be used for anything when the app is active.
    case background

    // swiftlint:disable variable_name
    private var qos_attributes: DispatchQueueAttributes {
        switch self {
        case .initiated: return DispatchQueueAttributes.qosUserInitiated
        case .interactive: return DispatchQueueAttributes.qosUserInteractive
        case .utility: return DispatchQueueAttributes.qosUtility
        case .background: return DispatchQueueAttributes.qosBackground
        default: return DispatchQueueAttributes.qosDefault
        }
    }

    private var qos_global_attributes: DispatchQueue.GlobalAttributes {
        switch self {
        case .initiated: return .qosUserInitiated
        case .interactive: return .qosUserInteractive
        case .utility: return .qosUtility
        case .background: return .qosBackground
        default: return .qosDefault
        }
    }
    // swiftlint:enable variable_name

    /**
    Access the appropriate global `dispatch_queue_t`. For `.Main` this
    is the main queue, for other cases, it is the global queue for the
    appropriate `qos_class_t`.

    - parameter queue: the corresponding global dispatch_queue_t
    */
    public var queue: DispatchQueue {
        switch self {
        case .main: return .main
        default: return .global(attributes: qos_global_attributes)
        }
    }

    /**
    Creates a named serial queue with the correct QOS class.

    Use like this:

        let queue = Queue.Utility.serial("me.danthorpe.Operation.eg")
            dispatch_async(queue) {
            print("I'm on a utility serial queue.")
        }
    */
    public func serial(_ named: String) -> DispatchQueue {
        return DispatchQueue(label: named, attributes: [.serial, qos_attributes])
    }

    /**
    Creates a named concurrent queue with the correct QOS class.

    Use like this:

        let queue = Queue.Initiated.concurrent("me.danthorpe.Operation.eg")
        dispatch_barrier_async(queue) {
            print("I'm on a initiated concurrent queue.")
        }
    */
    public func concurrent(_ named: String) -> DispatchQueue {
        return DispatchQueue(label: named, attributes: [.concurrent, qos_attributes])
    }
}

public extension DispatchQueue {

    /**
     Provides a throwing Void block with a rethrowing API.
     - parameter block: a throwing block returning Void.
    */
//    func sync(execute block: () throws -> Void) rethrows {
//        var failure: ErrorProtocol? = .none
//
//        let catcher = {
//            do {
//                try block()
//            }
//            catch {
//                failure = error
//            }
//        }
//
//        sync(execute: catcher)
//
//        if let failure = failure {
//            try { throw failure }()
//        }
//    }

    /**
     Provides a throwing T block with a rethrowing API.
     - parameter block: a throwing block returning T.
     */
    func sync<T>(execute block: () throws -> T) rethrows -> T {
        var result: T!
        try sync {
            result = try block()
        }
        return result
    }
}




extension Dictionary {

    internal init<Sequence: Swift.Sequence where Sequence.Iterator.Element == Value>(sequence: Sequence, keyMapper: (Value) -> Key?) {
        self.init()
        for item in sequence {
            if let key = keyMapper(item) {
                self[key] = item
            }
        }
    }
}
