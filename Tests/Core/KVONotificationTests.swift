//
//  KVONotificationTests.swift
//  Operations
//
//  Created by swiftlyfalling on 03/07/2016.
//  Copyright © 2016 swiftlyfalling. All rights reserved.
//
/*
    The MIT License (MIT)

    Copyright (c) 2016 swiftlyfalling

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
//

import XCTest
@testable import Operations

class OperationKVOTests: OperationTests {

    class NSOperationKVOObserver: NSObject {

        let operation: NSOperation
        private var removedObserved = false
        private var isFinishedBlock: (() -> Void)?

        enum KeyPath: String {
            case Cancelled = "isCancelled"
            case Asynchronous = "isAsynchronous"
            case Executing = "isExecuting"
            case Finished = "isFinished"
            case Ready = "isReady"
            case Dependencies = "dependencies"
            case QueuePriority = "queuePriority"
            case CompletionBlock = "completionBlock"
        }

        struct KeyPathSets {
            static let State = Set<String>([KeyPath.Cancelled.rawValue, KeyPath.Executing.rawValue, KeyPath.Finished.rawValue, KeyPath.Ready.rawValue])
        }

        struct KVONotification {
            let keyPath: String
            let time: NSTimeInterval
        }
        private var orderOfKVONotifications = Protector<[KVONotification]>([])


        init(operation: NSOperation, isFinishedBlock: (() -> Void)? = nil) {
            self.operation = operation
            self.isFinishedBlock = isFinishedBlock
            super.init()
            operation.addObserver(self, forKeyPath: KeyPath.Cancelled.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Asynchronous.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Executing.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Finished.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Ready.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Dependencies.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.QueuePriority.rawValue, options: [], context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.CompletionBlock.rawValue, options: [], context: &TestKVOOperationKVOContext)
        }

        deinit {
            operation.removeObserver(self, forKeyPath: KeyPath.Cancelled.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.Asynchronous.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.Executing.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.Finished.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.Ready.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.Dependencies.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.QueuePriority.rawValue)
            operation.removeObserver(self, forKeyPath: KeyPath.CompletionBlock.rawValue)
        }

        var observedKVO: [KVONotification] {
            return orderOfKVONotifications.read { array in return array }
        }

        func observedKVOFor(keyPaths: Set<String>) -> [KVONotification] {
            return observedKVO.filter({ (notification) -> Bool in
                keyPaths.contains(notification.keyPath)
            })
        }

        var frequencyOfKVOKeyPaths: [String: Int] {
            return observedKVO.reduce([:]) { (accu: [String: Int], element) in
                let keyPath = element.keyPath
                var accu = accu
                accu[keyPath] = accu[keyPath]?.successor() ?? 1
                return accu
            }
        }

        override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

            guard context == &TestKVOOperationKVOContext else {
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
                return
            }
            guard object === operation else { return }
            guard let keyPath = keyPath else { return }
            if let isFinishedBlock = self.isFinishedBlock where keyPath == KeyPath.Finished.rawValue {
                orderOfKVONotifications.write( { (array) -> Void in
                    array.append(KVONotification(keyPath: keyPath, time: NSDate().timeIntervalSinceReferenceDate))
                    }, completion: {
                        isFinishedBlock()   // write completion is executed on main queue
                })
            }
            else {
                orderOfKVONotifications.write { (array) -> Void in
                    array.append(KVONotification(keyPath: keyPath, time: NSDate().timeIntervalSinceReferenceDate))
                }
            }
        }
    }


    func test__nsoperation_kvo__operation_state_transition_from_initializing_to_pending() {
        let operation = TestOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        operation.willEnqueue() // trigger state transition from .Initializing -> .Pending
        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 0)    // should be no KVO notification on any NSOperation keyPaths for this internal state transition
    }

    func test__nsoperation_kvo__operation_state_transition_to_executing() {
        class NoFinishOperation: Operation {
            override func execute() {
                // do not finish
            }
        }
        let operation = NoFinishOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        operation.willEnqueue() // trigger state transition from .Initializing -> .Pending
        operation.start() // trigger state transition from .Pending -> .Executing

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // should be a single KVO notification for NSOperation keyPath "isExecuting" for this internal state transition
        XCTAssertEqual(observedKVO.count, 1)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
    }

    func test__nsoperation_kvo__operation_state_transition_to_executing_via_queue() {
        class NoFinishOperation: Operation {
            var didExecuteExpectation: XCTestExpectation
            init(didExecuteExpectation: XCTestExpectation) {
                self.didExecuteExpectation = didExecuteExpectation
                super.init()
            }
            override func execute() {
                didExecuteExpectation.fulfill()
                // do not finish
            }
        }
        let didExecuteExpectation = expectationWithDescription("Test: \(#function); DidExecute")
        let operation = NoFinishOperation(didExecuteExpectation: didExecuteExpectation)
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        runOperation(operation) // trigger state transition from .Initializing -> .Executing via the queue

        waitForExpectationsWithTimeout(5, handler: nil)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // should be a single KVO notification for NSOperation keyPath "isExecuting" for this internal state transition
        XCTAssertEqual(observedKVO.count, 1)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function); Did Complete Operation"))
        operation.finish()
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    private func verifyKVO_cancelledNotifications(observedKVO: [NSOperationKVOObserver.KVONotification]) -> (success: Bool, isReadyIndex: Int?, failureMessage: String?) {
        // ensure that the observedKVO contains:
        // "isReady", with at least one "isCancelled" before it
        if let isReadyIndex = observedKVO.indexOf({ $0.keyPath == NSOperationKVOObserver.KeyPath.Ready.rawValue }) {
            var foundIsCancelled = false
            guard isReadyIndex > 0 else {
                return (success: false, isReadyIndex: isReadyIndex, failureMessage: "Found isReady KVO notification, but no isCancelled beforehand.")
            }
            for idx in (0..<isReadyIndex) {
                if observedKVO[idx].keyPath == NSOperationKVOObserver.KeyPath.Cancelled.rawValue {
                    foundIsCancelled = true
                    break
                }
            }
            if foundIsCancelled {
                return (success: true, isReadyIndex: isReadyIndex, failureMessage: nil)
            }
            else {
                return (success: false, isReadyIndex: isReadyIndex, failureMessage: "Found isReady KVO notification, but no isCancelled beforehand.")
            }
        }
        else {
            return (success: false, isReadyIndex: nil, failureMessage: "Did not find isReady KVO notification")
        }
    }

    func test__nsoperation_kvo__operation_cancel_from_initialized() {
        let operation = TestOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        operation.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // NOTE: To fully match NSOperation, this should be 2 KVO notifications, in the order: isCancelled, isReady
        // Because Operation handles cancelled status internally *and* calls super.cancel (to trigger Ready status change),
        // a total of 3 KVO notifications are generated in the order: isCancelled, isCancelled, isReady
        XCTAssertGreaterThanOrEqual(observedKVO.count, 2)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)
    }

    func test__nsoperation_kvo__groupoperation_cancel_from_initialized() {
        let child = TestOperation(delay: 1.0)
        let group = GroupOperation(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: group)
        group.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // NOTE: To fully match NSOperation, this should be 2 KVO notifications, in the order: isCancelled, isReady
        // Because Operation handles cancelled status internally *and* calls super.cancel (to trigger Ready status change),
        // a total of 3 KVO notifications are generated in the order: isCancelled, isCancelled, isReady
        XCTAssertGreaterThanOrEqual(observedKVO.count, 2)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)
    }

    func test__nsoperation_kvo__groupoperation_child_cancel_from_initialized() {
        let child = TestOperation(delay: 1.0)
        let group = GroupOperation(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: child)
        group.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // NOTE: To fully match NSOperation, this should be 2 KVO notifications, in the order: isCancelled, isReady
        // Because Operation handles cancelled status internally *and* calls super.cancel (to trigger Ready status change),
        // a total of 3 KVO notifications are generated in the order: isCancelled, isCancelled, isReady
        XCTAssertGreaterThanOrEqual(observedKVO.count, 2)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)
    }

    func test__nsoperation_kvo__nsoperation_cancel_from_initialized() {
        let operation = NSBlockOperation { }
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        operation.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 2)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Cancelled.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Ready.rawValue)
    }

    func test__nsoperation_kvo__operation_cancelled_to_completion() {
        weak var expectationIsFinishedKVO = expectationWithDescription("Test: \(#function); Did Receive isFinished KVO Notification")
        let operation = TestOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation,
                                                 isFinishedBlock: {
                                                    guard let expectationIsFinishedKVO = expectationIsFinishedKVO else { return }
                                                    expectationIsFinishedKVO.fulfill()
        })
        operation.cancel()
        waitForOperation(operation)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        let keyPathFrequency = kvoObserver.frequencyOfKVOKeyPaths

        XCTAssertGreaterThanOrEqual(observedKVO.count, 3)

        // first three KVO notifications should contain isCancelled and isReady (in that order)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)

        // it is valid, but not necessary, for a cancelled operation to transition through isExecuting

        // last KVO notification should always be isFinished
        XCTAssertEqual(observedKVO.last?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue, "Notifications were: \(observedKVO)")

        // isFinished should only be sent once
        XCTAssertEqual(keyPathFrequency[NSOperationKVOObserver.KeyPath.Finished.rawValue], 1)
    }

    func test__nsoperation_kvo__groupoperation_cancelled_to_completion() {
        weak var expectationIsFinishedKVO = expectationWithDescription("Test: \(#function); Did Receive isFinished KVO Notification")
        let child = TestOperation(delay: 1.0)
        let group = GroupOperation(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: group,
                                                 isFinishedBlock: {
                                                    guard let expectationIsFinishedKVO = expectationIsFinishedKVO else { return }
                                                    expectationIsFinishedKVO.fulfill()
        })
        group.cancel()
        waitForOperation(group)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        let keyPathFrequency = kvoObserver.frequencyOfKVOKeyPaths

        XCTAssertGreaterThanOrEqual(observedKVO.count, 3)

        // first three KVO notifications should contain isCancelled and isReady (in that order)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)

        // it is valid, but not necessary, for a cancelled operation to transition through isExecuting

        // last KVO notification should always be isFinished
        XCTAssertEqual(observedKVO.last?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)

        // isFinished should only be sent once
        XCTAssertEqual(keyPathFrequency[NSOperationKVOObserver.KeyPath.Finished.rawValue], 1)
    }

    func test__nsoperation_kvo__operation_execute_to_completion() {
        weak var expectationIsFinishedKVO = expectationWithDescription("Test: \(#function); Did Receive isFinished KVO Notification")
        let operation = TestOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation,
                                                 isFinishedBlock: {
                                                    guard let expectationIsFinishedKVO = expectationIsFinishedKVO else { return }
                                                    expectationIsFinishedKVO.fulfill()
        })
        waitForOperation(operation)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 3)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 2)?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)
    }

    func test__nsoperation_kvo__groupoperation_execute_to_completion() {
        weak var expectationIsFinishedKVO = expectationWithDescription("Test: \(#function); Did Receive isFinished KVO Notification")
        let child = TestOperation(delay: 1.0)
        let group = GroupOperation(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: group,
                                                 isFinishedBlock: {
                                                    guard let expectationIsFinishedKVO = expectationIsFinishedKVO else { return }
                                                    expectationIsFinishedKVO.fulfill()
        })
        waitForOperation(group)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 3)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 2)?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)
    }

    func test__nsoperation_kvo__operation_execute_with_dependencies_to_completion() {
        weak var expectationIsFinishedKVO = expectationWithDescription("Test: \(#function); Did Receive isFinished KVO Notification")
        let delay = DelayOperation(interval: 0.1)
        let operation = TestOperation()
        let kvoObserver = NSOperationKVOObserver(operation: operation,
                                                 isFinishedBlock: {
                                                    guard let expectationIsFinishedKVO = expectationIsFinishedKVO else { return }
                                                    expectationIsFinishedKVO.fulfill()
        })
        operation.addDependency(delay)
        waitForOperations(delay, operation)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State.union([NSOperationKVOObserver.KeyPath.Dependencies.rawValue]))
        XCTAssertEqual(observedKVO.count, 6)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Ready.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Dependencies.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 2)?.keyPath, NSOperationKVOObserver.KeyPath.Ready.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 3)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 4)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 5)?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)
    }
}

extension CollectionType {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    func get(safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

private var TestKVOOperationKVOContext = 0
