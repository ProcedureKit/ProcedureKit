//
//  ActivityIndicatorViewObserver.swift
//  Operations
//
//  Created by Matthew Holden 16/04/2016.
//
//

import UIKit

public protocol ActivityIndicatorViewAnimationInterface {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: ActivityIndicatorViewAnimationInterface {}

/**
 An OperationObserverType that can update the state of an associated `UIActivityIndicatorView`
 when the observed operation starts and finishes.
 
 - note: Any type conforming to `ActivityIndicatorViewAnimationInterface` can be provided as 
         the activity indicator.
 */
public class ActivityIndicatorViewObserver: OperationDidStartObserver, OperationDidFinishObserver {

    private let activityIndicator: ActivityIndicatorViewAnimationInterface

    /**
     Initialize the observer with an `ActivityIndicatorViewAnimationInterface`-conforming type.
     - parameter activityIndicator: the object to start and stop animating
     - returns: an observer
     - note: The activity indicator's `startAninating` and `stopAnimating` methods 
             are guaranteed to execute on the main queue.
     */
    public init(activityIndicator: ActivityIndicatorViewAnimationInterface) {
        self.activityIndicator = activityIndicator
    }

    public func didStartOperation(operation: Operation) {
        dispatch_async(Queue.Main.queue) {
            self.activityIndicator.startAnimating()
        }
    }

    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        dispatch_async(Queue.Main.queue) {
            self.activityIndicator.stopAnimating()
        }
    }
}
