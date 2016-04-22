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
    typealias IndicatorAnimationStateDidChangeBlock =  (toState: AnimationState) -> Void

    let animationStateDidChange: IndicatorAnimationStateDidChangeBlock

    init(_ didChange: IndicatorAnimationStateDidChangeBlock) {
        animationStateDidChange = didChange
    }

    func startAnimating() {
        animationStateDidChange(toState: .Animating)
    }

    func stopAnimating() {
        animationStateDidChange(toState: .NotAnimating)
    }
}


class ActivityIndicatorViewObserverTests: OperationTests {

    var operation: TestOperation!
    var indicator: ActivityIndicatorViewAnimationInterface!
    var animationStateChanges: [AnimationState]!

    override func setUp() {
        super.setUp()
        animationStateChanges = [AnimationState]()
        operation = TestOperation()
        indicator = TestableActivityIndicatorView { [unowned self] animationState in
            self.animationStateChanges.append(animationState)
        }
        operation.addObserver(ActivityIndicatorViewObserver(activityIndicator: indicator))
    }

    override func tearDown() {
        operation = nil
        indicator = nil
        super.tearDown()
    }

    func test__activity_indicator_starts_animating__when_operation_starts() {
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))

        var animationStateChangesBeforeWillFinish = 0
        var firstAnimationChangeState: AnimationState? = .None

        operation.addObserver(WillFinishObserver { [unowned self] _, _ in
                animationStateChangesBeforeWillFinish = self.animationStateChanges.count
                firstAnimationChangeState = self.animationStateChanges.first
            })

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(self.operation.didExecute)
            XCTAssertTrue(self.operation.finished)

            XCTAssertEqual(animationStateChangesBeforeWillFinish, 1)
            XCTAssertTrue(firstAnimationChangeState == .Animating)
        }
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

            XCTAssertEqual(self.animationStateChanges.count, 2)

            XCTAssertTrue(self.animationStateChanges.first == .Animating)
            XCTAssertTrue(self.animationStateChanges.last == .NotAnimating)
        }

    }
}
