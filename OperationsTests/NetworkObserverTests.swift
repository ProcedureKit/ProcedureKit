//
//  NetworkObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
            XCTAssertTrue(self.visibilityChanges[0])
        }
    }

    func test__network_indicator_hides_after_short_delay_when_operation_ends() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addObserver(NetworkObserver(indicator: indicator))

        operation.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation.fulfill()
            }
        }

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertFalse(self.visibilityChanges[1])
        }
    }
}

#endif
