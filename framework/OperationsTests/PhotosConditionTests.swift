//
//  PhotosConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import XCTest
import Photos
import Operations

class TestablePhotoLibrary: PhotosManagerType {

    var status: PHAuthorizationStatus
    var authorizationAllowed = false
    var didRequestAuthorization = false

    init(status: PHAuthorizationStatus = .NotDetermined, authorizationAllowed: Bool = false) {
        self.status = status
        self.authorizationAllowed = authorizationAllowed
    }

    func authorizationStatus() -> PHAuthorizationStatus {
        return status
    }

    func requestAuthorization(handler: PHAuthorizationStatus -> Void) {
        didRequestAuthorization = true
        status = authorizationAllowed ? .Authorized : .Denied
        handler(status)
    }
}

class PhotosConditionTests: OperationTests {

    func test__condition_succeeds__when_access_is_authorized() {

        let manager = TestablePhotoLibrary(status: .Authorized)
        let operation = TestOperation()
        operation.addCondition(PhotosCondition(manager: manager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
    }

    func test__condition_fails__when_access_is_denied() {

        let manager = TestablePhotoLibrary(status: .Denied)
        let operation = TestOperation()
        operation.addCondition(PhotosCondition(manager: manager))


        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? PhotosCondition.Error {
            XCTAssertEqual(error, PhotosCondition.Error.AuthorizationNotAuthorized(.Denied))
        }
        else {
            XCTFail("Error message not received.")
        }
    }

    func test__condition_triggers_request__when_access_is_not_determined() {

        let manager = TestablePhotoLibrary(authorizationAllowed: true)
        let operation = TestOperation()
        operation.addCondition(PhotosCondition(manager: manager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(manager.didRequestAuthorization)
    }
}

#endif

