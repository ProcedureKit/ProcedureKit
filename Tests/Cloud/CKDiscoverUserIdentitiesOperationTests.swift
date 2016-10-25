//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
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
        operation.setDiscoverUserIdentitiesCompletionBlock { didExecuteBlock = true }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
