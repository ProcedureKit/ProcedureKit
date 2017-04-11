//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class TransformProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_transformed_to_result() {
        let timesTwo = TransformProcedure<Int, Int> { return $0 * 2 }
        timesTwo.input = .ready(2)
        wait(for: timesTwo)
        XCTAssertProcedureFinishedWithoutErrors(timesTwo)
        XCTAssertEqual(timesTwo.output.success ?? 0, 4)
    }

    func test__requirement_is_nil_finishes_with_error() {
        let timesTwo = TransformProcedure<Int, Int> { return $0 * 2 }
        wait(for: timesTwo)
        XCTAssertProcedureFinishedWithErrors(timesTwo, count: 1)
    }
}

class AsyncTransformProcedureTests: ProcedureKitTestCase {

    var dispatchQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        dispatchQueue = DispatchQueue.initiated
    }

    override func tearDown() {
        dispatchQueue = nil
        super.tearDown()
    }
    
    func test__requirement_is_transformed_to_result() {
        let timesTwo = AsyncTransformProcedure<Int, Int> { input, finishWithResult in
            self.dispatchQueue.async {
                finishWithResult(.success(input * 2))
            }
        }
        timesTwo.input = .ready(2)
        wait(for: timesTwo)
        XCTAssertProcedureFinishedWithoutErrors(timesTwo)
        XCTAssertEqual(timesTwo.output.success ?? 0, 4)
    }

    func test__requirement_is_nil_finishes_with_error() {
        let timesTwo = AsyncTransformProcedure<Int, Int> { input, finishWithResult in
            self.dispatchQueue.async {
                finishWithResult(.success(input * 2))
            }
        }
        wait(for: timesTwo)
        XCTAssertProcedureFinishedWithErrors(timesTwo, count: 1)
    }
}

class ProcedureChainTests: ProcedureKitTestCase {

    func test__all_procedures_in_chain_executes() {

        // This method allows arbitrary chaining of blocks to
        // any output procedure. This can be used to chain 
        // together smaller units of work in a functional
        // style 
        let chain = NumbersProcedure()
            .transform { $0.map { $0 * 2 } }
            .map { $0 + 3 }
            .reduce(0, nextPartialResult: +)

        wait(for: chain)

        // Numbers
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[0])
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[1])
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[2])
        guard let testResult = chain.tail.output.value?.value else { XCTFail("Did not get a result"); return }
        XCTAssertEqual(testResult, 3+5+7+9+11+13+15+17+19+21)
    }
}
