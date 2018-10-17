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

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
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
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
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
        operation.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchShareParticipantsOperationTests: CKProcedureTestCase {
    typealias T = TestCKFetchShareParticipantsOperation
    var cloudkit: CloudKitProcedure<T>!

    var setByShareParticipantFetchedBlock: (T.ShareParticipant)!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchShareParticipantsOperation() }
        cloudkit.container = container
        cloudkit.userIdentityLookupInfos = [ "user lookup info" ]
        cloudkit.shareParticipantFetchedBlock = { self.setByShareParticipantFetchedBlock = $0 }
    }

    override func tearDown() {
        cloudkit = nil
        setByShareParticipantFetchedBlock = nil
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

    func test__set_get_userIdentityLookupInfos() {
        cloudkit.userIdentityLookupInfos = [ "different user lookup info" ]
        XCTAssertEqual(cloudkit.userIdentityLookupInfos, [ "different user lookup info" ])
    }

    func test__set_get_shareParticipantFetchedBlock() {
        XCTAssertNotNil(cloudkit.shareParticipantFetchedBlock)
        cloudkit.shareParticipantFetchedBlock?("participant")
        XCTAssertEqual(setByShareParticipantFetchedBlock ?? "incorrect", "participant")
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
        cloudkit.setFetchShareParticipantsCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchShareParticipantsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchShareParticipantsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchShareParticipantsCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchShareParticipantsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchShareParticipantsOperation()
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
        cloudkit.setFetchShareParticipantsCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}
