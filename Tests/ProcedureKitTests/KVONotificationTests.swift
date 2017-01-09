//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class KVOTests: ProcedureKitTestCase {

    class NSOperationKVOObserver: NSObject {

        let operation: Operation
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
            let time: TimeInterval
            let old: Any?
            let new: Any?
        }
        private var orderOfKVONotifications = Protector<[KVONotification]>([])

        convenience init(operation: Operation, finishingExpectation: XCTestExpectation) {
            self.init(operation: operation, isFinishedBlock: { [weak finishingExpectation] in
                DispatchQueue.main.async {
                    guard let finishingExpectation = finishingExpectation else { return }
                    finishingExpectation.fulfill()
                }
            })
        }

        init(operation: Operation, isFinishedBlock: (() -> Void)? = nil) {
            self.operation = operation
            self.isFinishedBlock = isFinishedBlock
            super.init()
            let options: NSKeyValueObservingOptions = [.old, .new]
            operation.addObserver(self, forKeyPath: KeyPath.Cancelled.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Asynchronous.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Executing.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Finished.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Ready.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.Dependencies.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.QueuePriority.rawValue, options: options, context: &TestKVOOperationKVOContext)
            operation.addObserver(self, forKeyPath: KeyPath.CompletionBlock.rawValue, options: options, context: &TestKVOOperationKVOContext)
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

        func observedKVOFor(_ keyPaths: Set<String>) -> [KVONotification] {
            return observedKVO.filter({ (notification) -> Bool in
                keyPaths.contains(notification.keyPath)
            })
        }

        var frequencyOfKVOKeyPaths: [String: Int] {
            return observedKVO.reduce([:]) { (accu: [String: Int], element) in
                let keyPath = element.keyPath
                var accu = accu
                accu[keyPath] = accu[keyPath]?.advanced(by: 1) ?? 1
                return accu
            }
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            guard context == &TestKVOOperationKVOContext else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            guard object as AnyObject? === operation else { return }
            guard let keyPath = keyPath else { return }
            if let isFinishedBlock = self.isFinishedBlock, keyPath == KeyPath.Finished.rawValue {
                orderOfKVONotifications.write( { (array) -> Void in
                    array.append(KVONotification(keyPath: keyPath, time: NSDate().timeIntervalSinceReferenceDate, old: change?[.oldKey], new: change?[.newKey]))
                }, completion: {
                    isFinishedBlock()   // write completion is executed on main queue
                })
            }
            else {
                orderOfKVONotifications.write { (array) -> Void in
                    array.append(KVONotification(keyPath: keyPath, time: NSDate().timeIntervalSinceReferenceDate, old: change?[.oldKey], new: change?[.newKey]))
                }
            }
        }
    }


    func test__nsoperation_kvo__procedure_state_transition_from_initializing_to_pending() {
        let kvoObserver = NSOperationKVOObserver(operation: procedure)
        procedure.willEnqueue(on: queue) // trigger state transition from .Initializing -> .Pending
        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 0)    // should be no KVO notification on any NSOperation keyPaths for this internal state transition
    }

    func test__nsoperation_kvo__procedure_state_transition_to_executing() {
        class NoFinishOperation: Procedure {
            override func execute() {
                // do not finish
            }
        }
        let procedure = NoFinishOperation()
        weak var expDidExecute = expectation(description: "")
        procedure.addDidExecuteBlockObserver { _ in
            DispatchQueue.main.async {
                expDidExecute?.fulfill()
            }
        }
        let kvoObserver = NSOperationKVOObserver(operation: procedure)
        procedure.willEnqueue(on: queue) // trigger state transition from .Initializing -> .WillEnqueue
        procedure.pendingQueueStart() // trigger state transition from .WillEnqueue -> .Pending
        procedure.start() // trigger state transition from .Pending -> .Executing

        waitForExpectations(timeout: 3, handler: nil)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // should be a single KVO notification for NSOperation keyPath "isExecuting" for this internal state transition
        XCTAssertEqual(observedKVO.count, 1, "ObservedKVO = \(observedKVO)")
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
    }

    func test__nsoperation_kvo__procedure_state_transition_to_executing_via_queue() {
        class NoFinishOperation: Procedure {
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
        let didFinishGroup = DispatchGroup()
        didFinishGroup.enter()
        let didExecuteExpectation = expectation(description: "Test: \(#function); DidExecute")
        let operation = NoFinishOperation(didExecuteExpectation: didExecuteExpectation)
        operation.addDidFinishBlockObserver { _, _ in
            didFinishGroup.leave()
        }
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        run(operation: operation) // trigger state transition from .Initializing -> .Executing via the queue

        waitForExpectations(timeout: 5, handler: nil)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // should be a single KVO notification for NSOperation keyPath "isExecuting" for this internal state transition
        XCTAssertEqual(observedKVO.count, 1)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)

        weak var expDidFinish = expectation(description: "Test: \(#function); Did Complete Operation")
        didFinishGroup.notify(queue: DispatchQueue.main, execute: {
            expDidFinish?.fulfill()
        })
        operation.finish()
        waitForExpectations(timeout: 5, handler: nil)
    }

    private func verifyKVO_cancelledNotifications(_ observedKVO: [NSOperationKVOObserver.KVONotification]) -> (success: Bool, isReadyIndex: Int?, failureMessage: String?) {
        // ensure that the observedKVO contains:
        // "isReady", with at least one "isCancelled" before it
        if let isReadyIndex = observedKVO.index(where: { $0.keyPath == NSOperationKVOObserver.KeyPath.Ready.rawValue }) {
            var foundIsCancelled = false
            guard isReadyIndex > 0 else {
                return (success: false, isReadyIndex: isReadyIndex, failureMessage: "Found isReady KVO notification, but no isCancelled beforehand.")
            }
            for idx in (0..<isReadyIndex) {
                if observedKVO[idx].keyPath == NSOperationKVOObserver.KeyPath.Cancelled.rawValue {
                    guard let newBool = observedKVO[idx].new as? Bool, newBool == true else { continue }
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

    func test__nsoperation_kvo__procedure_cancel_from_initialized() {
        let kvoObserver = NSOperationKVOObserver(operation: procedure)
        procedure.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        // NOTE: To fully match NSOperation, this should be 2 KVO notifications, in the order: isCancelled, isReady
        // Because Operation handles cancelled status internally *and* calls super.cancel (to trigger Ready status change),
        // a total of 3 KVO notifications are generated in the order: isCancelled, isCancelled, isReady
        XCTAssertGreaterThanOrEqual(observedKVO.count, 2)
        let cancelledVerifyResult = verifyKVO_cancelledNotifications(observedKVO)
        XCTAssertTrue(cancelledVerifyResult.success, cancelledVerifyResult.failureMessage!)
        XCTAssertLessThanOrEqual(cancelledVerifyResult.isReadyIndex ?? 0, 3)
    }

    func test__nsoperation_kvo__groupprocedure_cancel_from_initialized() {
        let child = TestProcedure()
        let group = GroupProcedure(operations: [child])
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

    func test__nsoperation_kvo__groupprocedure_child_cancel_from_initialized() {
        let child = TestProcedure(delay: 1.0)
        let group = GroupProcedure(operations: [child])
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
        let operation = BlockOperation { }
        let kvoObserver = NSOperationKVOObserver(operation: operation)
        operation.cancel()

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 2)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Cancelled.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Ready.rawValue)
    }

    func test__nsoperation_kvo__procedure_cancelled_to_completion() {
        let expectationIsFinishedKVO = expectation(description: "Test: \(#function); Did Receive isFinished KVO Notification")
        let kvoObserver = NSOperationKVOObserver(operation: procedure, finishingExpectation: expectationIsFinishedKVO)
        procedure.cancel()
        wait(for: procedure)

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

    func test__nsoperation_kvo__groupprocedure_cancelled_to_completion() {
        let expectationIsFinishedKVO = expectation(description: "Test: \(#function); Did Receive isFinished KVO Notification")
        let child = TestProcedure(delay: 1.0)
        let group = GroupProcedure(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: group, finishingExpectation: expectationIsFinishedKVO)
        group.cancel()
        wait(for: group)

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

    func test__nsoperation_kvo__procedure_execute_to_completion() {
        let expectationIsFinishedKVO = expectation(description: "Test: \(#function); Did Receive isFinished KVO Notification")
        let kvoObserver = NSOperationKVOObserver(operation: procedure, finishingExpectation: expectationIsFinishedKVO)
        wait(for: procedure)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 3)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 2)?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)
    }

    func test__nsoperation_kvo__groupprocedure_execute_to_completion() {
        let expectationIsFinishedKVO = expectation(description: "Test: \(#function); Did Receive isFinished KVO Notification")
        let child = TestProcedure(delay: 1.0)
        let group = GroupProcedure(operations: [child])
        let kvoObserver = NSOperationKVOObserver(operation: group, finishingExpectation: expectationIsFinishedKVO)
        wait(for: group)

        let observedKVO = kvoObserver.observedKVOFor(NSOperationKVOObserver.KeyPathSets.State)
        XCTAssertEqual(observedKVO.count, 3)
        XCTAssertEqual(observedKVO.get(safe: 0)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 1)?.keyPath, NSOperationKVOObserver.KeyPath.Executing.rawValue)
        XCTAssertEqual(observedKVO.get(safe: 2)?.keyPath, NSOperationKVOObserver.KeyPath.Finished.rawValue)
    }

    func test__nsoperation_kvo__procedure_execute_with_dependencies_to_completion() {
        let expectationIsFinishedKVO = expectation(description: "Test: \(#function); Did Receive isFinished KVO Notification")
        let delay = DelayProcedure(by: 0.1)
        let operation = TestProcedure()
        let kvoObserver = NSOperationKVOObserver(operation: operation, finishingExpectation: expectationIsFinishedKVO)
        operation.addDependency(delay)
        wait(for: delay, operation)

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

extension Collection where Indices.Iterator.Element == Index {
    // Returns the element at the specified index iff it is within bounds, otherwise nil.
    func get(safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

private var TestKVOOperationKVOContext = 0
