//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDiscoverUserInfosOperation: TestCKOperation, CKDiscoverUserInfosOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

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

    func test__set_get__emailAddresses() {
        let emailAddresses = [ "hello@world.com" ]
        operation.emailAddresses = emailAddresses
        XCTAssertNotNil(operation.emailAddresses)
        XCTAssertEqual(operation.emailAddresses!.count, 1)
        XCTAssertEqual(operation.emailAddresses!, emailAddresses)
        XCTAssertNotNil(target.emailAddresses)
        XCTAssertEqual(target.emailAddresses!.count, 1)
        XCTAssertEqual(target.emailAddresses!, emailAddresses)
    }

    func test__set_get__userRecordIDs() {
        let userRecordIDs = [ "userRecordID" ]
        operation.userRecordIDs = userRecordIDs
        XCTAssertNotNil(operation.userRecordIDs)
        XCTAssertEqual(operation.userRecordIDs!.count, 1)
        XCTAssertEqual(operation.userRecordIDs!, userRecordIDs)
        XCTAssertNotNil(target.userRecordIDs)
        XCTAssertEqual(target.userRecordIDs!.count, 1)
        XCTAssertEqual(target.userRecordIDs!, userRecordIDs)
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
