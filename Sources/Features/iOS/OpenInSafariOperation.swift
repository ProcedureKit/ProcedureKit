//
//  OpenInSafariOperation.swift
//  Operations
//
//  Created by Andreas Braun on 14.05.16.
//
//

import Foundation
import UIKit

extension UIApplication {
    internal var isFullscreenPresentation: Bool {
        if let window = self.keyWindow {
            return CGRectEqualToRect(window.frame, window.screen.bounds)
        } else {
            return true
        }
    }
}

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

    internal var shouldOpenInSafariViewController: () -> Bool = { UIApplication.sharedApplication().isFullscreenPresentation }
    internal var openURL: NSURL -> Void = { UIApplication.sharedApplication().openURL($0) }

    /// The presenting `ViewControllerDisplayStyle`
    private let displayControllerFrom: ViewControllerDisplayStyle<From>
    /// The `AnyObject` sender.
    private let sender: AnyObject?

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
        self.entersReaderIfAvailable = entersReaderIfAvailable
        self.displayControllerFrom = from
        self.sender = sender
        super.init(operations: [])
        name = "Open in Safari"
    }

    public override func execute() {
        if #available(iOS 9.0, *), shouldOpenInSafariViewController() {
            addOperation(WebpageOperation(url: self.URL, displayControllerFrom: self.displayControllerFrom, sender: self.sender))
        } else {
            addOperation(BlockOperation { [unowned self] in self.openURL(self.URL) })
        }

        super.execute()
    }
}
