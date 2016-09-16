//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

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
