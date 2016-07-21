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
    
    let URL = Foundation.URL(string: "https://github.com")!
    var presentingController: TestablePresentingController!
    
    override func setUp() {
        super.setUp()
        presentingController = TestablePresentingController()
    }
    
    func test__operation_presents_safari_view_controller() {
        var didPresentWebpage = false
        let operation = OpenInSafariOperation(URL: URL, displayControllerFrom: .ShowDetail(presentingController))
        operation.shouldOpenInSafariViewController = { true }
        
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
    
    func test__operation_did_open_url_in_safari_app() {
        let expectation = self.expectation(description: "Test: \(#function)")
        
        var didOpenURL: Foundation.URL? = .none
        let operation = OpenInSafariOperation(URL: URL, displayControllerFrom: .ShowDetail(presentingController))
        operation.shouldOpenInSafariViewController = { false }
        operation.openURL = {
            expectation.fulfill()
            didOpenURL = $0
        }
        
        runOperation(operation)
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue(URL == didOpenURL)
    }
}
