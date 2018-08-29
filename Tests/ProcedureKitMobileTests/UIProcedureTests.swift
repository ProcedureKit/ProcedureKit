//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class TestablePresentingController: NSObject, PresentingViewController {
    typealias CheckBlockType = (UIViewController) -> Void

    var check: CheckBlockType? = nil
    var expectation: XCTestExpectation? = nil

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        check?(viewControllerToPresent)
        completion?()
        expectation?.fulfill()
    }

    func show(_ viewControllerToShow: UIViewController, sender: Any?) {
        check?(viewControllerToShow)
        expectation?.fulfill()
    }

    func showDetailViewController(_ viewControllerToShow: UIViewController, sender: Any?) {
        check?(viewControllerToShow)
        expectation?.fulfill()
    }
}

class TestableDismissingViewController: UIViewController, DismissingViewController {
    var didDismissViewControllerBlock: () -> Void = { }

    func dismissTheViewController() {
        didDismissViewControllerBlock()
    }
}

class UIProcedureTests: ProcedureKitTestCase {

    var presenting: TestablePresentingController!
    var presented: TestableDismissingViewController!

    override func setUp() {
        super.setUp()
        presenting = TestablePresentingController()
        presented = TestableDismissingViewController()
    }

    override func tearDown() {
        presenting = nil
        presented = nil
        super.tearDown()
    }

    func checkReceivedViewController(inNavigationController: Bool) -> (UIViewController) -> Void {
        return {  [unowned self] received in
            if inNavigationController {
                guard let nav = received as? UINavigationController else {
                    XCTFail("Expected received view controller to be a UINavigationController")
                    return
                }
                XCTAssertEqual(nav.topViewController, self.presented)
            }
            else {
                XCTAssertEqual(received, self.presented)
            }
        }
    }

    func test__present_style() {
        presenting.check = checkReceivedViewController(inNavigationController: true)
        let ui = UIProcedure(present: presented, from: presenting, withStyle: .present, sender: nil)
        wait(for: ui)
        PKAssertProcedureFinished(ui)
    }

    func test__present_style_without_navigation_controller() {
        presenting.check = checkReceivedViewController(inNavigationController: false)
        let ui = UIProcedure(present: presented, from: presenting, withStyle: .present, inNavigationController: false, sender: nil)
        wait(for: ui)
        PKAssertProcedureFinished(ui)
    }

    func test__show_style() {
        presenting.check = checkReceivedViewController(inNavigationController: false)
        let ui = UIProcedure(present: presented, from: presenting, withStyle: .show, sender: nil)
        wait(for: ui)
        PKAssertProcedureFinished(ui)
    }

    func test__show_detail_style() {
        presenting.check = checkReceivedViewController(inNavigationController: false)
        let ui = UIProcedure(present: presented, from: presenting, withStyle: .showDetail, sender: nil)
        wait(for: ui)
        PKAssertProcedureFinished(ui)
    }

    func test__present_dismissing_view_controller() {
        presenting.check = checkReceivedViewController(inNavigationController: true)
        let ui = UIProcedure(present: presented, from: presenting, withStyle: .present, sender: nil, waitForDismissal: true)
        let delay = DelayProcedure(by: 0.1)
        let dismiss = BlockProcedure { [unowned self] in self.presented.dismissTheViewController() }
        dismiss.addDependency(delay)
        wait(for: ui, delay, dismiss)
        PKAssertProcedureFinished(ui)
    }
}
