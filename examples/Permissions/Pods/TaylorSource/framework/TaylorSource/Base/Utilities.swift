//
//  Created by Daniel Thorpe on 21/04/2015.
//

import Foundation

// MARK: - Thread Safety & Locks

enum Queue {

    case Main, UserInteractive, UserInitiated, Default, Utility, Background

    private var id: Int {
        switch self {
        case .Main: return Int(qos_class_main().value)
        case .UserInteractive: return Int(QOS_CLASS_USER_INTERACTIVE.value)
        case .UserInitiated: return Int(QOS_CLASS_USER_INITIATED.value)
        case .Default: return Int(QOS_CLASS_DEFAULT.value)
        case .Utility: return Int(QOS_CLASS_UTILITY.value)
        case .Background: return Int(QOS_CLASS_BACKGROUND.value)
        }
    }

    internal var queue: dispatch_queue_t {
        switch self {
        case .Main: return dispatch_get_main_queue()
        default: return dispatch_get_global_queue(id, 0)
        }
    }
}

class Protector<T> {
    private var lock: ReadWriteLock = Lock()
    private var ward: T

    init(_ ward: T) {
        self.ward = ward
    }

    func read<U>(block: (T) -> U) -> U {
        return lock.read { [unowned self] in block(self.ward) }
    }

    func write(block: (inout T) -> Void, completion: (() -> Void)? = .None) {
        lock.write({
            block(&self.ward)
        }, completion: completion)
    }
}

protocol ReadWriteLock {
    mutating func read<T>(block: () -> T) -> T
    mutating func write(block: () -> ())
    // Execute a completion block asynchronously on a global queue.
    mutating func write(block: () -> (), completion: (() -> Void)?)
    // Note: synchronous write is deliberatly ommited as it blocks the queue
}

struct Lock: ReadWriteLock {

    let queue = dispatch_queue_create("me.danthorpe.lock", DISPATCH_QUEUE_CONCURRENT)

    mutating func read<T>(block: () -> T) -> T {
        var object: T?
        dispatch_sync(queue) {
            object = block()
        }
        return object!
    }

    mutating func write(block: () -> Void) {
        write(block, completion: nil)
    }

    mutating func write(block: () -> Void, completion: (() -> Void)? = .None) {
        dispatch_barrier_async(queue) {
            block()
            if let completion = completion {
                dispatch_async(Queue.Main.queue, completion)
            }
        }
    }
}

// MARK: - Notifications

class NotificationCenterHandler: NSObject {
    typealias Callback = (NSNotification) -> Void
    let name: String
    let callback: Callback

    init(name n: String, callback c: Callback) {
        name = n
        callback = c
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: name, object: .None)
    }

    func handleNotification(notification: NSNotification) {
        callback(notification)
    }
}

extension NSNotificationCenter {

    class func addObserverForName(name: String, object: AnyObject? = .None, withCallback callback: NotificationCenterHandler.Callback) -> NotificationCenterHandler {
        let handler = NotificationCenterHandler(name: name, callback: callback)
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(handler, name: name, object: object)
        center.addObserver(handler, selector: "handleNotification:", name: name, object: object)
        return handler
    }
}

// MARK: - Target/Action

public class TargetActionHandler: NSObject {
    public typealias Callback = (sender: AnyObject?) -> Void

    public class var selector: Selector {
        return "handleAction:"
    }

    private let callback: Callback

    public init(callback c: Callback) {
        callback = c
    }

    public func handleAction(sender: AnyObject?) {
        callback(sender: sender)
    }
}


