//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public protocol ConcurrencyTestResultProtocol {
    var procedures: [TestConcurrencyTrackingProcedure] { get }
    var duration: Double { get }
    var registrar: ConcurrencyRegistrar { get }
}

// MARK: - ConcurrencyTestCase

open class ConcurrencyTestCase: ProcedureKitTestCase {

    public typealias Registrar = ConcurrencyRegistrar
    public typealias TrackingProcedure = TestConcurrencyTrackingProcedure

    public var registrar: Registrar!

    public class TestResult: ConcurrencyTestResultProtocol {
        public let procedures: [TrackingProcedure]
        public let duration: TimeInterval
        public let registrar: Registrar

        public init(procedures: [TrackingProcedure], duration: TimeInterval, registrar: Registrar) {
            self.procedures = procedures
            self.duration = duration
            self.registrar = registrar
        }
    }

    public struct Expectations {
        public let checkMinimumDetected: Int?
        public let checkMaximumDetected: Int?
        public let checkAllProceduresFinished: Bool?
        public let checkMinimumDuration: TimeInterval?
        public let checkExactDetected: Int?

        public init(checkMinimumDetected: Int? = .none, checkMaximumDetected: Int? = .none, checkAllProceduresFinished: Bool? = .none, checkMinimumDuration: TimeInterval? = .none) {
            if let checkMinimumDetected = checkMinimumDetected,
                let checkMaximumDetected = checkMaximumDetected,
                checkMinimumDetected == checkMaximumDetected {
                self.checkExactDetected = checkMinimumDetected
            }
            else {
                self.checkExactDetected = .none
            }
            self.checkMinimumDetected = checkMinimumDetected
            self.checkMaximumDetected = checkMaximumDetected
            self.checkAllProceduresFinished = checkAllProceduresFinished
            self.checkMinimumDuration = checkMinimumDuration
        }
    }

    public func create(procedures count: Int = 3, delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withRegistrar registrar: Registrar) -> [TrackingProcedure] {
        return (0..<count).map { i in
            let name = "TestConcurrencyTrackingProcedure: \(i)"
            return TestConcurrencyTrackingProcedure(name: name, microsecondsToSleep: delayMicroseconds, registrar: registrar)
        }
    }

    public func concurrencyTest(operations: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TrackingProcedure) -> TrackingProcedure = { return $0 }, withExpectations expectations: Expectations) {

        concurrencyTest(operations: operations, withDelayMicroseconds: delayMicroseconds, withTimeout: timeout, withConfigureBlock: configure,
            completionBlock: { (results) in
                XCTAssertResults(results, matchExpectations: expectations)
            }
        )
    }

    public func concurrencyTest(operations: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TrackingProcedure) -> TrackingProcedure = { return $0 }, completionBlock completion: (TestResult) -> Void) {

        let registrar = Registrar()
        let procedures = create(procedures: operations, delayMicroseconds: delayMicroseconds, withRegistrar: registrar).map {
            return configure($0)
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        wait(forAll: procedures, withTimeout: timeout)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        completion(TestResult(procedures: procedures, duration: duration, registrar: registrar))
    }

    public func XCTAssertResults(_ results: TestResult, matchExpectations expectations: Expectations) {

        // checkAllProceduresFinished
        if let checkAllProceduresFinished = expectations.checkAllProceduresFinished, checkAllProceduresFinished {
            for i in results.procedures.enumerated() {
                XCTAssertTrue(i.element.isFinished, "Test procedure [\(i.offset)] did not finish")
            }
        }
        // exact test for registrar.maximumDetected
        if let checkExactDetected = expectations.checkExactDetected {
            XCTAssertEqual(results.registrar.maximumDetected, checkExactDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) does not equal expected: \(checkExactDetected)")
        }
        else {
            // checkMinimumDetected
            if let checkMinimumDetected = expectations.checkMinimumDetected {
                XCTAssertGreaterThanOrEqual(results.registrar.maximumDetected, checkMinimumDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) is less than expected minimum: \(checkMinimumDetected)")
            }
            // checkMaximumDetected
            if let checkMaximumDetected = expectations.checkMaximumDetected {
                XCTAssertLessThanOrEqual(results.registrar.maximumDetected, checkMaximumDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) is greater than expected maximum: \(checkMaximumDetected)")
            }
        }
        // checkMinimumDuration
        if let checkMinimumDuration = expectations.checkMinimumDuration {
            XCTAssertGreaterThanOrEqual(results.duration, checkMinimumDuration, "Test duration exceeded minimum expected duration.")
        }
    }

    open override func setUp() {
        super.setUp()
        registrar = Registrar()
    }

    open override func tearDown() {
        registrar = nil
        super.tearDown()
    }
}

// MARK: - ConcurrencyRegistrar

open class ConcurrencyRegistrar {
    private struct State {
        var operations: [Operation] = []
        var maximumDetected: Int = 0
    }
    private let state = Protector(State())

    public var maximumDetected: Int {
        get {
            return state.read { $0.maximumDetected }
        }
    }
    public func registerRunning(_ operation: Operation) {
        state.write { ward in
            ward.operations.append(operation)
            ward.maximumDetected = max(ward.operations.count, ward.maximumDetected)
        }
    }
    public func deregisterRunning(_ operation: Operation) {
        state.write { ward in
            if let opIndex = ward.operations.index(of: operation) {
                ward.operations.remove(at: opIndex)
            }
        }
    }
}

// MARK: - TestConcurrencyTrackingProcedure

open class TestConcurrencyTrackingProcedure: Procedure {
    private weak var concurrencyRegistrar: ConcurrencyRegistrar?
    private let microsecondsToSleep: useconds_t
    init(name: String = "TestConcurrencyTrackingProcedure", microsecondsToSleep: useconds_t, registrar: ConcurrencyRegistrar) {
        self.concurrencyRegistrar = registrar
        self.microsecondsToSleep = microsecondsToSleep
        super.init()
        self.name = name
    }
    override open func execute() {
        concurrencyRegistrar?.registerRunning(self)
        usleep(microsecondsToSleep)
        concurrencyRegistrar?.deregisterRunning(self)
        finish()
    }
}
