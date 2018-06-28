//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
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

    override func tearDown() {
        target = nil
        operation = nil
        badge = nil
        super.tearDown()
    }

    func test__set_get__badgeValue() {
        let badgeValue = 4
        operation.badgeValue = badgeValue
        XCTAssertEqual(operation.badgeValue, badgeValue)
        XCTAssertEqual(target.badgeValue, badgeValue)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        wait(for: operation)
        PKAssertProcedureFinished(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        let error = TestError()
        target.error = error
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureModifyBadgeOperationTests: CKProcedureTestCase {
    typealias T = TestCKModifyBadgeOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKModifyBadgeOperation() }
        cloudkit.container = container
        cloudkit.badgeValue = 10
    }

    override func tearDown() {
        cloudkit = nil
        super.tearDown()
    }

    func test__set_get__errorHandlers() {
        cloudkit.set(errorHandlers: [.internalError: cloudkit.passthroughSuggestedErrorHandler])
        XCTAssertEqual(cloudkit.errorHandlers.count, 1)
        XCTAssertNotNil(cloudkit.errorHandlers[.internalError])
    }

    func test__set_get_container() {
        cloudkit.container = "I'm a different container!"
        XCTAssertEqual(cloudkit.container, "I'm a different container!")
    }

    func test__set_get_badgeValue() {
        cloudkit.badgeValue = 100
        XCTAssertEqual(cloudkit.badgeValue, 100)
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        PKAssertProcedureCancelled(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setModifyBadgeCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyBadgeOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        let error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyBadgeOperation()
            operation.error = error
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setModifyBadgeCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyBadgeOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyBadgeOperation()
            if shouldError {
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.limitExceeded.rawValue, userInfo: nil)
                shouldError = false
            }
            return op
        }
        var didRunCustomHandler = false
        cloudkit.set(errorHandlerForCode: .limitExceeded) { _, _, _, suggestion in
            didRunCustomHandler = true
            return suggestion
        }

        var didExecuteBlock = false
        cloudkit.setModifyBadgeCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

