//
//  Support.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

// MARK: - Queues

public enum Queue {

    case Main
    case Default
    case Initiated
    case Interactive
    case Utility
    case Background

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

    public var queue: dispatch_queue_t {
        switch self {
        case .Main: return dispatch_get_main_queue()
        default: return dispatch_get_global_queue(qos_class, 0)
        }
    }

    public func serial(named: String) -> dispatch_queue_t {
        return dispatch_queue_create(named, dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class, QOS_MIN_RELATIVE_PRIORITY))
    }

    public func concurrent(named: String) -> dispatch_queue_t {
        return dispatch_queue_create(named, dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, qos_class, QOS_MIN_RELATIVE_PRIORITY))
    }
}

public protocol ErrorType { }


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

