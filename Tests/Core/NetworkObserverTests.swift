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
    var visibilityChanges: Array<Bool> {
        get {
            return _visibilityChanges.read { $0 }
        }
    }
    
    var _visibilityChanges = Protector<Array<Bool>>([])

    override func setUp() {
        super.setUp()
        indicator = TestableNetworkActivityIndicator { visibility in
            self._visibilityChanges.append(visibility)
        }
    }

    override func tearDown() {
        indicator = nil
        _visibilityChanges.write { (ward) in
            ward.removeAll()
        }
        super.tearDown()
    }

    func test__network_indicator_shows_when_operation_starts() {

        let operation = TestOperation(delay: 1)
        operation.addObserver(NetworkObserver(indicator: indicator))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
            XCTAssertTrue(self.visibilityChanges[0])
        }
    }

    func test__network_indicator_hides_after_short_delay_when_operation_ends() {

        let expectation = expectationWithDescription("Test: \(#function)")
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

    func test__network_indicator_changes_once_when_multiple_operations_start() {

        let operation1 = TestOperation(delay: 1)
        operation1.addObserver(NetworkObserver(indicator: indicator))

        let operation2 = TestOperation(delay: 1)
        operation2.addObserver(NetworkObserver(indicator: indicator))

        addCompletionBlockToTestOperation(operation1, withExpectation: expectationWithDescription("Test: \(#function)"))
        addCompletionBlockToTestOperation(operation2, withExpectation: expectationWithDescription("Test: \(#function)"))

        runOperations(operation1, operation2)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation1.didExecute)
            XCTAssertTrue(operation1.finished)
            XCTAssertTrue(operation2.didExecute)
            XCTAssertTrue(operation2.finished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertEqual(self.visibilityChanges.count, 1)
        }
    }

    func test__network_indicator_hides_once_multiple_operations_end() {

        let operation1 = TestOperation(delay: 1)
        operation1.addObserver(NetworkObserver(indicator: indicator))

        let operation2 = TestOperation(delay: 1)
        operation2.addObserver(NetworkObserver(indicator: indicator))

        let expectation1 = expectationWithDescription("Test: \(#function)")
        operation1.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation1.fulfill()
            }
        }
        let expectation2 = expectationWithDescription("Test: \(#function)")
        operation2.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation2.fulfill()
            }
        }

        runOperations(operation1, operation2)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation1.didExecute)
            XCTAssertTrue(operation1.finished)
            XCTAssertTrue(operation2.didExecute)
            XCTAssertTrue(operation2.finished)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertFalse(self.visibilityChanges[1])
            XCTAssertEqual(self.visibilityChanges.count, 2)
        }
    }
    
    func test__network_indicator_doesnt_disappear_before_all_operations_are_finished() {
        
        let timerInterval = 1.0     // the interval used inside NetworkIndicatorController for its Timer
        //
        // Definitions:
        //  timerInterval = the interval used inside NetworkIndicatorController for its Timer
        //
        // This test uses the following 3 operations to affect the NetworkIndicator:
        //
        //              [startTime]                                         [duration]
        // operation1   immediately                                         0.1 seconds
        // operation2   operation1.endTime + 0.1 seconds                    2 x timerInterval
        // operation3   operation1.endTime + timerInterval + (a bit extra)  0.1 seconds
        //
        // operation1
        //      - started immediately (by itself), triggers the network indicator, ends, and causes
        //        NetworkIndicatorController to queue a Timer to remove the network indicator
        // operation2
        //      - a "long-running" operation, starts after operation1 finishes, but before the 
        //        Timer that was queued as a result of operation1 finishing fires
        //      - this should result in the Timer being cancelled before it fires, and the network
        //        activity indicator remaining visible for the duration of operation2
        //        (operation2 is the last operation to finish)
        // operation3
        //      - a short operation that starts after operation2 is running, after the original Timer
        //        that operation1 triggered would have fired (if it weren't cancelled), and
        //        ends before operation2 is finished
        //      - this should not change the visible state of the network indicator, as it should still
        //        be visible (as a result of operation2)
        //
        // The expected output of this timing and sequence of operations is a network indicator that
        // shows at the start of operation1, and disappears "timerInterval" seconds after the end of
        // operation2. (i.e. 2 visibility changes: true, false)
        //
        // Previously, this test would fail by producing 4 visibility changes: (true, false, true, false)
        //
        
        let operation1 = TestOperation(delay: 0.1)
        operation1.name = "TestOperation1"
        operation1.addObserver(NetworkObserver(indicator: indicator))
        
        // the "long running" operation
        let operation2 = BlockOperation(block: { continuation in
            // operation2 is "busy" for 2x the timerInterval
            // this allows time for an errant NetworkObserver Timer that wasn't properly cancelled
            // to change the visibility to false prior to this operation finishing
            usleep(UInt32((timerInterval * 2.0) * 1000000.0))
            continuation(error: nil)
        })
        operation2.name = "TestOperation2"
        operation2.addObserver(NetworkObserver(indicator: indicator))
        
        // the operation that starts after the initial timer delay that *would* have set the indicator to invisible
        // (which should have been cancelled, and thus never executed)
        // if the Timer isn't properly cancelled, this will result in another cycle of:
        // indicator state = invisible -> visible -> invisible
        let operation3 = DelayOperation(interval: 0.1)
        operation3.name = "TestOperation3"
        operation3.addObserver(NetworkObserver(indicator: indicator))
        
        // the operation that starts operation3 after the initial timer delay
        // (does not have a NetworkObserver)
        let delayStartOperation3 = DelayOperation(interval: (timerInterval + 0.1))
        delayStartOperation3.name = "DelayForTestOperation3"
        operation3.addDependency(delayStartOperation3)
        
        operation1.addObserver(DidFinishObserver { (operation, errors) in
            dispatch_async(Queue.Initiated.queue, {
                let delayMicroseconds: useconds_t = 100000 // 0.1 seconds
                usleep(delayMicroseconds)
                // a short time after operation1 finishes (i.e. enough time for the NetworkIndicatorController to start a Timer to set the indicator to invisible), queue the following:
                // 1.) a long-running operation (operation2) which takes 2x the timerInterval to finish
                // 2.) a delayed operation (operation3), which starts (and triggers the NetworkObserver) after a delay greater than the timer interval (thus ensuring that if the first Timer was not properly cancelled, the indicator visibility will be set to false prior to operation3 starting)
                // 3.) the delay operation dependency of operation3 (delayStartOperation3)
                self.queue.addOperations([operation2, delayStartOperation3, operation3])
            })
        })
        
        let expectation1 = expectationWithDescription("Test: \(#function)")
        operation1.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64((timerInterval + 0.5) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation1.fulfill()
            }
        }
        let expectation2 = expectationWithDescription("Test: \(#function)")
        operation2.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64((timerInterval + 0.5) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation2.fulfill()
            }
        }
        let expectation3 = expectationWithDescription("Test: \(#function)")
        operation3.addCompletionBlock {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64((timerInterval + 0.5) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                expectation3.fulfill()
            }
        }
        
        queue.addOperation(operation1)
        
        waitForExpectationsWithTimeout((timerInterval + 0.5) * 3.0 + (timerInterval * 2.0)) { error in
            XCTAssertTrue(operation1.didExecute)
            XCTAssertTrue(operation1.finished)
            XCTAssertTrue(operation2.finished)
            XCTAssertEqual(self.visibilityChanges.count, 2)
            XCTAssertTrue(self.visibilityChanges[0])
            XCTAssertFalse(self.visibilityChanges[1])
        }
    }
    
    func test__network_indicator_timer_cancellation_prevents_handler_from_running() {
        // Test for: https://github.com/ProcedureKit/ProcedureKit/issues/344
        let interval = 0.4
        var ranHandler = false
        let timer = Timer(interval: interval) {
            ranHandler = true
        }
        timer.cancel()
        let expectation = expectationWithDescription("Test: \(#function)")
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64((interval + 0.1) * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Main.queue) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(ranHandler)
    }
}
