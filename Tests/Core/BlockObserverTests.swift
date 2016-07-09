//
//  BlockObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/12/2015.
//
//

import XCTest
@testable import Operations

class BaseBlockObserverTests: OperationTests {

    var operation: TestOperation!

    override func setUp() {
        super.setUp()
        operation = TestOperation()
    }

    override func tearDown() {
        operation = nil
        super.tearDown()
    }
}

class StartedObserverTests: BaseBlockObserverTests {

    var called_didAttachToOperation: Operation? = .None
    var called_didStartOperation: Operation? = .None
    var observer: WillExecuteObserver!

    override func setUp() {
        super.setUp()
        observer = WillExecuteObserver { [unowned self] op in
            self.called_didStartOperation = op
        }
        observer.didAttachToOperation = { [unowned self] op in
            self.called_didAttachToOperation = op
        }
    }

    func test__did_attach_block_is_called() {
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__observer_receives_did_starter() {
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_didStartOperation, operation)
    }
}

class CancelledObserverTests: BaseBlockObserverTests {

    var called_didAttachToOperation: Operation? = .None
    var called_didCancelOperation: Operation? = .None
    var observer: DidCancelObserver!

    override func setUp() {
        super.setUp()
        observer = DidCancelObserver { [unowned self] op in
            self.called_didCancelOperation = op
        }
        observer.didAttachToOperation = { [unowned self] op in
            self.called_didAttachToOperation = op
        }
    }

    func test__did_attach_block_is_called() {
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__cancel_before_adding_to_queue() {
        operation.addObserver(observer)
        operation.cancel()
        XCTAssertEqual(called_didCancelOperation, operation)
        XCTAssertTrue(operation.cancelled)
    }

    func test__cancel_after_adding_to_queue() {
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        operation.cancel()
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_didCancelOperation, operation)
        XCTAssertTrue(operation.cancelled)
    }
}

class ProducedOperationObserverTests: BaseBlockObserverTests {

    var called_didAttachToOperation: Operation? = .None
    var called_didProduceOperation: (Operation, NSOperation)? = .None
    var observer: ProducedOperationObserver!
    var produced: NSBlockOperation!

    override func setUp() {
        super.setUp()
        produced = NSBlockOperation { }
        operation = TestOperation(produced: produced)
        observer = ProducedOperationObserver { [unowned self] op, produced in
            self.called_didProduceOperation = (op, produced)
        }
        observer.didAttachToOperation = { [unowned self] op in
            self.called_didAttachToOperation = op
        }
    }

    func test__did_attach_block_is_called() {
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__did_produce_operation_block_is_called() {
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_didProduceOperation?.0, operation)
        XCTAssertEqual(called_didProduceOperation?.1, produced)
    }
}

class WillFinishObserverTests: BaseBlockObserverTests {

    var called_didAttachToOperation: Operation? = .None
    var called_willFinish: (Operation, [ErrorType])? = .None
    var observer: WillFinishObserver!

    override func setUp() {
        super.setUp()
        observer = WillFinishObserver { [unowned self] op, errors in
            self.called_willFinish = (op, errors)
        }
        observer.didAttachToOperation = { [unowned self] op in
            self.called_didAttachToOperation = op
        }
    }

    func test__did_attach_block_is_called() {
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__will_finish_block_is_called() {
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_willFinish?.0, operation)
        XCTAssertTrue(called_willFinish?.1.isEmpty ?? false)
    }

    func test__will_finish_block_with_errors() {
        operation = TestOperation(error: TestOperation.Error.SimulatedError)
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_willFinish?.0, operation)
        XCTAssertEqual(called_willFinish?.1.count ?? 0, 1)
    }
}

class DidFinishObserverTests: BaseBlockObserverTests {

    var called_didAttachToOperation: Operation? = .None
    var called_didFinish: (Operation, [ErrorType])? = .None
    var observer: DidFinishObserver!

    override func setUp() {
        super.setUp()
        observer = DidFinishObserver { [unowned self] op, errors in
            self.called_didFinish = (op, errors)
        }
        observer.didAttachToOperation = { [unowned self] op in
            self.called_didAttachToOperation = op
        }
    }

    func test__did_attach_block_is_called() {
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__did_finish_block_is_called() {
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_didFinish?.0, operation)
        XCTAssertTrue(called_didFinish?.1.isEmpty ?? false)
    }

    func test__will_finish_block_with_errors() {
        operation = TestOperation(error: TestOperation.Error.SimulatedError)
        operation.addObserver(observer)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(called_didFinish?.0, operation)
        XCTAssertEqual(called_didFinish?.1.count ?? 0, 1)
    }
}

class BlockObserverTests: BaseBlockObserverTests {

    func test__did_attach_block_is_called() {
        var called_didAttachToOperation: Operation? = .None
        var observer = BlockObserver { _, _ in }
        observer.didAttachToOperation = { op in
            called_didAttachToOperation = op
        }
        operation.addObserver(observer)
        XCTAssertEqual(called_didAttachToOperation, operation)
    }

    func test__start_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver(willExecute: { op in
            counter += 1
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }

    func test__cancellation_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver(didCancel: { op in
            counter += 1
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        operation.cancel()
        operation.cancel() // Deliberately call cancel multiple times.
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }

    func test__produce_handler_is_executed() {
        let produced = TestOperation()
        operation = TestOperation(produced: produced)

        var counter = 0
        operation.addObserver(BlockObserver(didProduce: { op, pro in
            counter += 1
            XCTAssertEqual(produced, pro)
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }

    func test__will_finish_handler_is_executed() {
        var counter = 0
        operation.addObserver(BlockObserver(willFinish: { op, errors in
            counter += 1
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }

    func test__did_finish_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver { op, errors in
            counter += 1
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }
}
