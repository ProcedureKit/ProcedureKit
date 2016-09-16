//
//  CloudCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 04/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import CloudKit
import XCTest
@testable import Operations

final class TestableCloudContainer: NSObject {

    var containerIdentifier: String? = .None

    var didCreateContainerWithIdentifier: String! = nil
    var didCreateContainerWithDefaultIdentifier = false

    var accountStatus: CKAccountStatus = .CouldNotDetermine
    var accountStatusError: NSError? = .None
    var didGetAccountStatus = false

    var verifyApplicationPermissionStatus: CKApplicationPermissionStatus = .InitialState
    var verifyApplicationPermissionsError: NSError? = .None
    var verifyApplicationPermissions: CKApplicationPermissions? = .None
    var didVerifyApplicationStatus = false

    var requestApplicationPermissionStatus: CKApplicationPermissionStatus = .Granted
    var requestApplicationPermissionsError: NSError? = .None
    var requestApplicationPermissions: CKApplicationPermissions? = .None
    var didRequestApplicationStatus = false

    required override init() { }
}

extension TestableCloudContainer: CloudContainerRegistrarType {

    var cloudKitContainer: CKContainer! {
        return nil
    }

    static func containerWithIdentifier(identifier: String?) -> TestableCloudContainer {
        let container = TestableCloudContainer()
        container.containerIdentifier = identifier
        if let id = identifier {
            container.didCreateContainerWithIdentifier = id
        }
        else {
            container.didCreateContainerWithDefaultIdentifier = true
        }
        return container
    }

    func opr_accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void) {
        didGetAccountStatus = true
        completionHandler(accountStatus, accountStatusError)
    }

    func opr_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        didVerifyApplicationStatus = true
        verifyApplicationPermissions = applicationPermission
        completionHandler(verifyApplicationPermissionStatus, verifyApplicationPermissionsError)
    }

    func opr_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        didRequestApplicationStatus = true
        requestApplicationPermissions = applicationPermission
        completionHandler(requestApplicationPermissionStatus, requestApplicationPermissionsError)
    }
}

class CloudCapabilitiesTests: XCTestCase {

    let identifier = "cloud container identifier"
    var requirement: CKApplicationPermissions = []
    var container: TestableCloudContainer!
    var capability: CloudCapability!

    override func setUp() {
        super.setUp()
        container = TestableCloudContainer()
        makeDefaultCapability()
    }

    override func tearDown() {
        capability = nil
        container = nil
        super.tearDown()
    }

    func makeDefaultCapability() {
        capability = CloudCapability(permissions: requirement)
        capability.storedRegistrar = container
    }

    func makeCapabilityWithIdentifier() {
        capability = CloudCapability(permissions: requirement, containerId: identifier)
        container.containerIdentifier = identifier
        capability.storedRegistrar = container
    }

    func test__cloud_container_with_no_container_id_is_default() {
        XCTAssertNil(capability.registrar.containerIdentifier)
    }

    func test__cloud_container_with_identifier() {
        makeCapabilityWithIdentifier()
        XCTAssertEqual(capability.registrar.containerIdentifier, identifier)
    }

    func test_name_is_set() {
        XCTAssertEqual(capability.name, "Cloud")
    }

    func test_has_requirements_returns_false_when_empty_permissions() {
        XCTAssertFalse(capability.hasRequirements)
    }

    func test_has_requirements_returns_true_when_permissions_set() {
        requirement = [ .UserDiscoverability ]
        makeDefaultCapability()
        XCTAssertTrue(capability.hasRequirements)
    }

    func test__cloud_container_is_always_available() {
        XCTAssertTrue(capability.isAvailable())
    }

    // Getting status

    func test__given_status_could_not_be_determined__authorization_status_queries_the_registrar() {
        capability.authorizationStatus { status in
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertEqual(status.account, CKAccountStatus.CouldNotDetermine)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
    }

    func test__given_status_is_available_but_with_no_permissions_does_not_get_status_for_permissions() {
        container.accountStatus = .Available
        capability.authorizationStatus { status in
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertFalse(self.container.didVerifyApplicationStatus)
            XCTAssertEqual(status.account, CKAccountStatus.Available)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
    }

    func test__given_status_is_available_but_with_permissions_does_not_get_status_for_permissions() {
        requirement = [ .UserDiscoverability ]
        makeDefaultCapability()
        container.accountStatus = .Available
        capability.authorizationStatus { status in
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertTrue(self.container.didVerifyApplicationStatus)
            XCTAssertEqual(status.account, CKAccountStatus.Available)
            XCTAssertNotNil(status.permissions)
            XCTAssertEqual(status.permissions, CKApplicationPermissionStatus.InitialState)
            XCTAssertNil(status.error)
        }
    }

    func test__no_account_status() {
        container.accountStatus = .NoAccount
        capability.authorizationStatus { status in
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertFalse(self.container.didVerifyApplicationStatus)
            XCTAssertEqual(status.account, CKAccountStatus.NoAccount)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
    }

    func test__restricted_account_status() {
        container.accountStatus = .Restricted
        capability.authorizationStatus { status in
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertFalse(self.container.didVerifyApplicationStatus)
            XCTAssertEqual(status.account, CKAccountStatus.Restricted)
            XCTAssertNil(status.permissions)
            XCTAssertNil(status.error)
        }
    }

    // Requesting authorization

    func test__request_permissions() {
        weak var expectation = expectationWithDescription("Test: \(#function)")
        requirement = [ .UserDiscoverability ]
        makeDefaultCapability()
        container.accountStatus = .Available
        capability.requestAuthorizationWithCompletion {
            XCTAssertTrue(self.container.didGetAccountStatus)
            XCTAssertTrue(self.container.didVerifyApplicationStatus)
            XCTAssertTrue(self.container.didRequestApplicationStatus)
            dispatch_async(Queue.Main.queue, {
                guard let expectation = expectation else { print("Test: \(#function): Finished expectation after timeout"); return }
                expectation.fulfill()
            })
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

}


class CloudStatusTests: XCTestCase {

    let error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: .None)
    var noRequirement: CKApplicationPermissions = []
    var someRequirement: CKApplicationPermissions = [ .UserDiscoverability ]
    var status: CloudStatus!

    func test__status_with_error_does_not_meet_requirement() {
        status = CloudStatus(account: .Available, error: error)
        XCTAssertFalse(status.isRequirementMet(someRequirement))
    }

    func test__status_with_error_does_not_meet_empty_requirement() {
        status = CloudStatus(account: .Available, error: error)
        XCTAssertFalse(status.isRequirementMet(noRequirement))
    }

    func test__given_available_empty_requirements_status_met() {
        status = CloudStatus(account: .Available)
        XCTAssertTrue(status.isRequirementMet(noRequirement))
    }

    func test__given_available_requirements_no_permissions_status_not_met() {
        status = CloudStatus(account: .Available)
        XCTAssertFalse(status.isRequirementMet(someRequirement))
    }

    func test__given_available_requirements_permissions_granted_status_met() {
        status = CloudStatus(account: .Available, permissions: .Granted)
        XCTAssertTrue(status.isRequirementMet(someRequirement))
    }



}
