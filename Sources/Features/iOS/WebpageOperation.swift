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
public class WebpageOperation<From: PresentingViewController>: GroupOperation, SFSafariViewControllerDelegate {

    var operation: UIOperation<SFSafariViewController, From>
    
    public init(url: NSURL, displayControllerFrom from: ViewControllerDisplayStyle<From>, entersReaderIfAvailable: Bool = true, sender: AnyObject? = .None) {
        operation = UIOperation(controller: SFSafariViewController(URL: url, entersReaderIfAvailable: entersReaderIfAvailable), displayControllerFrom: from, sender: sender)
        super.init(operations: [operation])
        
        addObserver(WillExecuteObserver() { [weak self] _ in
            self?.operation.controller.delegate = self
        })
        
        addCondition(MutuallyExclusive<UIViewController>())
    }

    @objc public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true) {
            self.finish()
        }
    }
}
