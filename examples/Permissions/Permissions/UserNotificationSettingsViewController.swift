//
//  UserNotificationSettingsViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 04/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import Operations

enum UserNotificationSettings {

    case Simple

    var type: UIUserNotificationType {
        switch self {
        case .Simple:
            return .Badge
        }
    }

    var categories: Set<UIUserNotificationCategory>? {
        return .None
    }

    var settings: UIUserNotificationSettings {
        return UIUserNotificationSettings(forTypes: type, categories: categories)
    }
}

class UserNotificationSettingsViewController: PermissionViewController {

    var currentUserNotificationSettings: UIUserNotificationSettings {
        return UserNotificationSettings.Simple.settings
    }

    var condition: UserNotificationCondition {
        return UserNotificationCondition(settings: currentUserNotificationSettings, behavior: .Merge)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("User Notifications", comment: "User Notifications")

        permissionNotDetermined.informationLabel.text = "We haven't yet asked for permission to set the User Notification Settings."

        permissionDenied.informationLabel.text = "Currently settings are not sufficient. 😞"

        permissionGranted.instructionLabel.text = "We don't support any User Notification Operations"
        permissionGranted.button.hidden = true

    }

    override func viewWillAppear(animated: Bool) {
        determineAuthorizationStatus()
    }

    override func conditionsForState(state: State, silent: Bool) -> [OperationCondition] {
        return configureConditionsForState(state, silent: silent)(condition)
    }

    func determineAuthorizationStatus(silently silently: Bool = true) {
        // Create a simple block operation to set the state.
        let authorized = BlockOperation { (continueWithError: BlockOperation.ContinuationBlockType) in
            self.state = .Authorized
            continueWithError(error: nil)
        }
        authorized.name = "Authorized Access"

        // Additionally, suppress the automatic request if not authorized.
        authorized.addCondition(silently ? SilentCondition(condition) : condition)

        // Attach an observer so that we can inspect any condition errors
        // From here, we can determine the authorization status if not
        // authorized.
        authorized.addObserver(BlockObserver { (_, errors) in
            if let error = errors.first as? UserNotificationCondition.Error {
                switch error {
                case let .SettingsNotSufficient(current: current, desired: _):
                    if let _ = current {
                        self.state = .Denied
                    }
                    else {
                        self.state = .Unknown
                    }
                }
            }
        })
        
        queue.addOperation(authorized)
    }

    override func requestPermission() {
        determineAuthorizationStatus(silently: false)
    }


}
