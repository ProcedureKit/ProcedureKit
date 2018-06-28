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

class TestCKDiscoverAllContactsOperation: TestCKOperation, CKDiscoverAllContactsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>

    var result: [DiscoveredUserInfo]?
    var error: Error?
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, Error?) -> Void)? = nil

    init(result: [DiscoveredUserInfo]? = nil, error: Error? = nil) {
        self.result = result
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllContactsCompletionBlock?(result, error)
    }
}
    
class CKDiscoverAllContactsOperationTests: CKProcedureTestCase {

    var target: TestCKDiscoverAllContactsOperation!
    var operation: CKProcedure<TestCKDiscoverAllContactsOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDiscoverAllContactsOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllContactsCompletionBlock { _ in
            didExecuteBlock = true
        }
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
        operation.setDiscoverAllContactsCompletionBlock { _ in didExecuteBlock = true }
        let error = TestError()
        target.error = error
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureDiscoverAllContactsOperationTests: CKProcedureTestCase {

    var cloudkit: CloudKitProcedure<TestCKDiscoverAllContactsOperation>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKDiscoverAllContactsOperation(result: [ "user info" ]) }
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
        var didSetDiscoveredUserInfo: [TestCKDiscoverAllContactsOperation.DiscoveredUserInfo]? = nil
        cloudkit.setDiscoverAllContactsCompletionBlock { didSetDiscoveredUserInfo = $0 }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertEqual(didSetDiscoveredUserInfo?.first ?? "not user info", "user info")
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllContactsOperation(result: [ "user info" ])
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        let error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKDiscoverAllContactsOperation(result: [ "user info" ])
            operation.error = error
            return operation
        }

        var didSetDiscoveredUserInfo: [TestCKDiscoverAllContactsOperation.DiscoveredUserInfo]? = nil
        cloudkit.setDiscoverAllContactsCompletionBlock { didSetDiscoveredUserInfo = $0 }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertNil(didSetDiscoveredUserInfo)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverAllContactsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setDiscoverAllContactsCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKDiscoverAllContactsOperation()
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
        cloudkit.setDiscoverAllContactsCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }

}

#endif
