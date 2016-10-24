//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud
#if !os(tvOS)

class TestCKAcceptSharesOperation: TestCKOperation, CKAcceptSharesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>

    var error: Error?

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

#endif
