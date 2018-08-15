//
//  ProcedureKit
//
//  Copyright © 2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class BatchProcedureTests: ProcedureKitTestCase {

    class Greeter: TransformProcedure<String, String> {
        init() {
            super.init { "Hello \($0)" }
        }
    }

    typealias Batch = BatchProcedure<Greeter>

    func test__batch() {

        let beatles = ResultProcedure { ["John", "Paul", "George", "Ringo"] }
        let greetings = Batch { Greeter() }.injectResult(from: beatles)

        wait(for: beatles, greetings)

        PKAssertProcedureFinished(greetings)
        guard let result = greetings.output.success else {
            XCTFail("Batch did not finish with successful output.")
            return
        }
        XCTAssertEqual(result, ["Hello John", "Hello Paul", "Hello George", "Hello Ringo"])
    }

    func test__batch_cancel_if_input_not_ready() {

        let beatles = ResultProcedure<[String]> { throw ProcedureKitError.unknown }
        let greetings = Batch { Greeter() }.injectResult(from: beatles)

        wait(for: beatles, greetings)

        PKAssertProcedureCancelledWithError(greetings, ProcedureKitError.dependency(finishedWithError: ProcedureKitError.unknown))
    }
}
