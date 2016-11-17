//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import SystemConfiguration

public class TestableNetworkReachability {
    typealias Reachability = String

    public var flags: SCNetworkReachabilityFlags = .reachable {
        didSet {
            delegate?.didChangeReachability(flags: flags)
        }
    }
    public var didStartNotifier = false
    public var didStopNotifier = false

    public var log: LoggerProtocol = Logger()
    public weak var delegate: NetworkReachabilityDelegate? = nil

    public init() { }
}

extension TestableNetworkReachability: NetworkReachability {

    public func startNotifier(onQueue queue: DispatchQueue) throws {
        log.notice(message: "Started Reachability Notifier")
        didStartNotifier = true
        delegate?.didChangeReachability(flags: flags)
    }

    public func stopNotifier() {
        log.notice(message: "Stopped Reachability Notifier")
        didStopNotifier = true
    }
}
