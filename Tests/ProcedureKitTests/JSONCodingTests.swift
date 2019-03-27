//
//  ProcedureKitTests
//
//  Copyright © 2019 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class JSONEncodingTests: ProcedureKitTestCase {

    struct Person: Equatable, Codable {
        let firstName: String
        let lastName: String
    }

    final class CodingTestProcedure<T: Codable>: GroupProcedure, InputProcedure, OutputProcedure {

        var input: Pending<T> = .pending
        var output: Pending<ProcedureResult<T>> = .pending

        init() {

            let encode = EncodeJSONProcedure<T>()
            let decode = DecodeJSONProcedure<T>().injectResult(from: encode)

            super.init(operations: [encode, decode])

            bind(to: encode)
            bind(from: decode)
        }
    }

    func test__coding_single_item() {

        let john = Person(firstName: "John", lastName: "Lennon")
        let input = ResultProcedure { john }
        let coding = CodingTestProcedure<Person>().injectResult(from: input)

        wait(for: coding, input)

        PKAssertProcedureOutput(coding, john)
    }

    func test__coding_array_items() {
        let beatles = [
            Person(firstName: "John", lastName: "Lennon"),
            Person(firstName: "Paul", lastName: "McCartney"),
            Person(firstName: "George", lastName: "Harrison"),
            Person(firstName: "Ringo", lastName: "Starr")
        ]
        let input = ResultProcedure { beatles }
        let coding = CodingTestProcedure<[Person]>().injectResult(from: input)

        wait(for: coding, input)

        PKAssertProcedureOutput(coding, beatles)
    }
}
