//
//  NetworkObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableNetworkActivityIndicator: NetworkActivityIndicatorInterface {
    typealias IndicatorVisibilityDidChange = (visibility: Bool) -> Void

    let visibilityDidChange: IndicatorVisibilityDidChange

    var networkActivityIndicatorVisible: Bool = false {
        didSet {
            visibilityDidChange(visibility: networkActivityIndicatorVisible)
        }
    }

    init(_ didChange: IndicatorVisibilityDidChange) {
        visibilityDidChange = didChange
    }
}

class NetworkObserverTests: OperationTests {

    var indicator: TestableNetworkActivityIndicator!
    var visibilityChanges = Array<Bool>()

    override func setUp() {
        super.setUp()
        indicator = TestableNetworkActivityIndicator { visibility in
            self.visibilityChanges.append(visibility)
        }
    }

    override func tearDown() {
        indicator = nil
        visibilityChanges.removeAll()
        super.tearDown()
    }

    func test__network_indicator_shows_when_operation_starts() {

        let operation = TestOperation(delay: 1)
        operation.addObserver(NetworkObserver(indicator: indicator))

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)

        waitForExpectations(withTimeout: 3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.isFinished)
            XCTAssertTrue(self.visibilityChanges[0])
        }
    }

    func test__network_indicator_hides_after_short_delay_when_operation_ends() {

        let expectation = self.expectation(withDescription: "Test: \(#function)")
        let operation = TestOperation(delay: 1)
        operation.addObserver(NetworkObserver(indicator: indicator))

        operation.addCompletionBlock {
            let after = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            Queue.main.queue.after(when: after) {
                expectation.fulfill()
            }
        }

        runOperation(operation)

        waitForExpectations(withTimeout: 3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.isFinished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertFalse(self.visibilityChanges[1])
        }
    }

    func test__network_indicator_changes_once_when_multiple_operations_start() {

        let operation1 = TestOperation(delay: 1)
        operation1.addObserver(NetworkObserver(indicator: indicator))

        let operation2 = TestOperation(delay: 1)
        operation2.addObserver(NetworkObserver(indicator: indicator))

        addCompletionBlockToTestOperation(operation1, withExpectation: expectation(withDescription: "Test: \(#function)"))
        addCompletionBlockToTestOperation(operation2, withExpectation: expectation(withDescription: "Test: \(#function)"))

        runOperations(operation1, operation2)

        waitForExpectations(withTimeout: 3) { error in
            XCTAssertTrue(operation1.didExecute)
            XCTAssertTrue(operation1.isFinished)
            XCTAssertTrue(operation2.didExecute)
            XCTAssertTrue(operation2.isFinished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertEqual(self.visibilityChanges.count, 1)
        }
    }

    func test__network_indicator_hides_once_multiple_operations_end() {

        let operation1 = TestOperation(delay: 1)
        operation1.addObserver(NetworkObserver(indicator: indicator))

        let operation2 = TestOperation(delay: 1)
        operation2.addObserver(NetworkObserver(indicator: indicator))

        let expectation1 = expectation(withDescription: "Test: \(#function)")
        operation1.addCompletionBlock {
            let after = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            Queue.main.queue.after(when: after) {
                expectation1.fulfill()
            }
        }
        let expectation2 = expectation(withDescription: "Test: \(#function)")
        operation2.addCompletionBlock {
            let after = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            Queue.main.queue.after(when: after) {
                expectation2.fulfill()
            }
        }

        runOperations(operation1, operation2)

        waitForExpectations(withTimeout: 3) { error in
            XCTAssertTrue(operation1.didExecute)
            XCTAssertTrue(operation1.isFinished)
            XCTAssertTrue(operation2.didExecute)
            XCTAssertTrue(operation2.isFinished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertFalse(self.visibilityChanges[1])
            XCTAssertEqual(self.visibilityChanges.count, 2)
        }
    }
}
