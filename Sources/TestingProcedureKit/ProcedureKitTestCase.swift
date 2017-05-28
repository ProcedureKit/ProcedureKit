//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class ProcedureKitTestCase: XCTestCase {

    public var queue: ProcedureQueue!
    public var delegate: QueueTestDelegate! // swiftlint:disable:this weak_delegate
    open var procedure: TestProcedure!

    open override func setUp() {
        super.setUp()
        queue = ProcedureQueue()
        delegate = QueueTestDelegate()
        queue.delegate = delegate
        procedure = TestProcedure()
    }

    open override func tearDown() {
        if let procedure = procedure {
            procedure.cancel()
        }
        if let queue = queue {
            queue.cancelAllOperations()
            queue.waitUntilAllOperationsAreFinished()
        }
        delegate = nil
        queue = nil
        procedure = nil
        LogManager.severity = .warning
        ExclusivityManager.__tearDownForUnitTesting()
        super.tearDown()
    }

    public func set(queueDelegate delegate: QueueTestDelegate) {
        self.delegate = delegate
        queue.delegate = delegate
    }

    public func run(operation: Operation) {
        run(operations: [operation])
    }

    public func run(operations: Operation...) {
        run(operations: operations)
    }

    public func run(operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    public func wait(for procedures: Procedure..., withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function, handler: XCWaitCompletionHandler? = nil) {
        wait(forAll: procedures, withTimeout: timeout, withExpectationDescription: expectationDescription, handler: handler)
    }

    public func wait(forAll procedures: [Procedure], withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function, handler: XCWaitCompletionHandler? = nil) {
        addCompletionBlockTo(procedures: procedures)
        run(operations: procedures)
        waitForExpectations(timeout: timeout, handler: handler)
    }

    /// Runs a Procedure on the queue, waiting until it is complete to return,
    /// but calls a specified block before the wait.
    ///
    /// IMPORTANT: This function calls the specified block immediately after adding
    ///            the Procedure to the queue. This does *not* ensure any specific
    ///            ordering/timing in regards to the block and the Procedure executing.
    ///
    /// - Parameters:
    ///   - procedure: a Procedure
    ///   - timeout: (optional) a timeout for the wait
    ///   - expectationDescription: (optional) an expectation description
    ///   - checkBeforeWait: a block to be executed before the wait (see above)
    public func check<T: Procedure>(procedure: T, withAdditionalProcedures additionalProcedures: Procedure..., withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function, checkBeforeWait: (T) -> Void) {
        var allProcedures = additionalProcedures
        allProcedures.append(procedure)
        addCompletionBlockTo(procedures: allProcedures)
        run(operations: allProcedures)
        checkBeforeWait(procedure)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func checkAfterDidExecute<T>(procedure: T, withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function, checkAfterDidExecuteBlock: @escaping (T) -> Void) where T: Procedure {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: expectationDescription)
        procedure.addDidExecuteBlockObserver { (procedure) in
            checkAfterDidExecuteBlock(procedure)
        }
        run(operations: procedure)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func addCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) {
        // Make a finishing procedure, which depends on this target Procedure.
        let finishingProcedure = makeFinishingProcedure(for: procedure, withExpectationDescription: expectationDescription)
        // Add the did finish expectation block to the finishing procedure
        addExpectationCompletionBlockTo(procedure: finishingProcedure, withExpectationDescription: expectationDescription)
        run(operation: finishingProcedure)
    }

    public func addCompletionBlockTo<S: Sequence>(procedures: S, withExpectationDescription expectationDescription: String = #function) where S.Iterator.Element == Procedure {
        for (i, procedure) in procedures.enumerated() {
            addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(i), \(expectationDescription)")
        }
    }

    @discardableResult public func addExpectationCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) -> XCTestExpectation {
        let expect = expectation(description: "Test: \(expectationDescription), \(UUID())")
        add(expectation: expect, to: procedure)
        return expect
    }

    public func add(expectation: XCTestExpectation, to procedure: Procedure) {
        weak var weakExpectation = expectation
        procedure.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                weakExpectation?.fulfill()
            }
        }
    }

    func makeFinishingProcedure(for procedure: Procedure, withExpectationDescription expectationDescription: String = #function) -> Procedure {
        let finishing = BlockProcedure { }
        finishing.log.enabled = false
        finishing.add(dependency: procedure)
        // Adds a will add operation observer, which adds the produced operation as a dependency
        // of the finishing procedure. This way, we don't actually finish, until the
        // procedure, and any produced operations also finish.
        procedure.addWillAddOperationBlockObserver { [weak weakFinishing = finishing] _, operation in
            guard let finishing = weakFinishing else { fatalError("Finishing procedure is finished + gone, but a WillAddOperation observer on a dependency was called. This should never happen.") }
            finishing.add(dependency: operation)
        }
        finishing.name = "FinishingBlockProcedure(for: \(procedure.operationName))"
        return finishing
    }
}

public extension ProcedureKitTestCase {

    func createCancellingProcedure() -> TestProcedure {
        let procedure = TestProcedure(name: "Cancelling Test Procedure")
        procedure.addWillExecuteBlockObserver { procedure, _ in
            procedure.cancel()
        }
        return procedure
    }
}
