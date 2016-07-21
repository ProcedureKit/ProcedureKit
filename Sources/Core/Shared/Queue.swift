//
//  Queue.swift
//  Operations
//
//  Created by Daniel Thorpe on 23/06/2016.
//
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

    /// returns: a Bool to indicate if the current queue is the main queue
    public static var isMainQueue: Bool {
        setKeyOnMainQueue
        return DispatchQueue.getSpecific(key: mainQueueKey) == 0
    }

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
        case .initiated: return .qosUserInitiated
        case .interactive: return .qosUserInteractive
        case .utility: return .qosUtility
        case .background: return .qosBackground
        default: return .qosDefault
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

     let queue = Queue.Utility.serial("me.danthorpe.Procedure.eg")
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

     let queue = Queue.Initiated.concurrent("me.danthorpe.Procedure.eg")
     dispatch_barrier_async(queue) {
     print("I'm on a initiated concurrent queue.")
     }
     */
    public func concurrent(_ named: String) -> DispatchQueue {
        return DispatchQueue(label: named, attributes: [.concurrent, qos_attributes])
    }

    /**
     Initialize a Queue with a given QualityOfService.

     - parameter qos: a QualityOfService value
     - returns: a Queue with an equivalent quality of service
     */
    public init(qos: QualityOfService) {
        switch qos {
        case .background:
            self = .background
        case .default:
            self = .default
        case .userInitiated:
            self = .initiated
        case .userInteractive:
            self = .interactive
        case .utility:
            self = .utility
        }
    }

    /**
     Initialize a Queue with a given GCD quality of service class.

     - parameter qos: a DispatchQoS value
     - returns: a Queue with an equivalent quality of service
     */
    public init(qos: DispatchQoS) {
        switch qos.qosClass {
        case .background:
            self = .background
        case .userInitiated:
            self = .initiated
        case .userInteractive:
            self = .interactive
        case .utility:
            self = .utility
        default:
            self = .default
        }
    }
}

internal let mainQueueKey = DispatchSpecificKey<Int8>()
internal let setKeyOnMainQueue: () = {
    DispatchQueue.main.setSpecific(key: mainQueueKey, value: 0)
}()
