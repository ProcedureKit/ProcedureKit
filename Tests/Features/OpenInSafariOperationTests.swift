//
//  OpenInSafariOperationTests.swift
//  Operations
//
//  Created by Andreas Braun on 14.05.16.
//
//

import XCTest
import SafariServices
@testable import Operations

class OpenInSafariOperationTests: OperationTests {
    
    let URL = NSURL(string: "https://github.com")!
    var presentingController: TestablePresentingController!
    
    override func setUp() {
        super.setUp()
        presentingController = TestablePresentingController()
    }
    
    func test__operation_presents_safari_view_controller() {
        var didPresentWebpage = false
        let operation = OpenInSafariOperation(URL: URL, displayControllerFrom: .ShowDetail(presentingController))
        operation.shouldOpenInSafariViewController = { true }
        
        presentingController.expectation = expectationWithDescription("Test: \(#function)")
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
        
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(didPresentWebpage)
    }
    
    func test__operation_did_open_url_in_safari_app() {
        let expectation = expectationWithDescription("Test: \(#function)")
        
        var didOpenURL: NSURL? = .None
        let operation = OpenInSafariOperation(URL: URL, displayControllerFrom: .ShowDetail(presentingController))
        operation.shouldOpenInSafariViewController = { false }
        operation.openURL = {
            expectation.fulfill()
            didOpenURL = $0
        }
        
        runOperation(operation)
        
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(URL == didOpenURL)
    }
}