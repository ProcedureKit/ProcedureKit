//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class CloudKitCapabilityTests: ProcedureKitTestCase {

    var container: TestableCloudKitContainerRegistrar!
    var capability: Capability.CloudKit!

    override func setUp() {
        super.setUp()
        container = TestableCloudKitContainerRegistrar()
        capability = Capability.CloudKit()
        capability.storedRegistrar = container
    }

    override func tearDown() {
        container = nil
        capability = nil
        super.tearDown()
    }

    func test__cloud_kit_is_available() {
        XCTAssertTrue(capability.isAvailable())
    }

    // Getting status

    func test__given_status_could_not_be_determined__authorization_status_queries_the_registrar() {
        capability.getAuthorizationStatus { status in
            XCTAssertEqual(status.account, .couldNotDetermine)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
        XCTAssertTrue(container.didGetAccountStatus)
    }

    func test__given_status_is_available_but_with_no_permissions__does_not_get_status_for_permissions() {
        container.accountStatus = .available
        capability.getAuthorizationStatus { status in
            XCTAssertEqual(status.account, .available)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
        XCTAssertTrue(container.didGetAccountStatus)
        XCTAssertFalse(container.didVerifyApplicationStatus)
    }

    func test__given_status_is_available_but_with_permissions__does_not_get_status_for_permissions() {
        capability = Capability.CloudKit([ .userDiscoverability ])
        capability.storedRegistrar = container
        container.accountStatus = .available
        capability.getAuthorizationStatus { status in
            XCTAssertEqual(status.account, .available)
            XCTAssertNotNil(status.permissions)
            XCTAssertEqual(status.permissions, .initialState)
            XCTAssertNil(status.error)
        }
        XCTAssertTrue(container.didGetAccountStatus)
        XCTAssertTrue(container.didVerifyApplicationStatus)
    }

    func test__no_account_status() {
        container.accountStatus = .noAccount
        capability.getAuthorizationStatus { status in
            XCTAssertEqual(status.account, .noAccount)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
        XCTAssertTrue(container.didGetAccountStatus)
        XCTAssertFalse(container.didVerifyApplicationStatus)
    }

    func test__restricted_account_status() {
        container.accountStatus = .restricted
        capability.getAuthorizationStatus { status in
            XCTAssertEqual(status.account, .restricted)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
        XCTAssertTrue(container.didGetAccountStatus)
        XCTAssertFalse(container.didVerifyApplicationStatus)
    }

    // Requesting Authorization

    func test__request_permissions() {
        let exp = expectation(description: "Test: \(#function)")
        container.accountStatus = .available
        capability = Capability.CloudKit([ .userDiscoverability ])
        capability.storedRegistrar = container
        capability.requestAuthorization {
            DispatchQueue.main.async { exp.fulfill() }
        }
        waitForExpectations(timeout: 3)
        XCTAssertTrue(container.didGetAccountStatus)
        XCTAssertTrue(container.didVerifyApplicationStatus)
        XCTAssertTrue(container.didRequestApplicationStatus)
    }
}

class CloudKitStatusTests: XCTestCase {
    var error: Error!
    var status: CloudKitStatus!

    override func setUp() {
        super.setUp()
        error = TestError()
    }

    override func tearDown() {
        error = nil
        super.tearDown()
    }

    func test__given_status_is_available__with_error__does_not_meet_requirements() {
        status = CloudKitStatus(account: .available, permissions: nil, error: error)
        XCTAssertFalse(status.meets(requirement: [.userDiscoverability]))
    }

    func test__given_status_is_available__with_error__does_not_meet_empty_requirements() {
        status = CloudKitStatus(account: .available, permissions: nil, error: error)
        XCTAssertFalse(status.meets(requirement: []))
    }

    func test__given_status_is_available__with_error__does_not_meet_nil_requirements() {
        status = CloudKitStatus(account: .available, permissions: nil, error: error)
        XCTAssertFalse(status.meets(requirement: nil))
    }

    func test__given_status_is_available__does_meet_empty_requirements() {
        status = CloudKitStatus(account: .available, permissions: nil, error: nil)
        XCTAssertTrue(status.meets(requirement: []))
    }

    func test__given_status_is_available__does_meet_nil_requirements() {
        status = CloudKitStatus(account: .available, permissions: nil, error: nil)
        XCTAssertTrue(status.meets(requirement: nil))
    }

    func test__given_status_is_available__with_granted_permissions__does_meet_requirements() {
        status = CloudKitStatus(account: .available, permissions: .granted, error: nil)
        XCTAssertTrue(status.meets(requirement: [.userDiscoverability]))
    }

    func test__given_status_is_available__with_granted_permissions__does_meet_empty_requirements() {
        status = CloudKitStatus(account: .available, permissions: .granted, error: nil)
        XCTAssertTrue(status.meets(requirement: []))
    }

    func test__given_status_is_available__with_granted_permissions__does_meet_nil_requirements() {
        status = CloudKitStatus(account: .available, permissions: .granted, error: nil)
        XCTAssertTrue(status.meets(requirement: nil))
    }

    func test__given_status_is_available__with_no_permissions__does_not_meet_requirements() {
        status = CloudKitStatus(account: .noAccount, permissions: .denied, error: nil)
        XCTAssertFalse(status.meets(requirement: [.userDiscoverability]))
    }

    func test__given_status_is_no_account__with_granted_permissions__does_not_meet_empty_requirements() {
        status = CloudKitStatus(account: .noAccount, permissions: .granted, error: nil)
        XCTAssertFalse(status.meets(requirement: []))
    }
}

