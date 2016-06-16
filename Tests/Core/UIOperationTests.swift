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

    var check: CheckBlockType? = .none
    var expectation: XCTestExpectation? = .none

    func presentViewController(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        check?(received: vc)
        completion?()
        expectation?.fulfill()
    }

    func showViewController(_ vc: UIViewController, sender: AnyObject?) {
        check?(received: vc)
        expectation?.fulfill()
    }

    func showDetailViewController(_ vc: UIViewController, sender: AnyObject?) {
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
        style = .show(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__show_details_style_returns_controller() {
        style = .showDetail(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__present_style_returns_controller() {
        style = .present(controller)
        XCTAssertEqual(controller, style.controller)
    }

    func test__show_display_controller() {
        controller.check = { received in
            XCTAssertEqual(received, self.other)
        }

        style = .show(controller)
        style.displayController(other, sender: .none)
    }

    func test__show_detail_display_controller() {
        controller.check = { received in
            XCTAssertEqual(received, self.other)
        }

        style = .showDetail(controller)
        style.displayController(other, sender: .none)
    }

    func test__present_display_controller() {
        controller.check = { received in
            guard let nav = received as? UINavigationController else {
                XCTFail("Should have received a UINavigationController")
                return
            }
            XCTAssertEqual(nav.topViewController, self.other)
        }

        style = .present(controller)
        style.displayController(other, sender: .none)
    }

    func test__present_display_controller_navigation_controller_wrapping_can_be_overridden() {
        controller.check = { received in
            guard let _ = received as? UINavigationController else {
                XCTAssertEqual(received, self.other)
                return
            }
            XCTFail("Should not have received a UINavigationController")
        }

        style = .present(controller)
        style.displayController(other, inNavigationController: false, sender: .none)
    }

    func test__present_display_alert_controller() {
        let alert = UIAlertController()
        controller.check = { received in
            XCTAssertEqual(received, alert)
        }

        style = .present(controller)
        style.displayController(alert, sender: .none)
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
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        var completionBlockDidRun = false
        operation = TypeUnderTest(controller: presented, displayControllerFrom: .present(presenter), sender: .none)
        operation.addCompletionBlock {
            completionBlockDidRun = true
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(completionBlockDidRun)
    }

    func test__presents_with_navigation_controller_wrapping_by_default() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        presenter.check = { [unowned self] received in
            guard let nav = received as? UINavigationController else {
                XCTFail("Should have received a UINavigationController")
                return
            }
            XCTAssertEqual(nav.topViewController, self.presented)
            expectation.fulfill()
        }

        operation = TypeUnderTest(controller: presented, displayControllerFrom: .present(presenter), sender: .none)
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)
    }


    func test__presents_without_navigation_controller_when_wrapping_overridden() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        presenter.check = { [unowned self] received in
            guard let _ = received as? UINavigationController else {
                XCTAssertEqual(received, self.presented)
                expectation.fulfill()
                return
            }
            XCTFail("Should not have received a UINavigationController")
        }

        operation = TypeUnderTest(controller: presented, displayControllerFrom: .present(presenter), inNavigationController: false, sender: .none)
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)
    }
}
