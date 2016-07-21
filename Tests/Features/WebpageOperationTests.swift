//
//  WebpageOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import SafariServices
@testable import Operations

@available(iOS 9.0, *)
class TestableSafariViewController: SFSafariViewController {

    var controllerDidDismiss = false

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        controllerDidDismiss = true
        super.dismiss(animated: flag, completion: completion)
    }
}

@available(iOS 9.0, *)
class WebpageOperationTests: OperationTests {

    let url = URL(string: "https://github.com")!
    var presentingController: TestablePresentingController!

    override func setUp() {
        super.setUp()
        presentingController = TestablePresentingController()
    }

    func test__operation_presents_safari_view_controller() {
        var didPresentWebpage = false
        let operation = WebpageOperation(url: url, displayControllerFrom: .showDetail(presentingController))

        presentingController.expectation = expectation(description: "Test: \(#function)")
        presentingController.check = { received in
            if let safariViewController = received as? SFSafariViewController {
                didPresentWebpage = true
                if let delegate = safariViewController.delegate {
                    delegate.safariViewControllerDidFinish?(safariViewController)
                }
                else {
                    XCTFail("Delegate not set on the SFSafariViewController.")
                }
            }
            else {
                XCTFail("Did not receive a SFSafariViewController.")
            }
        }

        runOperation(operation)

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue(didPresentWebpage)
    }
}
