//
//  CloudConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CloudKit

@testable
import Operations

class TestableCloudContainer: CloudContainer {

    let error: ErrorType?

    init(error: ErrorType? = .None) {
        self.error = error
    }

    func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void) {
        completion(error)
    }
}

class CloudConditionTests: OperationTests {

    func test__cloud_container_executes_when_available() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        let condition = CloudKitContainerCondition(container: TestableCloudContainer())
        operation.addCondition(condition)

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
        }
    }

}
