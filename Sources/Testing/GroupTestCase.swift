//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class GroupTestCase: ProcedureKitTestCase {

    public var children: [TestProcedure]!
    public var group: Group!

    func createTestProcedures(count: Int = 5) -> [TestProcedure] {
        return (0..<count).map { i in TestProcedure(name: "Child: \(i)") }
    }

    open override func setUp() {
        super.setUp()
        children = createTestProcedures()
        group = Group(operations: children)
        group.log.severity = .verbose
    }

    open override func tearDown() {
        group.cancel()
        children = nil
        super.tearDown()
    }
}
