//
//  UserNotificationConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableUserNotificationRegistrar: UserNotificationRegistrarType {

    var currentSettings: UIUserNotificationSettings?
    var didRegisterSettings: UIUserNotificationSettings? = .None

    init(settings: UIUserNotificationSettings? = .None) {
        currentSettings = settings
    }

    func opr_registerUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        didRegisterSettings = notificationSettings
        currentSettings = notificationSettings
        UserNotificationCondition.didRegisterUserNotificationSettings(notificationSettings)
    }

    func opr_currentUserNotificationSettings() -> UIUserNotificationSettings? {
        return currentSettings
    }
}

class UserNotificationConditionTests: OperationTests {

    func createSimpleSettings() -> UIUserNotificationSettings {
        return UIUserNotificationSettings(forTypes: [.Badge, .Alert], categories: nil)
    }

    func createAdvancedSettings() -> UIUserNotificationSettings {
        let action1 = UIMutableUserNotificationAction()
        action1.activationMode = .Background
        action1.title = "Action 1"
        action1.identifier = "me.danthorpe.Operations.Tests.UserNotification.Action1"
        action1.destructive = false
        action1.authenticationRequired = false

        let action2 = UIMutableUserNotificationAction()
        action2.activationMode = .Background
        action2.title = "Action 2"
        action2.identifier = "me.danthorpe.Operations.Tests.UserNotification.Action2"
        action2.destructive = false
        action2.authenticationRequired = false

        let category = UIMutableUserNotificationCategory()
        category.identifier = "me.danthorpe.Operations.Tests.UserNotification.Actions"
        category.setActions([action1, action2], forContext: .Default)

        let types: UIUserNotificationType = [.Badge, .Sound, .Alert]
        return UIUserNotificationSettings(forTypes: types, categories: Set(arrayLiteral: category))
    }

    func test__condition_fails_when_current_settings_are_empty() {
        let settings = createSimpleSettings()
        let registrar = TestableUserNotificationRegistrar(settings: .None)
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, registrar: registrar)

        let operation = TestOperation()
        operation.addCondition(SilentCondition(condition))

        waitForOperation(operation)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        if let error = operation.errors.first as? UserNotificationCondition.Error {
            XCTAssertTrue(error == UserNotificationCondition.Error.SettingsNotSufficient((current: nil, desired: settings)))
        }
        else {
            XCTFail("No error message was observed")
        }
    }

    func test__condition_succeeds_when_current_settings_match_desired() {

        let settings = createSimpleSettings()
        let registrar = TestableUserNotificationRegistrar(settings: settings)
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, registrar: registrar)

        let operation = TestOperation()
        operation.addCondition(SilentCondition(condition))

        waitForOperation(operation)

        XCTAssertTrue(operation.didExecute)
    }

    func test__permission_is_requested_if_permissions_are_not_enough() {
        let settings = createSimpleSettings()
        let registrar = TestableUserNotificationRegistrar(settings: UIUserNotificationSettings(forTypes: [], categories: nil))
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, registrar: registrar)

        let operation = TestOperation()
        operation.addCondition(condition)

        waitForOperation(operation)

        XCTAssertEqual(registrar.didRegisterSettings!, settings)
    }

}
