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
