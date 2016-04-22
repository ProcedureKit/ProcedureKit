//
//  ActivityIndicatorViewObserverTests.swift
//  Operations
//
//  Created by Matthew Holden 16/04/2016.
//
//

import Foundation
import XCTest
@testable import Operations

enum AnimationState {
    case Animating
    case NotAnimating
}

class TestableActivityIndicatorView: ActivityIndicatorViewAnimationInterface {

    var animationStateChanges = [AnimationState]()

    func startAnimating() {
        animationStateChanges.append(.Animating)
    }

    func stopAnimating() {
        animationStateChanges.append(.NotAnimating)
    }
}


class ActivityIndicatorViewObserverTests: OperationTests {

    var operation: TestOperation!
    var indicator: TestableActivityIndicatorView!

    override func setUp() {
        super.setUp()
        operation = TestOperation()
        indicator = TestableActivityIndicatorView()
        operation.addObserver(ActivityIndicatorViewObserver(indicator))
    }

    override func tearDown() {
        operation = nil
        indicator = nil
        super.tearDown()
    }

    func test__activity_indicator_starts_animating__when_operation_starts() {
        addCompletionBlockToTestOperation(operation)

        var animationStateChangesBeforeWillFinish = 0
        var firstAnimationChangeState: AnimationState? = .None

        operation.addObserver(WillFinishObserver { [unowned self] _, _ in
                animationStateChangesBeforeWillFinish = self.indicator.animationStateChanges.count
                firstAnimationChangeState = self.indicator.animationStateChanges.first
            })

        waitForOperation(operation)
        XCTAssertTrue(self.operation.didExecute)
        XCTAssertTrue(self.operation.finished)

        XCTAssertEqual(animationStateChangesBeforeWillFinish, 1)
        XCTAssertTrue(firstAnimationChangeState == .Animating)
    }

    func test__activity_indicator_stops_animating__when_operation_stops() {

        let expectation = expectationWithDescription("Test: \(#function)")

        operation.addCompletionBlock {
            // ActivityIndicatorViewObserver will marshall its invocation of 
            // the indicator's `stopAnimating` method onto the main queue.
            // As such, we need to ensure we don't fulfill this test's expectations
            // until the run loop has had the opportunity to run one additional time.
            dispatch_async(Queue.Main.queue) {
                expectation.fulfill()
            }
        }

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { [unowned self] error in
            XCTAssertTrue(self.operation.didExecute)
            XCTAssertTrue(self.operation.finished)

            XCTAssertEqual(self.indicator.animationStateChanges.count, 2)

            XCTAssertTrue(self.indicator.animationStateChanges.first == .Animating)
            XCTAssertTrue(self.indicator.animationStateChanges.last == .NotAnimating)
        }

    }
}
