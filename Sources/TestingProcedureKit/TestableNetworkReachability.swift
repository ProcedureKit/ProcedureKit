//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import SystemConfiguration
import XCTest
import ProcedureKit

public class TestableNetworkReachability {
    typealias Reachability = String

    public var flags: SCNetworkReachabilityFlags {
        get { return stateLock.withCriticalScope { _flags } }
        set {
            stateLock.withCriticalScope {
                _flags = newValue
            }
        }
    }
    public var didStartNotifier: Bool {
        get { return stateLock.withCriticalScope { _didStartNotifier } }
        set {
            stateLock.withCriticalScope {
                _didStartNotifier = newValue
            }
        }
    }
    public var didStopNotifier: Bool {
        get { return stateLock.withCriticalScope { _didStopNotifier } }
        set {
            stateLock.withCriticalScope {
                _didStopNotifier = newValue
            }
        }
    }

    public var log: LoggerProtocol {
        get { return stateLock.withCriticalScope { _log } }
        set {
            stateLock.withCriticalScope {
                _log = newValue
            }
        }
    }
    public weak var delegate: NetworkReachabilityDelegate? {
        get { return stateLock.withCriticalScope { _delegate } }
        set {
            stateLock.withCriticalScope {
                _delegate = newValue
            }
        }
    }

    private var stateLock = NSRecursiveLock()
    private var _flags: SCNetworkReachabilityFlags = .reachable {
        didSet {
            delegate?.didChangeReachability(flags: flags)
        }
    }
    private var _didStartNotifier = false
    private var _didStopNotifier = false
    private var _log: LoggerProtocol = Logger()
    private weak var _delegate: NetworkReachabilityDelegate?

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
