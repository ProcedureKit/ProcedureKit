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

    enum KeyPath: String {
        case State = "state"
    }

    public private(set) var task: NSURLSessionTask!

    public static func dataTask(fromSession session: NSURLSession, withURL url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperation()
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
        let op = URLSessionTaskOperation()
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

    public static func downloadTask(fromSession session: NSURLSession, withURL url: NSURL, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> URLSessionTaskOperation {
        let op = URLSessionTaskOperation()
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
        let op = URLSessionTaskOperation()
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

    private override init () {
        super.init()
    }

    @available(*, unavailable, message="URLSessionTaskOperation has been refactored to utilize factory methods that create the task and the operation.")
    public init(task: NSURLSessionTask) {
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        self.task = task
        super.init()
        addObserver(DidCancelObserver { _ in
            task.cancel()
        })
    }

    public override func execute() {
        assert(task.state == .Suspended, "NSURLSessionTask resumed outside of \(self)")
        task.resume()
    }
}

