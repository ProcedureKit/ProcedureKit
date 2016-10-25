//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

import XCTest
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
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
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
        operation.setDiscoverAllUserIdentitiesCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

#endif
