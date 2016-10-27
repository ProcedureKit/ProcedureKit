//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest

public protocol ConcurrencyTestResultProtocol {
    var testProcedures: [TestConcurrencyTrackingProcedure] { get }
    var duration: Double { get }
    var concurrencyRegistrar: ConcurrencyRegistrar { get }
}

public class ConcurrencyTestResult: ConcurrencyTestResultProtocol {
    public let testProcedures: [TestConcurrencyTrackingProcedure]
    public let duration: Double
    public let concurrencyRegistrar: ConcurrencyRegistrar
    
    public init(testProcedures: [TestConcurrencyTrackingProcedure], duration: Double, concurrencyRegistrar: ConcurrencyRegistrar) {
        self.testProcedures = testProcedures
        self.duration = duration
        self.concurrencyRegistrar = concurrencyRegistrar
    }
}

public struct ConcurrencyTestExpectations {
    public let minConcurrentOperationsDetectedCount: Int?
    public let maxConcurrentOperationsDetectedCount: Int?
    public let allTestConcurrencyProceduresFinished: Bool?
    public let minimumDurationInSeconds: Double?
    public let exactMaxConcurrentOperationsDetectedCount: Int?
    
    public init(minConcurrentOperationsDetectedCount: Int? = .none, maxConcurrentOperationsDetectedCount: Int? = .none, allTestConcurrencyProceduresFinished: Bool? = .none, minimumDurationInSeconds: Double? = .none) {
        if let minConcurrentOperationsDetectedCount = minConcurrentOperationsDetectedCount,
            let maxConcurrentOperationsDetectedCount = maxConcurrentOperationsDetectedCount,
            minConcurrentOperationsDetectedCount == maxConcurrentOperationsDetectedCount {
            self.exactMaxConcurrentOperationsDetectedCount = minConcurrentOperationsDetectedCount
        }
        else {
            self.exactMaxConcurrentOperationsDetectedCount = .none
        }
        self.minConcurrentOperationsDetectedCount = minConcurrentOperationsDetectedCount
        self.maxConcurrentOperationsDetectedCount = maxConcurrentOperationsDetectedCount
        self.allTestConcurrencyProceduresFinished = allTestConcurrencyProceduresFinished
        self.minimumDurationInSeconds = minimumDurationInSeconds
    }
}

// MARK: - ConcurrencyTestCase

open class ConcurrencyTestCase: ProcedureKitTestCase {

    public var concurrencyRegistrar: ConcurrencyRegistrar!

    public func createTestProcedures(count: Int = 3, procedureDelayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withConcurrencyRegistrar registrar: ConcurrencyRegistrar) -> [TestConcurrencyTrackingProcedure] {
        return (0..<count).map { i in
            let name = "TestConcurrencyTrackingProcedure: \(i)"
            return TestConcurrencyTrackingProcedure(name: name, microsecondsToSleep: procedureDelayMicroseconds, registrar: registrar)
        }
    }

    public func concurrencyTest(operations: Int = 3, withProcedureDelayMicroseconds procedureDelayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestConcurrencyTrackingProcedure) -> TestConcurrencyTrackingProcedure = { return $0 }, withExpectations expectations: ConcurrencyTestExpectations) {

        concurrencyTest(operations: operations, withProcedureDelayMicroseconds: procedureDelayMicroseconds, withTimeout: timeout, withConfigureBlock: configure,
            completionBlock: { (results) in
                XCTAssertConcurrencyResults(results, matchExpectations: expectations)
            }
        )
    }

    public func concurrencyTest(operations: Int = 3, withProcedureDelayMicroseconds procedureDelayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestConcurrencyTrackingProcedure) -> TestConcurrencyTrackingProcedure = { return $0 }, completionBlock completion: (ConcurrencyTestResult) -> Void) {

        let concurrencyRegistrar = ConcurrencyRegistrar()
        let testProcedures = createTestProcedures(count: operations, procedureDelayMicroseconds: procedureDelayMicroseconds, withConcurrencyRegistrar: concurrencyRegistrar).map {
            return configure($0)
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        wait(forAll: testProcedures, withTimeout: timeout)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        completion(ConcurrencyTestResult(testProcedures: testProcedures, duration: duration, concurrencyRegistrar: concurrencyRegistrar))
    }

    public func XCTAssertConcurrencyResults(_ results: ConcurrencyTestResultProtocol, matchExpectations expectations: ConcurrencyTestExpectations) {

        // allTestConcurrencyProceduresFinished
        if let allTestProceduresFinished = expectations.allTestConcurrencyProceduresFinished, allTestProceduresFinished {
            for i in results.testProcedures.enumerated() {
                XCTAssertTrue(i.element.isFinished, "Test operation [\(i.offset)] did not finish")
            }
        }
        // exact test for maxConcurrentOperationsDetectedCount
        if let exactMaxConcurrentOperationsExpected = expectations.exactMaxConcurrentOperationsDetectedCount {
            XCTAssertEqual(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount, exactMaxConcurrentOperationsExpected, "maxConcurrentOperationsDetectedCount (\(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount)) does not equal expected: \(exactMaxConcurrentOperationsExpected)")
        }
        else {
            // minConcurrentOperationsDetectedCount
            if let minConcurrentOperationsExpected = expectations.minConcurrentOperationsDetectedCount {
                XCTAssertGreaterThanOrEqual(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount, minConcurrentOperationsExpected, "maxConcurrentOperationsDetectedCount (\(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount)) is less than expected minimum: \(minConcurrentOperationsExpected)")
            }
            // maxConcurrentOperationsDetectedCount
            if let maxConcurrentOperationsExpected = expectations.maxConcurrentOperationsDetectedCount {
                XCTAssertLessThanOrEqual(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount, maxConcurrentOperationsExpected, "maxConcurrentOperationsDetectedCount (\(results.concurrencyRegistrar.maxConcurrentOperationsDetectedCount)) is greater than expected maximum: \(maxConcurrentOperationsExpected)")
            }
        }
        // minimumDurationInSeconds
        if let minimumDuration = expectations.minimumDurationInSeconds {
            XCTAssertGreaterThanOrEqual(results.duration, minimumDuration, "Test duration exceeded minimum expected duration.")
        }
    }

    open override func setUp() {
        super.setUp()
        concurrencyRegistrar = ConcurrencyRegistrar()
    }

    open override func tearDown() {
        concurrencyRegistrar = nil
        super.tearDown()
    }
}

// MARK: - ConcurrencyRegistrar

open class ConcurrencyRegistrar {
    private let _sharedRunningOperations = Protector([Operation]())
    private let _maxConcurrentOperationsDetectedCount = Protector(Int(0))
    public var maxConcurrentOperationsDetectedCount: Int {
        get {
            return _maxConcurrentOperationsDetectedCount.read { $0 }
        }
    }
    private func recordOperationsCount(_ currentOperationsCount: Int) {
        _maxConcurrentOperationsDetectedCount.write { (ward) in
            if currentOperationsCount > ward {
                ward = currentOperationsCount
            }
        }
    }
    public func registerRunning(_ op: Operation) {
        _sharedRunningOperations.write { (runningOperations) in
            runningOperations.append(op)
            self.recordOperationsCount(runningOperations.count)
        }
    }
    public func deregisterRunning(_ op: Operation) {
        _sharedRunningOperations.write { (runningOperations) in
            if let foundOperation = runningOperations.index(of: op) {
                runningOperations.remove(at: foundOperation)
            }
        }
    }
    public func atLeastOneOperationIsRunning(otherThan exception: Operation? = nil) -> Bool {
        return _sharedRunningOperations.read { runningOperations -> Bool in
            for op in runningOperations {
                if op !== exception {
                    return true
                }
            }
            return false
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
