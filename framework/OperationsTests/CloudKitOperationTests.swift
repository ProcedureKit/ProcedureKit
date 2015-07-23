//
//  CloudKitOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CloudKit
import Operations

class TestableCloudKitOperation: TestOperation, CloudKitOperationType {

    var didSetDatabase = false
    var database: CKDatabase! {
        didSet {
            didSetDatabase = true
        }
    }
}

class CloudKitOperationTests: OperationTests {

    func test__database_property_is_set() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = CloudKitOperation(operation: TestableCloudKitOperation())

        operation.addCompletionBlock {
            expectation.fulfill()
        }

        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.operation.didSetDatabase)
    }
}
