//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDiscoverUserInfosOperation: TestCKOperation, CKDiscoverUserInfosOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = DiscoverUserInfosError<RecordID, DiscoveredUserInfo>

    var emailAddresses: [String]?
    var userRecordIDs: [RecordID]?
    var userInfosByEmailAddress: [String: DiscoveredUserInfo]? = nil
    var userInfoByRecordID: [RecordID: DiscoveredUserInfo]? = nil
    var error: Error? = nil
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, Error?) -> Void)? = nil

    init(userInfosByEmailAddress: [String: DiscoveredUserInfo]? = nil, userInfoByRecordID: [RecordID: DiscoveredUserInfo]? = nil, error: Error? = nil) {
        self.userInfosByEmailAddress = userInfosByEmailAddress
        self.userInfoByRecordID = userInfoByRecordID
        self.error = error
        super.init()
    }

    override func main() {
        discoverUserInfosCompletionBlock?(userInfosByEmailAddress, userInfoByRecordID, error)
    }
}

class CKDiscoverUserInfosOperationTests: CKProcedureTestCase {

    var target: TestCKDiscoverUserInfosOperation!
    var operation: CKProcedure<TestCKDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__emailAddresses() {
        let emailAddresses = [ "hello@world.com" ]
        operation.emailAddresses = emailAddresses
        XCTAssertEqual(operation.emailAddresses ?? [], emailAddresses)
        XCTAssertEqual(target.emailAddresses ?? [], emailAddresses)
    }

    func test__set_get__userRecordIDs() {
        let userRecordIDs = [ "userRecordID" ]
        operation.userRecordIDs = userRecordIDs
        XCTAssertEqual(operation.userRecordIDs ?? [], userRecordIDs)
        XCTAssertEqual(target.userRecordIDs ?? [], userRecordIDs)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        var userInfosByEmailAddress: [String: TestCKDiscoverUserInfosOperation.DiscoveredUserInfo]? = .none
        var userInfoByRecordID: [TestCKDiscoverUserInfosOperation.RecordID: TestCKDiscoverUserInfosOperation.DiscoveredUserInfo]? = .none
        operation.setDiscoverUserInfosCompletionBlock { byEmail, byRecordID in
            userInfosByEmailAddress = byEmail
            userInfoByRecordID = byRecordID
            didExecuteBlock = true
        }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertNotNil(userInfosByEmailAddress)
        XCTAssertTrue(userInfosByEmailAddress?.isEmpty ?? false)
        XCTAssertNotNil(userInfoByRecordID)
        XCTAssertTrue(userInfoByRecordID?.isEmpty ?? false)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverUserInfosCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureDiscoverUserInfosOperationTests: CKProcedureTestCase {

    var setByUserIdentityDiscoveredBlock = false
    var cloudkit: CloudKitProcedure<TestCKDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKDiscoverUserInfosOperation() }
        cloudkit.container = container
        cloudkit.emailAddresses = [ "hello@world.com" ]
        cloudkit.userRecordIDs = [ "hello user" ]
    }

    override func tearDown() {
        setByUserIdentityDiscoveredBlock = false
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

    func test__set_get_emailAddresses() {
        cloudkit.emailAddresses = [ "hello@world.com" ]
        XCTAssertEqual(cloudkit.emailAddresses ?? [], [ "hello@world.com" ])
    }

    func test__set_get_userRecordIDs() {
        cloudkit.userRecordIDs = [ "hello user" ]
        XCTAssertEqual(cloudkit.userRecordIDs ?? [], [ "hello user" ])
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        XCTAssertProcedureCancelledWithoutErrors(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setDiscoverUserInfosCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverUserInfosOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverUserInfosOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setDiscoverUserInfosCompletionBlock { _, _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverUserInfosOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setDiscoverUserInfosCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverUserInfosOperation()
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
        cloudkit.setDiscoverUserInfosCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

