//
//  HealthCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import HealthKit
@testable import Operations

class TestableHealthRegistrar: NSObject {

    var healthDataAvailable = true
    var didCheckHealthDataAvailable = false

    var allowedForSharing: Set<HKSampleType> = Set()
    var didCheckAuthorizationStatusForTypes: Set<HKObjectType>? = .None

    var accessError: NSError? = .None
    var didRequestAccessForRequirement: HealthRequirement? = .None

    required override init() { }

    func addAuthorizationStatusCheckForType(type: HKObjectType) {
        didCheckAuthorizationStatusForTypes = didCheckAuthorizationStatusForTypes ?? Set()
        didCheckAuthorizationStatusForTypes!.insert(type)
    }
}

extension TestableHealthRegistrar: HealthCapabilityRegistrarType {

    func opr_isHealthDataAvailable() -> Bool {
        didCheckHealthDataAvailable = true
        return healthDataAvailable
    }

    func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus {
        addAuthorizationStatusCheckForType(type)
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

    func opr_requestAuthorizationForRequirement(requirement: HealthRequirement, completion: (Bool, NSError?) -> Void) {
        didRequestAccessForRequirement = requirement

        if !requirement.share.isEmpty {
            completion(allowedForSharing.isSupersetOf(requirement.share), accessError)
        }
        else {
            completion(true, accessError)
        }
    }
}

class HealthTests: XCTestCase {

    var types: Set<HKSampleType>!
    var requirement: HealthRequirement!
    var status: HealthCapabilityStatus!

    func sampleTypes() -> Set<HKSampleType> {
        let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let mass = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        let height = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        return Set([ heartRate!, mass!, height! ])
    }

    override func setUp() {
        super.setUp()
        types = sampleTypes()
        requirement = HealthRequirement(toShare: types)
        status = HealthCapabilityStatus()
    }

    override func tearDown() {
        types = nil
        requirement = nil
        status = nil
    }
}

class HealthRequirementTests: HealthTests {

    func test__that_to_share_types_are_set() {
        XCTAssertEqual(requirement.share, types)
        XCTAssertTrue(requirement.read.isEmpty)
    }

    func test__that_to_read_types_are_set() {
        let types = sampleTypes()
        let requirement = HealthRequirement(toRead: types)
        XCTAssertEqual(requirement.read, types)
        XCTAssertTrue(requirement.share.isEmpty)
    }

    func test__that_share_identifiers_is_correct() {
        XCTAssertEqual(requirement.shareIdentifiers, Set(types.map { $0.identifier }))
    }
}

class HeathCapabilityStatusTests: HealthTests {

    func test__empty_status_does_not_meet_requirements() {
        XCTAssertFalse(status.isRequirementMet(requirement))
    }

    func test__setting_status_for_types() {
        status[HKQuantityTypeIdentifierHeartRate] = HKAuthorizationStatus.SharingAuthorized
        XCTAssertEqual(status.dictionary.count, 1)
    }

    func test__reading_status_for_types() {
        status[HKQuantityTypeIdentifierHeartRate] = HKAuthorizationStatus.SharingAuthorized
        XCTAssertEqual(status[HKQuantityTypeIdentifierHeartRate], HKAuthorizationStatus.SharingAuthorized)
    }

    func test__all_authorized_status_meet_requirements() {
        for id in requirement.shareIdentifiers {
            status[id] = .SharingAuthorized
        }
        XCTAssertTrue(status.isRequirementMet(requirement))
    }

    func test__when_only_partial_authorization_overall_requirements_not_met() {
        status[HKQuantityTypeIdentifierHeartRate] = HKAuthorizationStatus.SharingAuthorized
        status[HKQuantityTypeIdentifierHeight] = HKAuthorizationStatus.SharingAuthorized
        XCTAssertFalse(status.isRequirementMet(requirement))
    }

    func test__when_mixed_authorization_status_overall_requirements_not_met() {
        status[HKQuantityTypeIdentifierHeartRate] = HKAuthorizationStatus.SharingAuthorized
        status[HKQuantityTypeIdentifierBodyMass] = HKAuthorizationStatus.SharingDenied
        status[HKQuantityTypeIdentifierHeight] = HKAuthorizationStatus.SharingAuthorized
        XCTAssertFalse(status.isRequirementMet(requirement))
    }
}

class HeathCapabilityTests: HealthTests {

    var registrar: TestableHealthRegistrar!
    var capability: HealthCapability!

    override func setUp() {
        super.setUp()
        registrar = TestableHealthRegistrar()
        capability = HealthCapability(requirement)
        capability.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__name() {
        XCTAssertEqual(capability.name, "Health")
    }

    func test__requirement_is_set() {
        XCTAssertEqual(capability.requirement, requirement)
    }

    func test__is_available_queries_registrar() {
        XCTAssertTrue(capability.isAvailable())
        XCTAssertTrue(registrar.didCheckHealthDataAvailable)
    }

    func test__authorization_status_queries_register() {
        capability.authorizationStatus { XCTAssertEqual($0.count, 3) }
        XCTAssertNotNil(registrar.didCheckAuthorizationStatusForTypes)
        XCTAssertEqual(registrar.didCheckAuthorizationStatusForTypes, requirement.share)
    }

    func test__given_service_disabled__requesting_authorization_returns_directly() {
        registrar.healthDataAvailable = false
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertTrue(registrar.didCheckHealthDataAvailable)
        XCTAssertNil(registrar.didRequestAccessForRequirement)
        XCTAssertTrue(didComplete)
    }

    func test__given_no_requirements__requesting_authorization_returns_directly() {
        requirement = HealthRequirement()
        capability = HealthCapability(requirement)
        capability.registrar = registrar

        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertTrue(registrar.didCheckHealthDataAvailable)
        XCTAssertNil(registrar.didRequestAccessForRequirement)
        XCTAssertTrue(didComplete)
    }

    func test__request_authorization_is_made() {
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertNotNil(registrar.didRequestAccessForRequirement)
        XCTAssertEqual(registrar.didRequestAccessForRequirement, requirement)
        XCTAssertTrue(didComplete)
    }
}
