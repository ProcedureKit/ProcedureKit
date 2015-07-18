//
//  Support.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

// MARK: - Queues

enum Queue {

    case Default
    case Initiated
    case Interactive
    case Utility
    case Background

    var queue: dispatch_queue_t {
        switch self {
        case .Default: return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
        case .Initiated: return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
        case .Interactive: return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        case .Utility: return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        case .Background: return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        }
    }
}

