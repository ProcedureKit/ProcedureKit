//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

// MARK: - Queue

public extension DispatchQueue {

    static var isMainDispatchQueue: Bool {
        return mainQueueScheduler.isScheduledQueue
    }

    static var `default`: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    }

    static var initiated: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    }

    static var interactive: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    }

    static var utility: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    }

    static var background: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    }

    static func concurrent(label: String, qos: DispatchQoS = .default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) -> DispatchQueue {
        return DispatchQueue(label: label, qos: qos, attributes: [.concurrent], autoreleaseFrequency: autoreleaseFrequency, target: target)
    }

    static func onMain<T>(execute work: () throws -> T) rethrows -> T {
        guard isMainDispatchQueue else {
            return try DispatchQueue.main.sync(execute: work)
        }
        return try work()
    }
}

internal extension QualityOfService {

    var qos: DispatchQoS {
        switch self {
        case .userInitiated: return DispatchQoS.userInitiated
        case .userInteractive: return DispatchQoS.userInteractive
        case .utility: return DispatchQoS.utility
        case .background: return DispatchQoS.background
        case .default: return DispatchQoS.default
        }
    }

    var qosClass: DispatchQoS.QoSClass {
        switch self {
        case .userInitiated: return .userInitiated
        case .userInteractive: return .userInteractive
        case .utility: return .utility
        case .background: return .background
        case .default: return .default
        }
    }
}

internal final class Scheduler {

    var key: DispatchSpecificKey<UInt8>
    var value: UInt8 = 1

    init(queue: DispatchQueue) {
        key = DispatchSpecificKey()
        queue.setSpecific(key: key, value: value)
    }

    var isScheduledQueue: Bool {
        guard let retrieved = DispatchQueue.getSpecific(key: key) else { return false }
        return value == retrieved
    }
}

internal let mainQueueScheduler = Scheduler(queue: DispatchQueue.main)
