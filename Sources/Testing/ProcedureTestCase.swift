//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

class ProcedureTestCase: XCTestCase {

    var queue: ProcedureQueue!
    var delegate: QueueTestDelegate!

    override func setUp() {
        super.setUp()
        queue = ProcedureQueue()
        delegate = QueueTestDelegate()
        queue.delegate = delegate
    }

    override func tearDown() {
        queue.cancelAllOperations()
        delegate = nil
        queue = nil
        super.tearDown()
    }

    func run(operation: Operation) {
        run(operations: operation)
    }

    func run(operations: Operation...) {
        run(operations: operations)
    }

    func run(operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func wait(for procedure: Procedure, withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {
        wait(for: procedure, withTimeout: timeout, withExpectationDescription: expectationDescription)
    }

    func wait(for procedures: Procedure..., withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {
        for (i, procedure) in procedures.enumerated() {
            let _ = addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(i), \(expectationDescription)")
        }
        run(operations: procedures)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func addCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) -> XCTestExpectation {
        let expect = expectation(description: "Test: \(expectationDescription), \(UUID())")
        addCompletionBlockTo(procedure: procedure, withExpectation: expect)
        return expect
    }

    func addCompletionBlockTo(procedure: Procedure, withExpectation expectation: XCTestExpectation) {
        weak var weakExpectation = expectation
        procedure.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                weakExpectation?.fulfill()
            }
        }
    }
}
