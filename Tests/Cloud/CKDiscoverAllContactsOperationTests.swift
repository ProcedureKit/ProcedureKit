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

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllContactsCompletionBlock { _ in
            didExecuteBlock = true
        }
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
        operation.setDiscoverAllContactsCompletionBlock { _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

#endif
