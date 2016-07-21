//
//  URLSessionTaskOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation


/**
An OldOperation which is a simple wrapper around `NSURLSessionTask`.

Note that the task will still need to be configured with a delegate
as usual. Typically this operation would be used after the task is
setup, so that conditions or observers can be attached.

*/
public class URLSessionTaskOperation: OldOperation {

    enum KeyPath: String {
        case State = "state"
    }

    public let task: URLSessionTask

    private var removedObserved = false
    private let lock = Foundation.Lock()

    public init(task: URLSessionTask) {
        assert(task.state == .suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        self.task = task
        super.init()
        addObserver(DidCancelObserver { _ in
            task.cancel()
        })
    }

    public override func execute() {
        assert(task.state == .suspended, "NSURLSessionTask resumed outside of \(self)")
        task.addObserver(self, forKeyPath: KeyPath.State.rawValue, options: [], context: &URLSessionTaskOperationKVOContext)
        task.resume()
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &URLSessionTaskOperationKVOContext else { return }

        lock.withCriticalScope {
            if object === task && keyPath == KeyPath.State.rawValue && !removedObserved {

                if case .completed = task.state {
                    finish(task.error)
                }

                switch task.state {
                case .completed, .canceling:
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
