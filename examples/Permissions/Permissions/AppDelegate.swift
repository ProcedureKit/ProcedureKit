//
//  AppDelegate.swift
//  Permissions
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import Operations

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // Set the global log level like this
        LogManager.severity = .Notice

        return true
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        UserNotificationCondition.didRegisterUserNotificationSettings(notificationSettings)
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        RemoteNotificationCondition.didReceiveNotificationToken(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        RemoteNotificationCondition.didFailToRegisterForRemoteNotifications(error)
    }
}

extension UIColor {
    
    static var globalTintColor: UIColor? {
        return UIApplication.sharedApplication().keyWindow?.tintColor
    }
}
