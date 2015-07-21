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
class WebpageOperation: Operation {

    let url: NSURL
    let presentingViewController: UIViewController?

    init(url: NSURL, presentingViewController: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) {
        self.url = url
        self.presentingViewController = presentingViewController
        super.init()
        addCondition(MutuallyExclusive<UIViewController>())
    }

    override func execute() {
        dispatch_async(Queue.Main.queue, showSafariViewController)
    }

    private func showSafariViewController() {
        if let presentingViewController = presentingViewController {
            let safari = SFSafariViewController(URL: url, entersReaderIfAvailable: true)
            safari.delegate = self
            presentingViewController.presentViewController(safari, animated: true, completion: nil)
        }
        else {
            finish()
        }
    }
}

@available(iOS 9.0, *)
extension WebpageOperation: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true) {
            self.finish()
        }
    }
}

