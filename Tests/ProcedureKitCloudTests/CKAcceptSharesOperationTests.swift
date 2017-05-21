//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKAcceptSharesOperation: TestCKOperation, CKAcceptSharesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error? = nil
    var shareMetadatas: [ShareMetadata] = []
    var perShareCompletionBlock: ((ShareMetadata, Share?, Error?) -> Void)? = nil
    var acceptSharesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        acceptSharesCompletionBlock?(error)
    }
}

class CKAcceptSharesOperationTests: CKProcedureTestCase {

    var target: TestCKAcceptSharesOperation!
    var operation: CKProcedure<TestCKAcceptSharesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKAcceptSharesOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__shareMetadatas() {
        let shareMetaddatas = [ "hello@world.com" ]
        operation.shareMetadatas = shareMetaddatas
        XCTAssertEqual(operation.shareMetadatas, shareMetaddatas)
        XCTAssertEqual(target.shareMetadatas, shareMetaddatas)
    }

    func test__set_get__perShareCompletionBlock() {
        var setByCompletionBlock = false
        let block: (String, String?, Error?) -> Void = { metadata, share, error in
            setByCompletionBlock = true
        }
        operation.perShareCompletionBlock = block
        XCTAssertNotNil(operation.perShareCompletionBlock)
        target.perShareCompletionBlock?("hello@world.com", "share", nil)
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setAcceptSharesCompletionBlock { didExecuteBlock = true }
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
        operation.setAcceptSharesCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureAcceptSharesOperationTests: CKProcedureTestCase {
    typealias T = TestCKAcceptSharesOperation
    var shareMetadatas: [T.ShareMetadata]!
    var setByBlockPerShareCompletionBlock: Bool!
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        shareMetadatas = [ "hello@world.com" ]
        setByBlockPerShareCompletionBlock = false
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKAcceptSharesOperation() }
        cloudkit.container = container
        cloudkit.shareMetadatas = shareMetadatas
        cloudkit.perShareCompletionBlock = { [weak self] _, _, _ in
            self?.setByBlockPerShareCompletionBlock = true
        }
    }

    override func tearDown() {
        shareMetadatas = nil
        setByBlockPerShareCompletionBlock = false
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

    func test__set_get_shareMetadatas() {
        cloudkit.shareMetadatas = [ "hello-again@world.com" ]
        XCTAssertEqual(cloudkit.shareMetadatas, [ "hello-again@world.com" ])
    }

    func test__set_get_perShareCompletionBlock() {
        XCTAssertNotNil(cloudkit.perShareCompletionBlock)
        cloudkit.perShareCompletionBlock?("share metadata", "accepted share", nil)
        XCTAssertTrue(setByBlockPerShareCompletionBlock)
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
        cloudkit.setAcceptSharesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKAcceptSharesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKAcceptSharesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        var didExecuteBlock = false
        cloudkit.setAcceptSharesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKAcceptSharesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setAcceptSharesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKAcceptSharesOperation()
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
        cloudkit.setAcceptSharesCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
}

#endif

