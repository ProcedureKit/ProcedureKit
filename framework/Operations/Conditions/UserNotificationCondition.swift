//
//  UserNotificationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import UIKit

public protocol UserNotificationRegistrarType {
    func opr_registerUserNotificationSettings(notificationSettings: UIUserNotificationSettings)
    func opr_currentUserNotificationSettings() -> UIUserNotificationSettings?
}

extension UIApplication: UserNotificationRegistrarType {
    
    public func opr_registerUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        registerUserNotificationSettings(notificationSettings)
    }
    
    public func opr_currentUserNotificationSettings() -> UIUserNotificationSettings? {
        return currentUserNotificationSettings() ?? .None
    }
}

private let DidRegisterSettingsNotificationName = "DidRegisterSettingsNotificationName"
private let NotificationSettingsKey = "NotificationSettingsKey"


/**
    A condition for verifying that we can present alerts
    to the user via `UILocalNotification` and/or remote
    notifications.
    
    In order to use this condition effectively, it is 
    required that you post a notification from inside the
    UIApplication.sharedApplication()'s delegate method.

    Like this:
        func application(_ application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
            UserNotificationCondition.didRegisterUserNotificationSettings(notificationSettings)
        }

*/
public struct UserNotificationCondition: OperationCondition {

    public enum Behavior {
        // Merge the new settings with the current settings
        case Merge
        // Replace the current settings with the new settings
        case Replace
    }

    public enum Error: ErrorType, Equatable {
        public typealias UserSettingsPair = (current: UIUserNotificationSettings?, desired: UIUserNotificationSettings)
        case SettingsNotSufficient(UserSettingsPair)
    }

    public static func didRegisterUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        NSNotificationCenter
            .defaultCenter()
            .postNotificationName(DidRegisterSettingsNotificationName, object: nil, userInfo: [NotificationSettingsKey: notificationSettings] )
    }

    public let name = "UserNotification"
    public let isMutuallyExclusive = false

    let settings: UIUserNotificationSettings
    let behavior: Behavior
    let registrar: UserNotificationRegistrarType

    public init(settings: UIUserNotificationSettings, behavior: Behavior = .Merge) {
        self.init(settings: settings, behavior: behavior, registrar: UIApplication.sharedApplication())
    }

    public init(settings: UIUserNotificationSettings, behavior: Behavior = .Merge, registrar: UserNotificationRegistrarType) {
        self.settings = settings
        self.behavior = behavior
        self.registrar = registrar
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return UserNotificationPermissionOperation(settings: settings, behavior: behavior, registrar: registrar)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if let current = registrar.opr_currentUserNotificationSettings() {

            switch (current, settings) {

            case let (current, settings) where current.contains(settings):
                completion(.Satisfied)

            default:
                completion(.Failed(Error.SettingsNotSufficient((current, settings))))
            }
        }
        else {
            completion(.Failed(Error.SettingsNotSufficient((.None, settings))))
        }
    }
}

public func ==(a: UserNotificationCondition.Error, b: UserNotificationCondition.Error) -> Bool {
    switch (a, b) {
    case let (.SettingsNotSufficient(current: aCurrent, desired: aDesired), .SettingsNotSufficient(current: bCurrent, desired: bDesired)):
        return (aCurrent == bCurrent) && (aDesired == bDesired)
    default: return false
    }
}
    
public class UserNotificationPermissionOperation: Operation {

    enum NotificationObserver: Selector {
        case SettingsDidChange = "notificationSettingsDidChange:"
    }

    let settings: UIUserNotificationSettings
    let behavior: UserNotificationCondition.Behavior
    let registrar: UserNotificationRegistrarType

    public convenience init(settings: UIUserNotificationSettings, behavior: UserNotificationCondition.Behavior = .Merge) {
        self.init(settings: settings, behavior: behavior, registrar: UIApplication.sharedApplication())
    }

    public init(settings: UIUserNotificationSettings, behavior: UserNotificationCondition.Behavior = .Merge, registrar: UserNotificationRegistrarType) {
        self.settings = settings
        self.behavior = behavior
        self.registrar = registrar
        super.init()
        addCondition(AlertPresentation())
    }

    public override func execute() {
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self, selector: NotificationObserver.SettingsDidChange.rawValue, name: DidRegisterSettingsNotificationName, object: nil)
        dispatch_async(Queue.Main.queue, request)
    }

    func request() {
        var settingsToRegister = settings
        if let current = registrar.opr_currentUserNotificationSettings() {
            switch (current, behavior) {
            case (let currentSettings, .Merge):
                settingsToRegister = currentSettings.settingsByMerging(settings)
            default:
                break
            }
        }
        registrar.opr_registerUserNotificationSettings(settingsToRegister)
    }

    func notificationSettingsDidChange(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.finish()
    }
}

extension UIUserNotificationSettings {

    func contains(settings: UIUserNotificationSettings) -> Bool {
        // This going to be so much easier with Swift 2.0's improved RawOptionSetType
        // Need to check that our types contain all of the other types
        // but without access to `contains:`
        if (types == UIUserNotificationType.allZeros) && (settings.types.rawValue > 0) {
            return false
        }
        if (types & UIUserNotificationType.Alert) && !(settings.types & UIUserNotificationType.Alert) {
            return false
        }
        if (types & UIUserNotificationType.Badge) && !(settings.types & UIUserNotificationType.Badge) {
            return false
        }
        if (types & UIUserNotificationType.Sound) && !(settings.types & UIUserNotificationType.Sound) {
            return false
        }

        let myCategories = categories ?? []
        let otherCategories = settings.categories ?? []
        return myCategories.isSupersetOf(otherCategories)
    }

    func settingsByMerging(settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let union = types | settings.types

        let myCategories = categories as? Set<UIUserNotificationCategory> ?? []
        var existingCategoriesByIdentifier = Dictionary(sequence: myCategories) { $0.identifier }

        let newCategories = settings.categories as? Set<UIUserNotificationCategory> ?? []
        var newCategoriesByIdentifier = Dictionary(sequence: myCategories) { $0.identifier }

        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }

        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(forTypes: union, categories: mergedCategories)
    }
}

extension UIUserNotificationType: BooleanType {

    public var boolValue: Bool {
        return self != .allZeros
    }
}

#endif

