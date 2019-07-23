//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

// MARK: - Queue

public extension DispatchQueue {

    static var isMainDispatchQueue: Bool {
        return mainQueueScheduler.isOnScheduledQueue
    }

    var isMainDispatchQueue: Bool {
        return mainQueueScheduler.isScheduledQueue(self)
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

    static var currentQoSClass: DispatchQoS.QoSClass {
        return DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified
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
        @unknown default:
            return DispatchQoS.default
        }
    }

    var qosClass: DispatchQoS.QoSClass {
        switch self {
        case .userInitiated: return .userInitiated
        case .userInteractive: return .userInteractive
        case .utility: return .utility
        case .background: return .background
        case .default: return .default
        @unknown default:
            return .default
        }
    }
}

extension DispatchQoS.QoSClass: Comparable {

    public static func < (lhs: DispatchQoS.QoSClass, rhs: DispatchQoS.QoSClass) -> Bool { // swiftlint:disable:this cyclomatic_complexity
        switch lhs {
        case .unspecified:
            return rhs != .unspecified
        case .background:
            switch rhs {
            case .unspecified, lhs: return false
            default: return true
            }
        case .utility:
            switch rhs {
            case .default, .userInitiated, .userInteractive: return true
            default: return false
            }
        case .default:
            switch rhs {
            case .userInitiated, .userInteractive: return true
            default: return false
            }
        case .userInitiated:
            return rhs == .userInteractive
        case .userInteractive:
            return false
        @unknown default:
            fatalError()
        }
    }
}

extension DispatchQoS: Comparable {
    public static func < (lhs: DispatchQoS, rhs: DispatchQoS) -> Bool {
        if lhs.qosClass < rhs.qosClass { return true }
        else if lhs.qosClass > rhs.qosClass { return false }
        else { // qosClass are equal
            return lhs.relativePriority < rhs.relativePriority
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

    var isOnScheduledQueue: Bool {
        guard let retrieved = DispatchQueue.getSpecific(key: key) else { return false }
        return value == retrieved
    }

    func isScheduledQueue(_ queue: DispatchQueue) -> Bool {
        guard let retrieved = queue.getSpecific(key: key) else { return false }
        return value == retrieved
    }
}

internal let mainQueueScheduler = Scheduler(queue: DispatchQueue.main)
