//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class TestGroupProcedure: GroupProcedure {
    public var didExecute: Bool { return _didExecute.access }

    private var _didExecute = Protector(false)

    open override func execute() {
        _didExecute.overwrite(with: true)
        super.execute()
    } 
}

open class GroupTestCase: ProcedureKitTestCase {

    public var children: [TestProcedure]!
    public var group: TestGroupProcedure!

    public func createTestProcedures(count: Int = 5, shouldError: Bool = false, duration: TimeInterval = 0.000_001) -> [TestProcedure] {
        return (0..<count).map { i in
            let name = "Child: \(i)"
            return shouldError ? TestProcedure(name: name, delay: duration, error: TestError()) : TestProcedure(name: name, delay: duration)
        }
    }

    open override func setUp() {
        super.setUp()
        children = createTestProcedures()
        group = TestGroupProcedure(operations: children)
    }

    open override func tearDown() {
        group.cancel()
        children = nil
        super.tearDown()
    }
}

public extension ProcedureKitTestCase {

    func PKAssertGroupErrors<T: GroupProcedure>(_ exp: @autoclosure () throws -> T, count exp2:  @autoclosure () throws -> Int, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let procedure = try exp()
            let count = try exp2()

            guard count > 0 else {
                guard procedure.error == nil else {
                    return .expectedFailure("\(procedure.procedureName) had an error.")
                }
                return .success
            }

            let groupErrors = procedure.children.compactMap { ($0 as? Procedure)?.error }

            guard groupErrors.count == count else {
                return .expectedFailure("\(procedure.procedureName) expected \(count) errors, received \(groupErrors.count).")
            }

            return .success
        }
    }

    func PKAssertGroupErrors<T: GroupProcedure, E: Error>(_ exp: @autoclosure () throws -> T, doesNot: Bool = false, contain exp2:  @autoclosure () throws -> E, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where E: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let procedure = try exp()
            let otherError = try exp2()

            guard procedure.error != nil else {
                return .expectedFailure("\(procedure.procedureName) did not have an error.")
            }

            let errors: [E] = procedure.children.compactMap { ($0 as? Procedure)?.error as? E }

            guard errors.count > 0 else {
                return .expectedFailure("\(procedure.procedureName) did not have any errors of type \(E.self).")
            }

            switch (doesNot, errors.contains(otherError)) {
            case (false, false):
                return .expectedFailure("\(procedure.procedureName) errors did not contain \(otherError).")
            case (true, true):
                return .expectedFailure("\(procedure.procedureName) errors did contain \(otherError).")
            default:
                break
            }

            return .success
        }
    }
}

// MARK: - GroupConcurrencyTestCase

open class GroupConcurrencyTestCase: ConcurrencyTestCase {

    public class GroupTestResult: TestResult {
        public let group: TestGroupProcedure

        public init(group: TestGroupProcedure, procedures: [TrackingProcedure], duration: TimeInterval, registrar: Registrar) {
            self.group = group
            super.init(procedures: procedures, duration: duration, registrar: registrar)
        }
    }

    @discardableResult public func concurrencyTestGroup(children: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestGroupProcedure) -> Void, withExpectations expectations: Expectations) -> GroupTestResult {

        return concurrencyTestGroup(children: children, withDelayMicroseconds: delayMicroseconds, withName: name, withTimeout: timeout,
            withConfigureBlock: configure,
            completionBlock: { (results) in
                XCTAssertResults(results, matchExpectations: expectations)
        })
    }

    @discardableResult public func concurrencyTestGroup(children: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestGroupProcedure) -> Void, completionBlock completion: (GroupTestResult) -> Void) -> GroupTestResult {

        let registrar = Registrar()
        let testProcedures = create(procedures: children, delayMicroseconds: delayMicroseconds, withRegistrar: registrar)
        let group = TestGroupProcedure(operations: testProcedures)

        configure(group)

        let startTime = CFAbsoluteTimeGetCurrent()
        wait(for: group, withTimeout: timeout)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        let result = GroupTestResult(group: group, procedures: testProcedures, duration: duration, registrar: registrar)
        completion(result)
        return result
    }
}
