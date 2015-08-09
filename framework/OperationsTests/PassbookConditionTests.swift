//
//  PassbookConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class TestablePassLibrary: PassLibraryType {
    let enabled: Bool

    init(enabled: Bool) {
        self.enabled = enabled
    }

    func isPassLibraryAvailable() -> Bool {
        return enabled
    }
}

class PassbookConditionTests: OperationTests {

    func test__condition_succeeds__when_library_is_available() {

        let library = TestablePassLibrary(enabled: true)

        let operation = TestOperation()
        operation.addCondition(PassbookCondition(library: library))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)

    }

    func test__condition_fails__when_library_is_not_available() {
        let library = TestablePassLibrary(enabled: false)

        let operation = TestOperation()
        operation.addCondition(PassbookCondition(library: library))

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? PassbookCondition.Error {
            switch error {
            case .LibraryNotAvailable:
                break // Great
            }
        }
        else {
            XCTFail("Error message not received.")
        }
    }
}

