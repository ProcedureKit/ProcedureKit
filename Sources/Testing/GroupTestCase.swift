//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest

open class TestGroupProcedure: GroupProcedure {
    public private(set) var didExecute = false

    open override func execute() {
        didExecute = true
        super.execute()
    }
}

open class GroupTestCase: ProcedureKitTestCase {

    public var children: [TestProcedure]!
    public var group: TestGroupProcedure!

    public func createTestProcedures(count: Int = 5, shouldError: Bool = false) -> [TestProcedure] {
        return (0..<count).map { i in
            let name = "Child: \(i)"
            return shouldError ? TestProcedure(name: name, error: TestError()) : TestProcedure(name: name)
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

// MARK: - GroupConcurrencyTestCase

open class GroupConcurrencyTestCase: ConcurrencyTestCase {

    public class GroupTestResult: TestResult {
        public let group: TestGroupProcedure

        public init(group: TestGroupProcedure, procedures: [TrackingProcedure], duration: TimeInterval, registrar: Registrar) {
            self.group = group
            super.init(procedures: procedures, duration: duration, registrar: registrar)
        }
    }

    public func concurrencyTestGroup(children: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestGroupProcedure) -> Void, withExpectations expectations: Expectations) {

        concurrencyTestGroup(children: children, withDelayMicroseconds: delayMicroseconds, withName: name, withTimeout: timeout,
            withConfigureBlock: configure,
            completionBlock: { (results) in
                XCTAssertResults(results, matchExpectations: expectations)
        })
    }

    public func concurrencyTestGroup(children: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TestGroupProcedure) -> Void, completionBlock completion: (GroupTestResult) -> Void) {

        let registrar = Registrar()
        let testProcedures = create(procedures: children, delayMicroseconds: delayMicroseconds, withRegistrar: registrar)
        let group = TestGroupProcedure(operations: testProcedures)

        configure(group)

        let startTime = CFAbsoluteTimeGetCurrent()
        wait(for: group, withTimeout: timeout)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        completion(GroupTestResult(group: group, procedures: testProcedures, duration: duration, registrar: registrar))
    }
}
