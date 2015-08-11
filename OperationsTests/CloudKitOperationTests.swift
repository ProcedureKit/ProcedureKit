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
    var database: CKDatabase? {
        didSet {
            didSetDatabase = true
        }
    }
}

/**
    - Commenting out this test because in iOS 9 / Swift 2.0.
    accessing the default container causes the test suite
    to crash. And it's not possible to subclass CKDatabase

    - Will have to re-write the CloudKitOperation I think.

class CloudKitOperationTests: OperationTests {

    func test__database_property_is_set() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = CloudKitOperation(operation: TestableCloudKitOperation(), database: container.privateCloudDatabase)

        operation.addCompletionBlock {
            expectation.fulfill()
        }

        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.operation.didSetDatabase)
    }
}

*/