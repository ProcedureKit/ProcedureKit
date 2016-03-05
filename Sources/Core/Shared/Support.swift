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
}

extension Dictionary {

    internal init<Sequence: SequenceType where Sequence.Generator.Element == Value>(sequence: Sequence, keyMapper: Value -> Key?) {
        self.init()
        for item in sequence {
            if let key = keyMapper(item) {
                self[key] = item
            }
        }
    }
}
