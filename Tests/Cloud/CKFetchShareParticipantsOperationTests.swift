//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchShareParticipantsOperation: TestCKOperation, CKFetchShareParticipantsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?

    var userIdentityLookupInfos: [UserIdentityLookupInfo] = []
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? = nil
    var fetchShareParticipantsCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        fetchShareParticipantsCompletionBlock?(error)
    }
}

class CKFetchShareParticipantsOperationTests: CKProcedureTestCase {

    var target: TestCKFetchShareParticipantsOperation!
    var operation: CKProcedure<TestCKFetchShareParticipantsOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchShareParticipantsOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__userIdentityLookupInfos() {
        let userIdentityLookupInfos = [ "hello@world.com" ]
        operation.userIdentityLookupInfos = userIdentityLookupInfos
        XCTAssertEqual(operation.userIdentityLookupInfos, userIdentityLookupInfos)
        XCTAssertEqual(target.userIdentityLookupInfos, userIdentityLookupInfos)
    }

    func test__set_get__shareParticipantFetchedBlock() {
        var setByCompletionBlock = false
        let block: (String) -> Void = { participant in
            setByCompletionBlock = true
        }
        operation.shareParticipantFetchedBlock = block
        XCTAssertNotNil(operation.shareParticipantFetchedBlock)
        target.shareParticipantFetchedBlock?("hello@world.com")
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
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
        operation.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
