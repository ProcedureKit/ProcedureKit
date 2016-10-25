//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
