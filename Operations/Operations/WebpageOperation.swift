//
//  WebpageOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import SafariServices

@available(iOS 9.0, *)
public protocol WebpageController: class {
    weak var delegate: SFSafariViewControllerDelegate? { get set }
    init(URL: NSURL, entersReaderIfAvailable: Bool)
}

@available(iOS 9.0, *)
public class WebpageOperation<F: PresentingViewController>: Operation, SFSafariViewControllerDelegate {

    let operation: UIOperation<SFSafariViewController, F>

    public init(url: NSURL, displayControllerFrom from: ViewControllerDisplayStyle<F>, sender: AnyObject? = .None, completion: (() -> Void)? = .None) {
        operation = UIOperation(controller: SFSafariViewController(URL: url, entersReaderIfAvailable: true), displayControllerFrom: from, sender: sender, completion: completion)
        super.init()
        addCondition(MutuallyExclusive<UIViewController>())
    }

    public override func execute() {
        operation.controller.delegate = self
        produceOperation(operation)
    }
    
    @objc public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true) {
            self.finish()
        }
    }
}

