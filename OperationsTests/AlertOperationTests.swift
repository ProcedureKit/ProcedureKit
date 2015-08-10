//
//  BlockConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class TestablePresentingController: PresentingViewController {
    typealias CheckBlockType = (String?, String?) -> Void

    var check: CheckBlockType? = .None
    var expectation: XCTestExpectation? = .None

    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if let alertController = viewController as? UIAlertController {
            check?(alertController.title, alertController.message)
            expectation?.fulfill()
        }
    }
}

class AlertOperationTests: OperationTests {

    var presentingController: TestablePresentingController!

    override func setUp() {
        super.setUp()
        presentingController = TestablePresentingController()
    }

    func test__alert_operation_presents_alert_controller() {

        var didPresentAlert = false
        let alert = AlertOperation(presentFromController: presentingController)
        alert.title = "This is the alert title"
        alert.message = "This is the alert message"

        presentingController.expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        presentingController.check = { (title, message) in
            XCTAssertTrue(title == alert.title)
            XCTAssertTrue(message == alert.message)
            didPresentAlert = true
        }

        runOperation(alert)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(didPresentAlert)
    }

}

