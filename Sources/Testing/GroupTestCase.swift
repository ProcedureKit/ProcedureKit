//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class GroupTestCase: ProcedureKitTestCase<Group> {

    public var children: [TestProcedure]!

    public var group: Group {
        get { return target }
        set { target = newValue }
    }

    func createTestProcedures(count: Int = 5) -> [TestProcedure] {
        return (0..<count).map { _ in TestProcedure() }
    }

    open override func setUp() {
        super.setUp()
        children = createTestProcedures()
        target = Group(operations: children)
    }

    open override func tearDown() {
        target.cancel()
        children = nil
        super.tearDown()
    }

}
