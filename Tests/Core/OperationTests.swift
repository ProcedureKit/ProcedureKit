//
//  OperationTests.swift
//  OperationTests
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestOperation: Operation, ResultOperationType {

    enum Error: ErrorType {
        case SimulatedError
    }

    let numberOfSeconds: Double
    let simulatedError: ErrorType?
    let producedOperation: NSOperation?
    var didExecute: Bool = false
    var result: String? = "Hello World"

    var operationWillFinishCalled = false
    var operationDidFinishCalled = false
    var operationWillCancelCalled = false
    var operationDidCancelCalled = false

    init(delay: Double = 0.0001, error: ErrorType? = .None, produced: NSOperation? = .None) {
        numberOfSeconds = delay
        simulatedError = error
        producedOperation = produced
        super.init()
        name = "Test Operation"
    }

    override func execute() {

        if let producedOperation = self.producedOperation {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(numberOfSeconds * Double(0.001) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                self.produceOperation(producedOperation)
            }
        }

        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(numberOfSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Main.queue) {
            self.didExecute = true
            self.finish(self.simulatedError)
        }
    }

    override func operationWillFinish(errors: [ErrorType]) {
        operationWillFinishCalled = true
    }

    override func operationDidFinish(errors: [ErrorType]) {
        operationDidFinishCalled = true
    }

    override func operationWillCancel(errors: [ErrorType]) {
        operationWillCancelCalled = true
    }

    override func operationDidCancel() {
        operationDidCancelCalled = true
    }
}

struct TestCondition: OperationCondition {

    var name: String = "Test Condition"
    var isMutuallyExclusive = false
    let dependency: NSOperation?
    let condition: () -> Bool

    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return dependency
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(condition() ? .Satisfied : .Failed(BlockCondition.Error.BlockConditionFailed))
    }
}

class TestConditionOperation: Condition {

    let evaluate: () throws -> Bool

    init(dependencies: [NSOperation]? = .None, evaluate: () throws -> Bool) {
        self.evaluate = evaluate
        super.init()
        if let dependencies = dependencies {
            addDependencies(dependencies)
        }
    }

    override func evaluate(operation: Operation, completion: CompletionBlockType) {
        do {
            let success = try evaluate()
            completion(success ? .Satisfied : .Failed(OperationError.ConditionFailed))
        }
        catch {
            completion(.Failed(error))
        }
    }
}

class TestQueueDelegate: OperationQueueDelegate {

    typealias FinishBlockType = (NSOperation, [ErrorType]) -> Void

    let willFinishOperation: FinishBlockType?
    let didFinishOperation: FinishBlockType?

    var did_willAddOperation: Bool = false
    var did_operationWillFinish: Bool = false
    var did_operationDidFinish: Bool = false
    var did_willProduceOperation: Bool = false
    var did_numberOfErrorThatOperationDidFinish: Int = 0

    init(willFinishOperation: FinishBlockType? = .None, didFinishOperation: FinishBlockType? = .None) {
        self.willFinishOperation = willFinishOperation
        self.didFinishOperation = didFinishOperation
    }

    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        did_willAddOperation = true
    }

    func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        did_operationWillFinish = true
        did_numberOfErrorThatOperationDidFinish = errors.count
        willFinishOperation?(operation, errors)
    }

    func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        did_operationDidFinish = true
        did_numberOfErrorThatOperationDidFinish = errors.count
        didFinishOperation?(operation, errors)
    }
    
    func operationQueue(queue: OperationQueue, willProduceOperation operation: NSOperation) {
        did_willProduceOperation = true
    }
}

class OperationTests: XCTestCase {

    var queue: OperationQueue!
    var delegate: TestQueueDelegate!

    override func setUp() {
        super.setUp()
        LogManager.severity = .Fatal
        queue = OperationQueue()
        delegate = TestQueueDelegate()
        queue.delegate = delegate
    }

    override func tearDown() {
        queue.cancelAllOperations()
        queue = nil
        delegate = nil
        ExclusivityManager.sharedInstance.__tearDownForUnitTesting()
        LogManager.severity = .Warning
        super.tearDown()
    }

    func runOperation(operation: NSOperation) {
        queue.addOperation(operation)
    }

    func runOperations(operations: [NSOperation]) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func runOperations(operations: NSOperation...) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func waitForOperation(operation: Operation, withExpectationDescription text: String = #function) {
        addCompletionBlockToTestOperation(operation, withExpectationDescription: text)
        queue.delegate = delegate
        queue.addOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func waitForOperations(operations: Operation..., withExpectationDescription text: String = #function) {
        for (i, op) in operations.enumerate() {
            addCompletionBlockToTestOperation(op, withExpectationDescription: "\(i), \(text)")
        }
        queue.delegate = delegate
        queue.addOperations(operations, waitUntilFinished: false)
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func addCompletionBlockToTestOperation(operation: Operation, withExpectation expectation: XCTestExpectation) {
        weak var weakExpectation = expectation
        operation.addObserver(DidFinishObserver { _, _ in
            weakExpectation?.fulfill()
        })
    }

    func addCompletionBlockToTestOperation(operation: Operation, withExpectationDescription text: String = #function) -> XCTestExpectation {
        let expectation = expectationWithDescription("Test: \(text), \(NSUUID().UUIDString)")
        operation.addObserver(DidFinishObserver { _, _ in
            expectation.fulfill()
        })
        return expectation
    }
}
