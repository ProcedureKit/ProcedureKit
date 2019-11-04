//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDiscoverAllUserIdentitiesOperation: TestCKOperation, CKDiscoverAllUserIdentitiesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?
    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? = nil
    var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllUserIdentitiesCompletionBlock?(error)
    }
}

class CKDiscoverAllUserIdentitiesOperationTests: CKProcedureTestCase {

    var target: TestCKDiscoverAllUserIdentitiesOperation!
    var operation: CKProcedure<TestCKDiscoverAllUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDiscoverAllUserIdentitiesOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__userIdentityDiscoveredBlock() {
        var setByCompletionBlock = false
        let block: (String) -> Void = { identity in
            setByCompletionBlock = true
        }
        operation.userIdentityDiscoveredBlock = block
        XCTAssertNotNil(operation.userIdentityDiscoveredBlock)
        target.userIdentityDiscoveredBlock?("hello@world.com")
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
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
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        let error = TestError()
        target.error = error
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureDiscoverAllUserIdentitiesOperationTests: CKProcedureTestCase {

    var setByUserIdentityDiscoveredBlock = false
    var cloudkit: CloudKitProcedure<TestCKDiscoverAllUserIdentitiesOperation>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKDiscoverAllUserIdentitiesOperation() }
        cloudkit.container = container
        cloudkit.userIdentityDiscoveredBlock = { [weak self] _ in
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

    func test__set_get_userIdentityDiscoveredBlock() {
        XCTAssertNotNil(cloudkit.userIdentityDiscoveredBlock)
        cloudkit.userIdentityDiscoveredBlock?("user identity")
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
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllUserIdentitiesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverAllUserIdentitiesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverAllUserIdentitiesOperation()
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
        cloudkit.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
}

#endif
