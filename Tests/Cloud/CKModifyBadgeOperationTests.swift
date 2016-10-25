//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyBadgeOperation: TestCKOperation, CKModifyBadgeOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var badgeValue: Int = 0
    var error: Error? = nil
    var modifyBadgeCompletionBlock: ((Error?) -> Void)? = nil

    init(value: Int = 0, error: Error? = nil) {
        self.badgeValue = value
        self.error = error
        super.init()
    }

    override func main() {
        modifyBadgeCompletionBlock?(error)
    }
}

class CKModifyBadgeOperationTests: CKProcedureTestCase {

    var target: TestCKModifyBadgeOperation!
    var operation: CKProcedure<TestCKModifyBadgeOperation>!
    var badge: Int!

    override func setUp() {
        super.setUp()
        badge = 9
        target = TestCKModifyBadgeOperation(value: badge)
        operation = CKProcedure(operation: target)
    }

    func test__set_get__badgeValue() {
        let badgeValue = 4
        operation.badgeValue = badgeValue
        XCTAssertEqual(operation.badgeValue, badgeValue)
        XCTAssertEqual(target.badgeValue, badgeValue)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
