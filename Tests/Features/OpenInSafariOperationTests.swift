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
        var didPresentWebpage = false
        let expectation = expectationWithDescription("Test: \(#function)")
        
        let operation = TestableOpenInSafariOperation(URL: URL, displayControllerFrom: .ShowDetail(presentingController))
        
        operation.decideOperation.addObserver(WillFinishObserver() { _, _ in
            operation.decideOperation.shouldOpenInSafariViewController = false
        })
        
        operation.didOpenURLBlock = { success in
            didPresentWebpage = true
            expectation.fulfill()
        }
        
        runOperation(operation)
        
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(didPresentWebpage)
    }
}

class TestableOpenInSafariOperation<From: PresentingViewController>: OpenInSafariOperation<From> {
    var didOpenURLBlock: (() -> Void)?
    
    // For some reason the compiler does not see the init.
    override init(URL: NSURL, displayControllerFrom from: ViewControllerDisplayStyle<From>? = .None, entersReaderIfAvailable: Bool = false, sender: AnyObject? = .None) {
        super.init(URL: URL, displayControllerFrom: from, entersReaderIfAvailable: entersReaderIfAvailable, sender: sender)
    }
    
    override func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && !cancelled, let _ = operation as? OpenURLOperation {
            didOpenURLBlock?()
        }
        
        super.willFinishOperation(operation, withErrors: errors)
    }
}
