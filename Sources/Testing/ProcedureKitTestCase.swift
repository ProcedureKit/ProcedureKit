//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class ProcedureKitTestCase<Target>: XCTestCase {

    public var queue: ProcedureQueue!
    public var delegate: QueueTestDelegate!
    open var target: Target!

    open override func setUp() {
        super.setUp()
        queue = ProcedureQueue()
        delegate = QueueTestDelegate()
        queue.delegate = delegate
    }

    open override func tearDown() {
        queue.cancelAllOperations()
        delegate = nil
        queue = nil
        target = nil
        super.tearDown()
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

    public func wait(for procedures: Procedure..., withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {
        for (i, procedure) in procedures.enumerated() {
            let _ = addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(i), \(expectationDescription)")
        }
        run(operations: procedures)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func addCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) -> XCTestExpectation {
        let expect = expectation(description: "Test: \(expectationDescription), \(UUID())")
        addCompletionBlockTo(procedure: procedure, withExpectation: expect)
        return expect
    }

    public func addCompletionBlockTo(procedure: Procedure, withExpectation expectation: XCTestExpectation) {
        weak var weakExpectation = expectation
        procedure.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                weakExpectation?.fulfill()
            }
        }
    }
}


open class BasicProcedureKitTestCase: ProcedureKitTestCase<TestProcedure> {

    public var procedure: TestProcedure {
        get { return target }
        set { target = newValue }
    }

    open override func setUp() {
        super.setUp()
        target = TestProcedure()
    }

    open override func tearDown() {
        target.cancel()
        super.tearDown()
    }
}
