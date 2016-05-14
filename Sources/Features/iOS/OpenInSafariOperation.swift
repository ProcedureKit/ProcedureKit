//
//  OpenInSafariOperation.swift
//  Operations
//
//  Created by Andreas Braun on 14.05.16.
//
//

import Foundation
import UIKit

/**
 An Operation that opens a given URL in an SFSafariViewController (if the base iOS SDK supports it) or opens it in the Safari app.

 It implements the following behaviour:

 - If the current iOS version supports SFSafariViewController, it opens the provided URL in an SFSafariViewController using WebpageOperation.
 - If the app is the secondary app in a SplitView, it opens the provided URL in Safari as the primary app.
 - If the current iOS version does not support SFSafariViewController, it opens the URL the old school way.
 */

public class OpenInSafariOperation<From: PresentingViewController>: GroupOperation {
    /// The URL to open.
    public let URL: NSURL
    /// A flag that determines whether the `SFSafariViewController` should open the `URL` in reader mode or not.
    public var entersReaderIfAvailable: Bool
    /// The presenting `ViewControllerDisplayStyle`
    private let displayControllerFrom: ViewControllerDisplayStyle<From>
    /// The `AnyObject` sender.
    private let sender: AnyObject?
    /// A operation that decides what should happen.
    let decideOperation = DecideWhereToOpenOperation()

    /**
     Initializes an `OpenInSafariOperation` with a base `URL` and some optional customization.

     - parameter URL: The `URL` to open.
     - parameter displayControllerFrom: The presenting `ViewControllerDisplayStyle`.
     - parameter entersReaderIfAvailable: A flag that determines whether the `SFSafariViewController` should open the `URL` in reader mode or not.
     - parameter sender: The `AnyObject` sender.

     - returns: An `OpenInSafariOperation` object initialized with a `URL` and some optional custom settings.
     */
    public init(URL: NSURL, displayControllerFrom from: ViewControllerDisplayStyle<From>, entersReaderIfAvailable: Bool = false, sender: AnyObject? = .None) {
        self.URL = URL
        self.displayControllerFrom = from
        self.entersReaderIfAvailable = entersReaderIfAvailable
        self.sender = sender

        super.init(operations: [decideOperation])

        self.name = "Open in Safari"
    }

    public override func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && !cancelled, let decision = operation as? DecideWhereToOpenOperation {
            if decision.shouldOpenInSafariViewController {
                if #available(iOS 9.0, *) {
                    produceOperation(WebpageOperation(url: URL, displayControllerFrom: displayControllerFrom, sender: sender))
                }
            } else {
                produceOperation(OpenURLOperation(URL: URL))
            }
        }
    }
}

/**
 An `OpenURLOperation` object represents an `Operation` that opens a given `URL` in the Safari app.
 */
class OpenURLOperation: Operation {

    /// The `URL` that should be opend.
    let URL: NSURL

    /**
     Initializes an `OpenInSafariOperation` with a base `URL`.

     - parameter URL: The `NSURL` object which should be opend.
     */
    init(URL: NSURL) {
        self.URL = URL

        super.init()
        self.name = "Open URL"
    }

    override func execute() {
        UIApplication.sharedApplication().openURL(URL)

        finish()
    }
}

/**
 An `DecideWhereToOpenOperation` object represents an `Operation` that decides on some circumstances whether it's parent `OpenInSafariOperation` should open a `URL` in the `SFSafariViewController` or in the Safari app.
 */
class DecideWhereToOpenOperation: Operation {

    /// The property that tells the parent `OpenInSafariOperation` operation to perform a certain operation.
    var shouldOpenInSafariViewController: Bool = false

    override func execute() {
        if UIApplication.isFullscreenPresentation {
            if #available(iOS 9.0, *) {
                shouldOpenInSafariViewController = true
            } else {
                shouldOpenInSafariViewController = false
            }
        }

        finish()
    }
}

/// A private extension of UIApplication to check if the current app is opend in a SplitView.
private extension UIApplication {
    class var isFullscreenPresentation: Bool {
        get {
            if let window = self.sharedApplication().keyWindow {
                return CGRectEqualToRect(window.frame, window.screen.bounds)
            } else {
                return true
            }
        }
    }
}
