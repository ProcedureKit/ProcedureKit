//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Dispatch

// MARK: - Queue

public extension DispatchQueue {

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
}
