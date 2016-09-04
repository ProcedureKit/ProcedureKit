//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

private enum __XCTAssertionResult {
    case success
    case expectedFailure(String?)
    case unexpectedFailure(Swift.Error)

    var isExpected: Bool {
        switch self {
        case .unexpectedFailure(_): return false
        default: return true
        }
    }

    func failureDescription() -> String {
        let explanation: String
        switch self {
        case .success: explanation = "passed"
        case .expectedFailure(let details?): explanation = "failed: \(details)"
        case .expectedFailure(_): explanation = "failed"
        case .unexpectedFailure(let error): explanation = "threw error \"\(error)\""
        }
        return explanation
    }
}

private func __XCTEvaluateAssertion(testCase: XCTestCase, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, expression: () throws -> __XCTAssertionResult) {
    let result: __XCTAssertionResult
    do {
        result = try expression()
    }
    catch {
        result = .unexpectedFailure(error)
    }

    switch result {
    case .success: return
    default:
        testCase.recordFailure(
            withDescription: "\(result.failureDescription()) - \(message())",
            inFile: String(describing: file), atLine: line,
            expected: result.isExpected
        )
    }

}

// MARK: Procedure Assertions

public extension ProcedureKitTestCase {

    func XCTAssertProcedureFinishedWithoutErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed with errors: \"\(procedure.errors)\".")
            }
            guard !procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureFinishedWithErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard !procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureFinishedWithErrors<T: ProcedureProcotol>(_ exp1: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp1()
            let count = try exp2()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard procedure.errors.count == count else {
                return .expectedFailure("\(procedure.procedureName) number of errors: (\(procedure.errors.count)), did not meet expectation: (\(count)).")
            }
            guard !procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureCancelledWithoutErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed with errors: \"\(procedure.errors)\".")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureCancelledWithErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureCancelledWithErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            let count = try exp2()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard procedure.errors.count == count else {
                return .expectedFailure("\(procedure.procedureName) number of errors: (\(procedure.errors.count)), did not meet expectation: (\(count)).")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }
}

// MARK: Constrained to TestProcedure

public extension ProcedureKitTestCase {

    func XCTAssertProcedureFinishedWithoutErrors<T: ProcedureProcotol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: TestProcedure {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed with errors: \"\(procedure.errors)\".")
            }
            guard !procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.didExecute else {
                return .expectedFailure("\(procedure.procedureName) did not execute.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }
}

public extension ProcedureKitTestCase {

    func XCTAssertProcedureFinishedWithoutErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureFinishedWithoutErrors(procedure, message, file: file, line: line)
    }

    func XCTAssertProcedureFinishedWithErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureFinishedWithErrors(procedure, message, file: file, line: line)
    }

    func XCTAssertProcedureFinishedWithErrors(count: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureFinishedWithErrors(procedure, count: count, message, file: file, line: line)
    }

    func XCTAssertProcedureCancelledWithoutErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureCancelledWithoutErrors(procedure, message, file: file, line: line)
    }

    func XCTAssertProcedureCancelledWithErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureCancelledWithErrors(procedure, message, file: file, line: line)
    }

    func XCTAssertProcedureCancelledWithErrors(count: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertProcedureCancelledWithErrors(procedure, count: count, message, file: file, line: line)
    }
}
