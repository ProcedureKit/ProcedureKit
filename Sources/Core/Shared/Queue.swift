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

    internal final class Scheduler {

        private var once: dispatch_once_t = 0
        private var key: UInt8 = 0
        private var context: UInt8 = 0

        init(queue: dispatch_queue_t) {
            dispatch_once(&once) {
                dispatch_queue_set_specific(queue, &self.key, &self.context, nil)
            }
        }

        var isScheduleQueue: Bool {
            return dispatch_get_specific(&self.key) == &self.context
        }
    }

    /// returns: a Bool to indicate if the current queue is the main queue
    public static var isMainQueue: Bool {
        return mainQueueScheduler.isScheduleQueue
    }

    /// The main queue
    case Main

    /// The default QOS
    case Default

    /// Use for user initiated tasks which do not impact the UI. Such as data processing.
    case Initiated

    /// Use for user initiated tasks which do impact the UI - e.g. a rendering pipeline.
    case Interactive

    /// Use for non-user initiated task.
    case Utility

    /// Backgound QOS is a severly limited class, should not be used for anything when the app is active.
    case Background

    // swiftlint:disable variable_name
    private var qos_class: qos_class_t {
        switch self {
        case .Main: return qos_class_main()
        case .Default: return QOS_CLASS_DEFAULT
        case .Initiated: return QOS_CLASS_USER_INITIATED
        case .Interactive: return QOS_CLASS_USER_INTERACTIVE
        case .Utility: return QOS_CLASS_UTILITY
        case .Background: return QOS_CLASS_BACKGROUND
        }
    }
    // swiftlint:enable variable_name

    /**
     Access the appropriate global `dispatch_queue_t`. For `.Main` this
     is the main queue, for other cases, it is the global queue for the
     appropriate `qos_class_t`.

     - parameter queue: the corresponding global dispatch_queue_t
     */
    public var queue: dispatch_queue_t {
        switch self {
        case .Main: return dispatch_get_main_queue()
        default: return dispatch_get_global_queue(qos_class, 0)
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
    public func serial(named: String) -> dispatch_queue_t {
        return dispatch_queue_create(named, dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class, QOS_MIN_RELATIVE_PRIORITY))
    }

    /**
     Creates a named concurrent queue with the correct QOS class.

     Use like this:

     let queue = Queue.Initiated.concurrent("me.danthorpe.Operation.eg")
     dispatch_barrier_async(queue) {
     print("I'm on a initiated concurrent queue.")
     }
     */
    public func concurrent(named: String) -> dispatch_queue_t {
        return dispatch_queue_create(named, dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, qos_class, QOS_MIN_RELATIVE_PRIORITY))
    }

    /**
     Initialize a Queue with a given NSQualityOfService.

     - parameter qos: a NSQualityOfService value
     - returns: a Queue with an equivalent quality of service
     */
    public init(qos: NSQualityOfService) {
        switch qos {
        case .Background:
            self = .Background
        case .Default:
            self = .Default
        case .UserInitiated:
            self = .Initiated
        case .UserInteractive:
            self = .Interactive
        case .Utility:
            self = .Utility
        }
    }

    /**
     Initialize a Queue with a given GCD quality of service class.

     - parameter qos: a qos_class_t value
     - returns: a Queue with an equivalent quality of service
     */
    public init(qos: qos_class_t) {
        switch qos {
        case qos_class_main():
            self = .Main
        case QOS_CLASS_BACKGROUND:
            self = .Background
        case QOS_CLASS_USER_INITIATED:
            self = .Initiated
        case QOS_CLASS_USER_INTERACTIVE:
            self = .Interactive
        case QOS_CLASS_UTILITY:
            self = .Utility
        default:
            self = .Default
        }
    }
}

internal let mainQueueScheduler = Queue.Scheduler(queue: Queue.Main.queue)
