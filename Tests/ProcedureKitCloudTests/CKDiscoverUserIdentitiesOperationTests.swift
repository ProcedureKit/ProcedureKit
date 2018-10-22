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

class TestCKDiscoverUserIdentitiesOperation: TestCKOperation, CKDiscoverUserIdentitiesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?
    var userIdentityLookupInfos: [UserIdentityLookupInfo] = []
    var userIdentityDiscoveredBlock: ((UserIdentity, UserIdentityLookupInfo) -> Void)? = nil
    var discoverUserIdentitiesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        discoverUserIdentitiesCompletionBlock?(error)
    }
}

class CKDiscoverUserIdentitiesOperationTests: CKProcedureTestCase {

    var target: TestCKDiscoverUserIdentitiesOperation!
    var operation: CKProcedure<TestCKDiscoverUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDiscoverUserIdentitiesOperation()
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

    func test__set_get__userIdentityDiscoveredBlock() {
        var setByCompletionBlock = false
        let block: (String, String) -> Void = { identity, lookupInfo in
            setByCompletionBlock = true
        }
        operation.userIdentityDiscoveredBlock = block
        XCTAssertNotNil(operation.userIdentityDiscoveredBlock)
        target.userIdentityDiscoveredBlock?("Example", "hello@world.com")
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
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
        operation.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureDiscoverUserIdentitiesOperationTests: CKProcedureTestCase {

    var setByUserIdentityDiscoveredBlock = false
    var cloudkit: CloudKitProcedure<TestCKDiscoverUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKDiscoverUserIdentitiesOperation() }
        cloudkit.container = container
        cloudkit.userIdentityLookupInfos = [ "user lookup info" ]
        cloudkit.userIdentityDiscoveredBlock = { [weak self] _, _ in
            self?.setByUserIdentityDiscoveredBlock = true
        }
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

    func test__set_get_userIdentityLookupInfos() {
        cloudkit.userIdentityLookupInfos = [ "user lookup info" ]
        XCTAssertEqual(cloudkit.userIdentityLookupInfos, [ "user lookup info" ])
    }

    func test__set_get_userIdentityDiscoveredBlock() {
        XCTAssertNotNil(cloudkit.userIdentityDiscoveredBlock)
        cloudkit.userIdentityDiscoveredBlock?("user identity", "user lookup info")
        XCTAssertTrue(setByUserIdentityDiscoveredBlock)
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
        cloudkit.setDiscoverUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setDiscoverUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverUserIdentitiesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverUserIdentitiesOperation()
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
        cloudkit.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}
