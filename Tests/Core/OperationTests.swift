//
//  OperationTests.swift
//  OperationTests
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestOperation: OldOperation, ResultOperationType {

    enum Error: ErrorProtocol {
        case simulatedError
    }

    let numberOfSeconds: Double
    let simulatedError: ErrorProtocol?
    let producedOperation: Operation?
    var didExecute: Bool = false
    var result: String? = "Hello World"

    var operationWillFinishCalled = false
    var operationDidFinishCalled = false
    var operationWillCancelCalled = false
    var operationDidCancelCalled = false

    init(delay: Double = 0.0001, error: ErrorProtocol? = .none, produced: Operation? = .none) {
        numberOfSeconds = delay
        simulatedError = error
        producedOperation = produced
        super.init()
        name = "Test OldOperation"
    }

    override func execute() {

        if let producedOperation = self.producedOperation {
            let after = DispatchTime.now() + Double(Int64(numberOfSeconds * Double(0.001) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            (Queue.main.queue).after(when: after) {
                self.produceOperation(producedOperation)
            }
        }

        let after = DispatchTime.now() + Double(Int64(numberOfSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        (Queue.main.queue).after(when: after) {
            self.didExecute = true
            self.finish(self.simulatedError)
        }
    }

    override func operationWillFinish(_ errors: [ErrorProtocol]) {
        operationWillFinishCalled = true
    }

    override func operationDidFinish(_ errors: [ErrorProtocol]) {
        operationDidFinishCalled = true
    }

    override func operationWillCancel(_ errors: [ErrorProtocol]) {
        operationWillCancelCalled = true
    }

    override func operationDidCancel() {
        operationDidCancelCalled = true
    }
}

struct TestCondition: OperationCondition {

    var name: String = "Test Condition"
    var isMutuallyExclusive = false
    let dependency: Operation?
    let condition: () -> Bool

    func dependencyForOperation(_ operation: OldOperation) -> Operation? {
        return dependency
    }

    func evaluateForOperation(_ operation: OldOperation, completion: (OperationConditionResult) -> Void) {
        completion(condition() ? .satisfied : .failed(BlockCondition.Error.blockConditionFailed))
    }
}

class TestConditionOperation: Operations.Condition {

    let evaluate: () throws -> Bool

    init(dependencies: [Operation]? = .none, evaluate: () throws -> Bool) {
        self.evaluate = evaluate
        super.init()
        if let dependencies = dependencies {
            addDependencies(dependencies)
        }
    }

    override func evaluate(_ operation: OldOperation, completion: CompletionBlockType) {
        do {
            let success = try evaluate()
            completion(success ? .satisfied : .failed(OperationError.conditionFailed))
        }
        catch {
            completion(.failed(error))
        }
    }
}

class TestQueueDelegate: OperationQueueDelegate {

    typealias FinishBlockType = (Operation, [ErrorProtocol]) -> Void

    let willFinishOperation: FinishBlockType?
    let didFinishOperation: FinishBlockType?

    var did_willAddOperation: Bool = false
    var did_operationWillFinish: Bool = false
    var did_operationDidFinish: Bool = false
    var did_willProduceOperation: Bool = false
    var did_numberOfErrorThatOperationDidFinish: Int = 0

    init(willFinishOperation: FinishBlockType? = .none, didFinishOperation: FinishBlockType? = .none) {
        self.willFinishOperation = willFinishOperation
        self.didFinishOperation = didFinishOperation
    }

    func operationQueue(_ queue: OldOperationQueue, willAddOperation operation: Operation) {
        did_willAddOperation = true
    }

    func operationQueue(_ queue: OldOperationQueue, willFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) {
        did_operationWillFinish = true
        did_numberOfErrorThatOperationDidFinish = errors.count
        willFinishOperation?(operation, errors)
    }

    func operationQueue(_ queue: OldOperationQueue, didFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) {
        did_operationDidFinish = true
        did_numberOfErrorThatOperationDidFinish = errors.count
        didFinishOperation?(operation, errors)
    }
    
    func operationQueue(_ queue: OldOperationQueue, willProduceOperation operation: Operation) {
        did_willProduceOperation = true
    }
}

class OperationTests: XCTestCase {

    var queue: OldOperationQueue!
    var delegate: TestQueueDelegate!

    override func setUp() {
        super.setUp()
        LogManager.severity = .fatal
        queue = OldOperationQueue()
        delegate = TestQueueDelegate()
        queue.delegate = delegate
    }

    override func tearDown() {
        queue.cancelAllOperations()
        queue = nil
        delegate = nil
        ExclusivityManager.sharedInstance.__tearDownForUnitTesting()
        LogManager.severity = .warning
        super.tearDown()
    }

    func runOperation(_ operation: Operation) {
        queue.addOperation(operation)
    }

    func runOperations(_ operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func runOperations(_ operations: Operation...) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func waitForOperation(_ operation: OldOperation, withExpectationDescription text: String = #function) {
        addCompletionBlockToTestOperation(operation, withExpectationDescription: text)
        queue.delegate = delegate
        queue.addOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func waitForOperations(_ operations: OldOperation..., withExpectationDescription text: String = #function) {
        for (i, op) in operations.enumerated() {
            addCompletionBlockToTestOperation(op, withExpectationDescription: "\(i), \(text)")
        }
        queue.delegate = delegate
        queue.addOperations(operations, waitUntilFinished: false)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func addCompletionBlockToTestOperation(_ operation: OldOperation, withExpectation expectation: XCTestExpectation) {
        weak var weakExpectation = expectation
        operation.addObserver(DidFinishObserver { _, _ in
            weakExpectation?.fulfill()
        })
    }

    @discardableResult
    func addCompletionBlockToTestOperation(_ operation: OldOperation, withExpectationDescription text: String = #function) -> XCTestExpectation {
        let expectation = self.expectation(description: "Test: \(text), \(UUID().uuidString)")
        operation.addObserver(DidFinishObserver { _, _ in
            expectation.fulfill()
        })
        return expectation
    }
}
