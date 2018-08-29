//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
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
        testCase.recordFailure(
            withDescription: "\(result.failureDescription()) - \(message())",
            inFile: String(describing: file), atLine: Int(line),
            expected: result.isExpected
        )
    }

}

// MARK: Procedure Assertions

public extension ProcedureKitTestCase {

    func PKAssertProcedureFinished<T: Procedure>(_ exp: @autoclosure () throws -> T, withErrors: Bool = false, cancelling: Bool = false, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let procedure = try exp()

            // Errors are expected
            if withErrors {
                guard let _ = procedure.error else {
                    return .expectedFailure("\(procedure.procedureName) did not have an error.")
                }
            }
            // Errors are not expected
            else {
                guard procedure.error == nil else {
                    return .expectedFailure("\(procedure.procedureName) has an error.")
                }
            }

            if cancelling {
                guard procedure.isCancelled else {
                    return .expectedFailure("\(procedure.procedureName) was not cancelled.")
                }
            }
            else {
                guard !procedure.isCancelled else {
                    return .expectedFailure("\(procedure.procedureName) was cancelled.")
                }
            }

            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }

            return .success
        }
    }

    func PKAssertProcedureError<T: Procedure, E: Error>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            let expectedError = try exp2()
            guard let error = procedure.error else {
                return .expectedFailure("\(procedure.procedureName) did not error.")
            }
            guard let e = error as? E else {
                return .expectedFailure("\(procedure.procedureName) error: \(error), was not the expected type.")
            }
            guard expectedError == e else {
                return .expectedFailure("\(procedure.procedureName) error: \(e), did not equal expected error: \(expectedError).")
            }
            return .success
        }
    }


    func PKAssertProcedureCancelled<T: Procedure>(_ exp: @autoclosure () throws -> T, withErrors: Bool = false, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        PKAssertProcedureFinished(exp, withErrors: withErrors, cancelling: true, message, file: file, line: line)
    }

    func PKAssertProcedureFinishedWithError<T: Procedure, E: Error>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        PKAssertProcedureFinished(exp, withErrors: true, message, file: file, line: line)
        PKAssertProcedureError(exp, exp2, message, file: file, line: line)
    }

    func PKAssertProcedureCancelledWithError<T: Procedure, E: Error>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        PKAssertProcedureCancelled(exp, withErrors: true, message, file: file, line: line)
        PKAssertProcedureError(exp, exp2, message, file: file, line: line)
    }

    func PKAssertConditionSatisfied(_ exp1: @autoclosure () throws -> ConditionResult, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
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

    func PKAssertConditionFailed<E: Error>(_ exp1: @autoclosure () throws -> ConditionResult, failedWithError error: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
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

    func PKAssertProcedureOutput<T: Procedure>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () -> T.Output, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: OutputProcedure, T.Output: Equatable {
        PKAssertProcedureFinished(exp, message, file: file, line: line)
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard let output = procedure.output.success else {
                return .expectedFailure("\(procedure.procedureName) did not have a successful output value.")
            }
            let expectedOutput = exp2()
            guard expectedOutput == output else {
                return .expectedFailure("\(procedure.procedureName)'s successful output did not == \(expectedOutput).")
            }
            return .success
        }
    }
}


// MARK: - Deprecations

public extension ProcedureKitTestCase {

    @available(*, unavailable, deprecated: 5.0.0, renamed: "PKAssertProcedureFinished", message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureFinishedWithoutErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed.")
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

    @available(*, unavailable, deprecated: 5.0.0, message: "Use PKAssertProcedure* functions instead.")
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

    @available(*, unavailable, deprecated: 5.0.0, renamed: "PKAssertProcedureFinishedWithError", message: "Use XCTAssertProcedureFinishedWithErrors instead, providing an appropriate error.")
    func XCTAssertProcedureFinishedWithErrors<T: ProcedureProtocol>(_ exp1: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, deprecated: 5.0.0, renamed: "PKAssertProcedureCancelled", message: "Use PKAssertProcedureCancelled instead.")
    func XCTAssertProcedureCancelledWithoutErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed.")
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

    @available(*, unavailable, deprecated: 5.0.0, renamed: "PKAssertProcedureCancelledWithError", message: "Use PKAssertProcedureCancelledWithError instead, providing an appropriate error.")
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

    @available(*, unavailable, deprecated: 5.0.0, renamed: "PKAssertProcedureCancelledWithError", message: "Use PKAssertProcedureCancelledWithError instead, providing an appropriate error.")
    func XCTAssertProcedureCancelledWithErrors<T: ProcedureProtocol>(_ exp: @autoclosure () throws -> T, count exp2: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, deprecated: 5.0.0, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertConditionResult<E: Error>(_ exp1: @autoclosure () throws -> ConditionResult, failedWithError error: @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        PKAssertConditionFailed(exp1, failedWithError: error, message, file: file, line: line)
    }

    @available(*, unavailable, deprecated: 5.0.0, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertConditionResultSatisfied(_ exp1: @autoclosure () throws -> ConditionResult, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        PKAssertConditionSatisfied(exp1, message, file: file, line: line)
    }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedure<T: ProcedureProtocol, E: Error>(_ exp: @autoclosure () throws -> T, firstErrorEquals firstError: E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable { }

    @available(*, deprecated: 5.0.0, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureOutputSuccess<T: OutputProcedure>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () -> T.Output, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T.Output: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            guard !procedure.failed else {
                return .expectedFailure("\(procedure.procedureName) has failed.")
            }
            guard !procedure.isCancelled else {
                return .expectedFailure("\(procedure.procedureName) was cancelled.")
            }
            guard procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) did not finish.")
            }
            guard let output = procedure.output.success else {
                return .expectedFailure("\(procedure.procedureName) did not have a successful output value.")
            }
            let expectedOutput = exp2()
            guard expectedOutput == output else {
                return .expectedFailure("\(procedure.procedureName)'s successful output did not == .")
            }
            return .success
        }
    }
}

// MARK: Constrained to TestProcedure

public extension ProcedureKitTestCase {

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureFinishedWithoutErrors<T>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: TestProcedure { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureCancelledWithoutErrors<T>(_ exp: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: TestProcedure { }

}

public extension ProcedureKitTestCase {

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureFinishedWithoutErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureFinishedWithErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureFinishedWithErrors(count: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureCancelledWithoutErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureCancelledWithErrors(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }

    @available(*, unavailable, message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureCancelledWithErrors(count: @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) { }
}

// MARK: Constrained to EventConcurrencyTrackingProcedureProtocol

public extension ProcedureKitTestCase {

    func PKAssertProcedureNoConcurrentEvents<T: EventConcurrencyTrackingProcedureProtocol>(_ exp: @autoclosure () throws -> T, minimumConcurrentDetected: Int = 1, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: Procedure {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()
            let detectedConcurrentEvents = procedure.concurrencyRegistrar.detectedConcurrentEvents
            guard procedure.concurrencyRegistrar.maximumDetected >= minimumConcurrentDetected && detectedConcurrentEvents.isEmpty else {
                return .expectedFailure("\(procedure.procedureName) detected concurrent events: \n\(detectedConcurrentEvents)")
            }
            return .success
        }
    }

    @available(*, unavailable, renamed: "PKAssertProcedureNoConcurrentEvents", message: "Use PKAssertProcedure* functions instead.")
    func XCTAssertProcedureNoConcurrentEvents<T: EventConcurrencyTrackingProcedureProtocol>(_ exp: @autoclosure () throws -> T, minimumConcurrentDetected: Int = 1, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where T: Procedure {
        PKAssertProcedureNoConcurrentEvents(exp, minimumConcurrentDetected: minimumConcurrentDetected, message, file: file, line: line)
    }
}
