//
//  HealthConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import XCTest
import HealthKit
import Operations

class TestableHealthManager: HealthManagerType {

    var available: Bool
    var allowedForSharing: Set<HKSampleType>
    var didRequestAccess = false

    init(available: Bool = true, allowedForSharing: Set<HKSampleType>) {
        self.available = available
        self.allowedForSharing = allowedForSharing
    }

    func opr_isHealthDataAvailable() -> Bool {
        return available
    }

    func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus {
        if let sampleType = type as? HKSampleType {
            if allowedForSharing.contains(sampleType) {
                return .SharingAuthorized
            }
            else {
                return .SharingDenied
            }
        }
        return .NotDetermined
    }

    func opr_requestAuthorizationToShareTypes(typesToShare: Set<HKSampleType>?, readTypes typesToRead: Set<HKObjectType>?, completion: (Bool, NSError?) -> Void) {
        didRequestAccess = true
        let granted: Bool = {
            if let typesToShare = typesToShare {
                return self.allowedForSharing.isSupersetOf(typesToShare)
            }
            return true
        }()

        completion(granted, nil)
    }
}

class HealthConditionTests: OperationTests {

    let sampleTypes: [HKSampleType] = {
        let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let mass = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        let height = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        return [ heartRate, mass, height ]
    }()

    func test__condition_succeeds__when_access_is_authorized() {
        let manager = TestableHealthManager(allowedForSharing: Set(sampleTypes))

        let operation = TestOperation()
        operation.addCondition(HealthCondition(manager: manager, typesToWrite: Set(sampleTypes)))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
    }

    func test__condition_fails__when_health_data_is_not_available() {
        let manager = TestableHealthManager(available: false, allowedForSharing: Set(sampleTypes))

        let operation = TestOperation()
        operation.addCondition(HealthCondition(manager: manager, typesToWrite: Set(sampleTypes)))

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? HealthCondition.Error {
            switch error {
            case .HealthDataNotAvailable:
                break // expected
            case .UnauthorizedShareTypes(_):
                XCTFail("Incorrect error returned.")
            }
        } else {
            XCTFail("Error message not received.")
        }
    }

    func test__condition_fails__when_sharing_is_denied() {
        let manager = TestableHealthManager(available: true, allowedForSharing: Set(arrayLiteral: sampleTypes[0]))

        let operation = TestOperation()
        operation.addCondition(HealthCondition(manager: manager, typesToWrite: Set(sampleTypes)))

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
            })

        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? HealthCondition.Error {
            switch error {
            case .HealthDataNotAvailable:
                XCTFail("Incorrect error returned.")
            case .UnauthorizedShareTypes(let types):
                let expected = Set(arrayLiteral: sampleTypes[1], sampleTypes[2])
                XCTAssertEqual(types, expected)
            }
        } else {
            XCTFail("Error message not received.")
        }
    }
}

#endif

