//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

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
        XCTAssertEqual(testResult, 120)
    }

    func test__async_transform() {
        let chain = NumbersProcedure()
            .transform { input, finish in finish(.success(input.map { $0 * 2 })) }
            .map { $0 + 3 }
            .reduce(0, nextPartialResult: +)

        wait(for: chain)

        // Numbers
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[0])
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[1])

        guard let testResult = chain.tail.output.value?.value else { XCTFail("Did not get a result"); return }
        XCTAssertEqual(testResult, 120)
    }

    func test__filter() {
        let chain = NumbersProcedure()
            .chain
            .filter { $0 % 2 == 0 }
            .reduce(0, nextPartialResult: +)

        wait(for: chain)

        // Numbers
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[0])
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[1])

        guard let testResult = chain.tail.output.value?.value else { XCTFail("Did not get a result"); return }
        XCTAssertEqual(testResult, 20) // 2+4+6+8
    }

    func test__flatMap() {
        let chain = NumbersProcedure()
            .chain
            .flatMap {
                guard $0 % 2 == 0 else { return nil }
                return $0 * 2
            }
            .reduce(0, nextPartialResult: +)

        wait(for: chain)

        // Numbers
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[0])
        XCTAssertProcedureFinishedWithoutErrors(chain.procedures[1])

        guard let testResult = chain.tail.output.value?.value else { XCTFail("Did not get a result"); return }
        XCTAssertEqual(testResult, 40) // 4+8+12+16
    }
}
