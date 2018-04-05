//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import UserNotifications
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class UNAuthorizationStatusTests: XCTestCase {

    func test__given_status_not_determined__requirement_not_met() {
        let status = UNAuthorizationStatus.notDetermined
        XCTAssertFalse(status.meets(requirement: [.alert]))
        XCTAssertFalse(status.meets(requirement: []))
    }

    func test__given_status_denied__requirement_not_met() {
        let status = UNAuthorizationStatus.denied
        XCTAssertFalse(status.meets(requirement: [.alert]))
        XCTAssertFalse(status.meets(requirement: []))
    }

    func test__given_status_authorized__requirement_met() {
        let status = UNAuthorizationStatus.authorized
        XCTAssertTrue(status.meets(requirement: [.alert]))
        XCTAssertTrue(status.meets(requirement: []))
    }
}

class UserNotificationCapabilityTests: XCTestCase {

    var registrar: TestableUserNotificationsRegistrar!
    var capability: Capability.UserNotifications!

    override func setUp() {
        super.setUp()
        registrar = TestableUserNotificationsRegistrar()
        capability = Capability.UserNotifications()
        capability.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__is_available() {
        XCTAssertTrue(capability.isAvailable())
    }

    func test__authorization_status_queries_registrar() {
        capability.getAuthorizationStatus { XCTAssertEqual($0, .notDetermined) }
        XCTAssertTrue(registrar.didCheckAuthorizationStatus)
    }

    func test__request_authorization() {
        registrar.authorization = (true, nil, .authorized)
        capability.requestAuthorization { [unowned self] in
            self.capability.getAuthorizationStatus { XCTAssertEqual($0, .authorized) }
        }
        XCTAssertTrue(registrar.didRequestAuthorization)
        XCTAssertTrue(registrar.didCheckAuthorizationStatus)
    }
}
