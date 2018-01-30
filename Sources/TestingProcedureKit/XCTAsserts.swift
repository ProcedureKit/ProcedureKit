//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

internal enum __XCTAssertionResult {
    case success
    case expectedFailure(String?)
    case unexpectedFailure(Swift.Error)

    var isExpected: Bool {
        switch self {
        case .unexpectedFailure: return false
        default: return true
        }
    }

    func failureDescription() -> String {
        let explanation: String
        switch self {
        case .success: explanation = "passed"
        case .expectedFailure(let details?): explanation = "failed: \(details)"
        case .expectedFailure: explanation = "failed"
        case .unexpectedFailure(let error): explanation = "threw error \"\(error)\""
        }
        return explanation
    }
}

internal func __XCTEvaluateAssertion(testCase: XCTestCase, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, expression: () throws -> __XCTAssertionResult) {
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
        #if swift(>=4.0)
            testCase.recordFailure(
                withDescription: "\(result.failureDescription()) - \(message())",
                inFile: String(describing: file), atLine: Int(line),
                expected: result.isExpected
            )
        #else
            testCase.recordFailure(
                withDescription: "\(result.failureDescription()) - \(message())",
                inFile: String(describing: file), atLine: line,
                expected: result.isExpected
            )
        #endif
    }

}

// MARK: Procedure Assertions

public extension ProcedureKitTestCase {

    func XCTAssertProcedureFinishedWithoutErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
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

    func XCTAssertProcedureFinishedWithErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
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

    func XCTAssertProcedureFinishedWithErrors<T: ProcedureProtocol>(_ exp1: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
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

    func XCTAssertProcedureCancelledWithoutErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed with errors: \"\(procedure.errors)\".")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was not cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureCancelledWithErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was not cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    func XCTAssertProcedureCancelledWithErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
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
                return .expectedFailure("\(procedure.procedureName) was not cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            return .success
        }
    }

    public func XCTAssertConditionResult<E: Error>(_ exp1: @autoclosure () throws -> ConditionResult, failedWithError error: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let result = try exp1()
            let expectedError = try error()

            switch result {
            case let .failure(receivedError):
                guard let error = receivedError as? E else {
                    return .expectedFailure("Condition failed with unexpected error, \(receivedError).")
                }
                guard error == expectedError else {
                    return .expectedFailure("Condition failed with error: \(error), instead of: \(expectedError).")
                }
            default:
                return .expectedFailure("Condition did not fail, \(result).")
            }
            return .success
        }
    }

    public func XCTAssertConditionResultSatisfied(_ exp1: @autoclosure () throws -> ConditionResult, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let result = try exp1()

            switch result {
            case .success(true): break
            default:
                return .expectedFailure("Condition was not satisfied: \(result).")
            }
            return .success
        }
    }

    public func XCTAssertProcedure<T: ProcedureProtocol, E: Error>(_ exp: @autoclosure () throws -> T, firstErrorEquals firstError: E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors.")
            }
            guard procedure.errors[0] as? E == firstError else {
                return .expectedFailure("\(procedure.procedureName) first error is not expected error. Errors are: \(procedure.errors)")
            }
            return .success
        }
    }
}

// MARK: Constrained to TestProcedure

public extension ProcedureKitTestCase {

    func XCTAssertProcedureFinishedWithoutErrors<T>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: TestProcedure {
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

    func XCTAssertProcedureCancelledWithoutErrors<T>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: TestProcedure {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed with errors: \"\(procedure.errors)\".")
            }
            guard !procedure.didExecute else {
                return .expectedFailure("\(procedure.procedureName) did execute.")
            }
            guard procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was not cancelled.")
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

// MARK: Constrained to EventConcurrencyTrackingProcedureProtocol

public extension ProcedureKitTestCase {

    func XCTAssertProcedureNoConcurrentEvents<T: EventConcurrencyTrackingProcedureProtocol>(_ exp: @autoclosure () throws -> T, minimumConcurrentDetected: Int = 1, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: Procedure {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            let detectedConcurrentEvents = procedure.concurrencyRegistrar.detectedConcurrentEvents
            guard procedure.concurrencyRegistrar.maximumDetected >= minimumConcurrentDetected && detectedConcurrentEvents.isEmpty else {
                return .expectedFailure("\(procedure.procedureName) detected concurrent events: \n\(detectedConcurrentEvents)")
            }
            return .success
        }
    }
}
