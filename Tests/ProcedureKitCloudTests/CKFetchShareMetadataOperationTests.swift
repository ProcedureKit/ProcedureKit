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

class TestCKFetchShareMetadataOperation: TestCKOperation, CKFetchShareMetadataOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?
    var shareURLs: [URL] = []
    var shouldFetchRootRecord: Bool = false
    var rootRecordDesiredKeys: [String]? = nil
    var perShareMetadataBlock: ((URL, ShareMetadata?, Error?) -> Void)? = nil
    var fetchShareMetadataCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        fetchShareMetadataCompletionBlock?(error)
    }
}

class CKFetchShareMetadataOperationTests: CKProcedureTestCase {

    var target: TestCKFetchShareMetadataOperation!
    var operation: CKProcedure<TestCKFetchShareMetadataOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchShareMetadataOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__shareURLs() {
        let shareURLs = [ URL(string: "http://example.com")! ]
        operation.shareURLs = shareURLs
        XCTAssertEqual(operation.shareURLs, shareURLs)
        XCTAssertEqual(target.shareURLs, shareURLs)
    }

    func test__set_get__shouldFetchRootRecord() {
        var shouldFetchRootRecord = true
        operation.shouldFetchRootRecord = shouldFetchRootRecord
        XCTAssertEqual(operation.shouldFetchRootRecord, shouldFetchRootRecord)
        XCTAssertEqual(target.shouldFetchRootRecord, shouldFetchRootRecord)
        shouldFetchRootRecord = false
        operation.shouldFetchRootRecord = shouldFetchRootRecord
        XCTAssertEqual(operation.shouldFetchRootRecord, shouldFetchRootRecord)
        XCTAssertEqual(target.shouldFetchRootRecord, shouldFetchRootRecord)
    }

    func test__set_get__rootRecordDesiredKeys() {
        let rootRecordDesiredKeys = [ "recordKeyExample" ]
        operation.rootRecordDesiredKeys = rootRecordDesiredKeys
        XCTAssertNotNil(operation.rootRecordDesiredKeys)
        XCTAssertEqual(operation.rootRecordDesiredKeys ?? [], rootRecordDesiredKeys)
        XCTAssertNotNil(target.rootRecordDesiredKeys)
        XCTAssertEqual(target.rootRecordDesiredKeys ?? [], rootRecordDesiredKeys)
    }

    func test__set_get__perShareMetadataBlock() {
        var setByCompletionBlock = false
        let block: (URL, String?, Error?) -> Void = { shareURL, shareMetadata, error in
            setByCompletionBlock = true
        }
        operation.perShareMetadataBlock = block
        XCTAssertNotNil(operation.perShareMetadataBlock)
        target.perShareMetadataBlock?(URL(string: "http://example.com")!, "share metadata", nil)
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchShareMetadataCompletionBlock { didExecuteBlock = true }
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
        operation.setFetchShareMetadataCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchShareMetadataOperationTests: CKProcedureTestCase {
    typealias T = TestCKFetchShareMetadataOperation
    var cloudkit: CloudKitProcedure<T>!

    var setByPerShareMetadataBlock: (URL, T.ShareMetadata?, Error?)!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchShareMetadataOperation() }
        cloudkit.container = container
        cloudkit.shareURLs = [ URL(string: "http://url.com")! ]
        cloudkit.shouldFetchRootRecord = true
        cloudkit.rootRecordDesiredKeys = [ "key 1" ]
        cloudkit.perShareMetadataBlock = { [unowned self] url, metadata, error in
            self.setByPerShareMetadataBlock = (url, metadata, error)
        }
    }

    override func tearDown() {
        cloudkit = nil
        setByPerShareMetadataBlock = nil
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

    func test__set_get_shareURLs() {
        cloudkit.shareURLs = [ URL(string: "http://different-url.com")! ]
        XCTAssertEqual(cloudkit.shareURLs, [ URL(string: "http://different-url.com")! ])
    }

    func test__set_get_shouldFetchRootRecord() {
        cloudkit.shouldFetchRootRecord = false
        XCTAssertEqual(cloudkit.shouldFetchRootRecord, false)
    }

    func test__set_get_rootRecordDesiredKeys() {
        cloudkit.rootRecordDesiredKeys = [ "key 1", "key 2" ]
        XCTAssertEqual(cloudkit.rootRecordDesiredKeys ?? [], [ "key 1", "key 2" ])
    }

    func test__set_get_perShareMetadataBlock() {
        XCTAssertNotNil(cloudkit.perShareMetadataBlock)
        let url = URL(string: "http://different-url.com")!
        let error = TestError()
        cloudkit.perShareMetadataBlock?(url, "metadata", error)
        XCTAssertEqual(setByPerShareMetadataBlock?.0, url)
        XCTAssertEqual(setByPerShareMetadataBlock?.1, "metadata")
        XCTAssertEqual(setByPerShareMetadataBlock?.2 as? TestError ?? TestError(), error)
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
        cloudkit.setFetchShareMetadataCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchShareMetadataOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchShareMetadataOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchShareMetadataCompletionBlock {
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchShareMetadataOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchShareMetadataCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchShareMetadataOperation()
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
        cloudkit.setFetchShareMetadataCompletionBlock { didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

