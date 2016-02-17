//
//  UIOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import XCTest
@testable import Operations

class TestablePresentingController: NSObject, PresentingViewController {
    typealias CheckBlockType = (received: UIViewController) -> Void

    var check: CheckBlockType? = .None
    var expectation: XCTestExpectation? = .None

    func presentViewController(vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        check?(received: vc)
        completion?()
        expectation?.fulfill()
    }

    func showViewController(vc: UIViewController, sender: AnyObject?) {
        check?(received: vc)
        expectation?.fulfill()
    }

    func showDetailViewController(vc: UIViewController, sender: AnyObject?) {
        check?(received: vc)
        expectation?.fulfill()
    }
}

class ViewControllerDisplayStyleTests: XCTestCase {

    let controller = TestablePresentingController()
    var other: UIViewController!
    var style: ViewControllerDisplayStyle<TestablePresentingController>!

    override func setUp() {
        super.setUp()
        other = UIViewController()
    }

    override func tearDown() {
        other = nil
        super.tearDown()
    }

    func test__show_style_returns_controller() {
        style = .Show(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__show_details_style_returns_controller() {
        style = .ShowDetail(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__present_style_returns_controller() {
        style = .Present(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__show_display_controller() {
        controller.check = { received in
            XCTAssertEqual(received, self.other)
        }

        style = .Show(controller)
        style.displayController(other, sender: .None)
    }

    func test__show_detail_display_controller() {
        controller.check = { received in
            XCTAssertEqual(received, self.other)
        }

        style = .ShowDetail(controller)
        style.displayController(other, sender: .None)
    }

    func test__present_display_controller() {
        controller.check = { received in
            guard let nav = received as? UINavigationController else {
                XCTFail("Should have received a UINavigationController")
                return
            }
            XCTAssertEqual(nav.topViewController, self.other)
        }

        style = .Present(controller)
        style.displayController(other, sender: .None)
    }

    func test__present_display_alert_controller() {
        let alert = UIAlertController()
        controller.check = { received in
            XCTAssertEqual(received, alert)
        }

        style = .Present(controller)
        style.displayController(alert, sender: .None)
    }
}

class UIOperationTests: OperationTests {

    typealias TypeUnderTest = UIOperation<UIViewController, TestablePresentingController>

    var presenter: TestablePresentingController!
    var presented: UIViewController!

    var operation: UIOperation<UIViewController, TestablePresentingController>!

    override func setUp() {
        super.setUp()
        presenter = TestablePresentingController()
        presented = UIViewController()
    }

    override func tearDown() {
        presenter = nil
        presented = nil
        super.tearDown()
    }
    
    func test__presents() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        var completionBlockDidRun = false
        operation = TypeUnderTest(controller: presented, displayControllerFrom: .Present(presenter), sender: .None)
        operation.addCompletionBlock {
            completionBlockDidRun = true
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(completionBlockDidRun)

    }
}




