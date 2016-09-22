//
//  URLSessionTaskOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation


/**
An Operation which is a simple wrapper around `NSURLSessionTask`.

Note that the task will still need to be configured with a delegate
as usual. Typically this operation would be used after the task is
setup, so that conditions or observers can be attached.

*/
public class URLSessionTaskOperation: Operation {
    public private(set) var task: NSURLSessionTask!

    private override init() {
        super.init()
    }

    // Deprecated init
    @available(*, unavailable, message="URLSessionTaskOperation has been refactored to utilize factory methods that create the task and the operation.")
    public init(task: NSURLSessionTask) {
        super.init()
    }

    // MARK: - Factory Methods

    // MARK: -- Data Tasks

    public static func dataTask(fromSession session: NSURLSession, withURL url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithCompletionHandler()
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            completionHandler(data, response, error)
            op.finish(error)
        }
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    public static func dataTask(fromSession session: NSURLSession, withRequest request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithCompletionHandler()
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            completionHandler(data, response, error)
            op.finish(error)
        }
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }
    
    // without completion handler

    public static func dataTask(fromSession session: NSURLSession, withURL url: NSURL) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithoutCompletionHandler(session: session)
        let task = session.dataTaskWithURL(url)
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    public static func dataTask(fromSession session: NSURLSession, withRequest request: NSURLRequest) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithoutCompletionHandler(session: session)
        let task = session.dataTaskWithRequest(request)
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    // MARK: -- Download Tasks

    public static func downloadTask(fromSession session: NSURLSession, withURL url: NSURL, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithCompletionHandler()
        let task = session.downloadTaskWithURL(url) { (location, response, error) in
            completionHandler(location, response, error)
            op.finish(error)
        }
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    public static func downloadTask(fromSession session: NSURLSession, withRequest request: NSURLRequest, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithCompletionHandler()
        let task = session.downloadTaskWithRequest(request) { (location, response, error) in
            completionHandler(location, response, error)
            op.finish(error)
        }
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    // without completion handler

    public static func downloadTask(fromSession session: NSURLSession, withURL url: NSURL) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithoutCompletionHandler(session: session)
        let task = session.downloadTaskWithURL(url)
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }

    public static func downloadTask(fromSession session: NSURLSession, withRequest request: NSURLRequest) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperationWithoutCompletionHandler(session: session)
        let task = session.downloadTaskWithRequest(request)
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        op.task = task
        op.addObserver(DidCancelObserver { _ in
            task.cancel()
        })
        return op
    }
}

// For URLSessionTasks with a completion handler, we can properly handle finishing the operation 
// by utilizing the completion handler. So this is pretty simple:
internal class URLSessionTaskOperationWithCompletionHandler: URLSessionTaskOperation {
    override func execute() {
        assert(task.state == .Suspended, "NSURLSessionTask resumed outside of \(self)")
        task.resume()
    }
}

// For URLSessionTasks *without* a completion handler, we must: 
// 1.) Use KVO to determine when the task is finished
// 2.) Dispatch the call to `finish()` to the NSURLSession's delegateQueue
internal class URLSessionTaskOperationWithoutCompletionHandler: URLSessionTaskOperation {

    enum KeyPath: String {
        case State = "state"
    }

    private var removedObserved = false
    private let lock = NSLock()
    private var sessionDelegateQueue: NSOperationQueue
    
    init(session: NSURLSession) {
        self.sessionDelegateQueue = session.delegateQueue
        super.init()
    }

    internal override func execute() {
        assert(task.state == .Suspended, "NSURLSessionTask resumed outside of \(self)")
        task.addObserver(self, forKeyPath: KeyPath.State.rawValue, options: [], context: &URLSessionTaskOperationKVOContext)
        task.resume()
    }

    internal override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaskOperationKVOContext else { return }

        lock.withCriticalScope {
            if object === task && keyPath == KeyPath.State.rawValue && !removedObserved {

                if case .Completed = task.state {
                    sessionDelegateQueue.addOperation(NSBlockOperation { [unowned self] in
                        self.finish(self.task.error)
                    })
                }

                switch task.state {
                case .Completed, .Canceling:
                    task.removeObserver(self, forKeyPath: KeyPath.State.rawValue)
                    removedObserved = true
                default:
                    break
                }
            }
        }
    }
}

// swiftlint:disable variable_name
private var URLSessionTaskOperationKVOContext = 0
// swiftlint:enable variable_name
