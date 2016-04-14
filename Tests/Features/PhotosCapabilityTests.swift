//
//  PhotosCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Photos
@testable import Operations

class TestablePhotosRegistrar: NSObject {

    var authorizationStatus: PHAuthorizationStatus = .NotDetermined
    var didCheckAuthorizationStatus = false

    var responseStatus: PHAuthorizationStatus = .Authorized
    var accessError: NSError? = .None
    var didRequestAuthorization = false

    required override init() { }
}

extension TestablePhotosRegistrar: PhotosCapabilityRegistrarType {

    func opr_authorizationStatus() -> PHAuthorizationStatus {
        didCheckAuthorizationStatus = true
        return authorizationStatus
    }

    func opr_requestAuthorization(handler: PHAuthorizationStatus -> Void) {
        didRequestAuthorization = true
        authorizationStatus = responseStatus
        handler(authorizationStatus)
    }
}

class PHAuthorizationStatusTests: XCTestCase {

    func test__given_not_determined_requirement_not_met() {
        let status = PHAuthorizationStatus.NotDetermined
        XCTAssertFalse(status.isRequirementMet())
    }

    func test__given_restricted_requirement_not_met() {
        let status = PHAuthorizationStatus.Restricted
        XCTAssertFalse(status.isRequirementMet())
    }

    func test__given_denied_requirement_not_met() {
        let status = PHAuthorizationStatus.Denied
        XCTAssertFalse(status.isRequirementMet())
    }

    func test__given_authorized_requirement_met() {
        let status = PHAuthorizationStatus.Authorized
        XCTAssertTrue(status.isRequirementMet())
    }
}

class PhotosCapabilityTests: XCTestCase {
    var registrar: TestablePhotosRegistrar!
    var capability: PhotosCapability!

    override func setUp() {
        super.setUp()
        registrar = TestablePhotosRegistrar()
        capability = PhotosCapability()
        capability.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__name() {
        XCTAssertEqual(capability.name, "Photos")
    }

    func test__is_available_always() {
        XCTAssertTrue(capability.isAvailable())
    }

    func test__authorization_status_queries_register() {
        capability.authorizationStatus { XCTAssertEqual($0, PHAuthorizationStatus.NotDetermined) }
        XCTAssertTrue(registrar.didCheckAuthorizationStatus)
    }

    func test__given_not_determined_request_authorization() {
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertTrue(registrar.didRequestAuthorization)
        XCTAssertTrue(didComplete)
    }

    func test__given_denied_does_not_request() {
        registrar.authorizationStatus = .Denied
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertFalse(registrar.didRequestAuthorization)
        XCTAssertTrue(didComplete)
    }

    func test__given_authorized_does_not_request() {
        registrar.authorizationStatus = .Authorized
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertFalse(registrar.didRequestAuthorization)
        XCTAssertTrue(didComplete)
    }

    func test__default_registrar() {
        XCTAssertNotNil(PhotosCapability().registrar.opr_authorizationStatus())
    }
}
