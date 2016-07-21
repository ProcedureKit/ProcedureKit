//
//  UserNotificationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

public protocol UserNotificationRegistrarType {
    func opr_registerUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings)
    func opr_currentUserNotificationSettings() -> UIUserNotificationSettings?
}

extension UIApplication: UserNotificationRegistrarType {

    public func opr_registerUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings) {
        registerUserNotificationSettings(notificationSettings)
    }

    public func opr_currentUserNotificationSettings() -> UIUserNotificationSettings? {
        return currentUserNotificationSettings() ?? .none
    }
}

// swiftlint:disable variable_name
private let DidRegisterSettingsNotificationName = "DidRegisterSettingsNotificationName"
private let NotificationSettingsKey = "NotificationSettingsKey"
// swiftlint:enable variable_name

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
public final class UserNotificationCondition: Condition {

    public enum Behavior {
        // Merge the new settings with the current settings
        case merge
        // Replace the current settings with the new settings
        case replace
    }

    public enum Error: ErrorProtocol, Equatable {
        public typealias UserSettingsPair = (current: UIUserNotificationSettings?, desired: UIUserNotificationSettings)
        case settingsNotSufficient(UserSettingsPair)
    }

    public static func didRegisterUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings) {
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: DidRegisterSettingsNotificationName), object: nil, userInfo: [NotificationSettingsKey: notificationSettings] )
    }

    let settings: UIUserNotificationSettings
    let behavior: Behavior
    let registrar: UserNotificationRegistrarType

    public convenience init(settings: UIUserNotificationSettings, behavior: Behavior = .merge) {
        self.init(settings: settings, behavior: behavior, registrar: UIApplication.shared())
    }

    init(settings: UIUserNotificationSettings, behavior: Behavior = .merge, registrar: UserNotificationRegistrarType) {
        self.settings = settings
        self.behavior = behavior
        self.registrar = registrar
        super.init()
        name = "UserNotification"
        mutuallyExclusive = false
        addDependency(UserNotificationPermissionOperation(settings: settings, behavior: behavior, registrar: registrar))
    }

    public override func evaluate(_ operation: OldOperation, completion: (OperationConditionResult) -> Void) {
        if let current = registrar.opr_currentUserNotificationSettings() {

            switch (current, settings) {

            case let (current, settings) where current.contains(settings):
                completion(.satisfied)

            default:
                completion(.failed(Error.settingsNotSufficient((current, settings))))
            }
        }
        else {
            completion(.failed(Error.settingsNotSufficient((.none, settings))))
        }
    }
}

public func == (lhs: UserNotificationCondition.Error, rhs: UserNotificationCondition.Error) -> Bool {
    switch (lhs, rhs) {
    case let (.settingsNotSufficient(current: aCurrent, desired: aDesired), .settingsNotSufficient(current: bCurrent, desired: bDesired)):
        return (aCurrent == bCurrent) && (aDesired == bDesired)
    }
}

public class UserNotificationPermissionOperation: OldOperation {

    enum NotificationObserver {
        case settingsDidChange

        var selector: Selector {
            switch self {
            case .settingsDidChange:
                return #selector(UserNotificationPermissionOperation.notificationSettingsDidChange(_:))
            }
        }
    }

    let settings: UIUserNotificationSettings
    let behavior: UserNotificationCondition.Behavior
    let registrar: UserNotificationRegistrarType

    public convenience init(settings: UIUserNotificationSettings, behavior: UserNotificationCondition.Behavior = .merge) {
        self.init(settings: settings, behavior: behavior, registrar: UIApplication.shared())
    }

    init(settings: UIUserNotificationSettings, behavior: UserNotificationCondition.Behavior = .merge, registrar: UserNotificationRegistrarType) {
        self.settings = settings
        self.behavior = behavior
        self.registrar = registrar
        super.init()
        name = "User Notification Permissions OldOperation"
        addCondition(AlertPresentation())
    }

    public override func execute() {
        NotificationCenter.default
            .addObserver(self, selector: NotificationObserver.settingsDidChange.selector, name: NSNotification.Name(rawValue: DidRegisterSettingsNotificationName), object: nil)
        Queue.main.queue.async(execute: request)
    }

    func request() {
        var settingsToRegister = settings
        if let current = registrar.opr_currentUserNotificationSettings() {
            switch (current, behavior) {
            case (let currentSettings, .merge):
                settingsToRegister = currentSettings.settingsByMerging(settings)
            default:
                break
            }
        }
        registrar.opr_registerUserNotificationSettings(settingsToRegister)
    }

    func notificationSettingsDidChange(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
        self.finish()
    }
}

extension UIUserNotificationSettings {

    func contains(_ settings: UIUserNotificationSettings) -> Bool {

        if !types.contains(settings.types) {
            return false
        }

        let myCategories = categories ?? []
        let otherCategories = settings.categories ?? []
        return myCategories.isSuperset(of: otherCategories)
    }

    func settingsByMerging(_ settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let union = types.union(settings.types)

        let myCategories = categories ?? []
        var existingCategoriesByIdentifier = Dictionary(sequence: myCategories) { $0.identifier }

        let newCategories = settings.categories ?? []
        let newCategoriesByIdentifier = Dictionary(sequence: newCategories) { $0.identifier }

        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }

        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(types: union, categories: mergedCategories)
    }
}

extension UIUserNotificationType: Boolean {

    public var boolValue: Bool {
        return self != []
    }
}
