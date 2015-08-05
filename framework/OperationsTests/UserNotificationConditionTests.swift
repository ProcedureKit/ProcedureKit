//
//  UserNotificationConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class TestableUserNotificationManager: UserNotificationManager {

    var currentSettings: UIUserNotificationSettings?
    var didRegisterSettings: UIUserNotificationSettings? = .None
    
    
    init(settings: UIUserNotificationSettings? = .None) {
        currentSettings = settings
    }
    
    func opr_registerUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        println("Registering notification settings")        
        didRegisterSettings = notificationSettings
        currentSettings = notificationSettings
    }

    func opr_currentUserNotificationSettings() -> UIUserNotificationSettings? {
        println("Reading current notification settings")
        return currentSettings
    }
}

class UserNotificationConditionTests: OperationTests {

    func createSimpleSettings() -> UIUserNotificationSettings {
        return UIUserNotificationSettings(forTypes: .Badge | .Alert, categories: nil)
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
        
        let types: UIUserNotificationType = .Badge | .Sound | .Alert
        return UIUserNotificationSettings(forTypes: types, categories: Set(arrayLiteral: category))
    }
    
    func test__condition_fails_when_current_settings_are_empty() {
        let settings = createSimpleSettings()
        let manager = TestableUserNotificationManager(settings: .None)
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, manager: manager)
        
        let operation = TestOperation()
        operation.addCondition(SilentCondition(condition))
        
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors.first as? UserNotificationCondition.Error {
            XCTAssertTrue(error == UserNotificationCondition.Error.SettingsNotSufficient((current: nil, desired: settings)))
        }
        else {
            XCTFail("No error message was observed")
        }
    }
    
    func test__condition_succeeds_when_current_settings_match_desired() {
        
        let settings = createSimpleSettings()
        let manager = TestableUserNotificationManager(settings: settings)
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, manager: manager)
        
        let operation = TestOperation()
        operation.addCondition(SilentCondition(condition))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertTrue(operation.didExecute)
    }
    
    func test__permission_is_requested_if_permissions_are_not_enough() {
        let settings = createSimpleSettings()
        let manager = TestableUserNotificationManager(settings: .None)
        let condition = UserNotificationCondition(settings: settings, behavior: .Merge, manager: manager)
        
        let operation = TestOperation()
        operation.addCondition(condition)
        
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))
        
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(manager.didRegisterSettings!, settings)
        XCTAssertFalse(operation.didExecute)
//        if let error = receivedErrors.first as? UserNotificationCondition.Error {
//            XCTAssertTrue(error == UserNotificationCondition.Error.SettingsNotSufficient((current: nil, desired: settings)))
//        }
//        else {
//            XCTFail("No error message was observed")
//        }
    }
    
}

