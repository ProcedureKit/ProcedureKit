//
//  AppDelegate.swift
//  Permissions
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import Operations
import SwiftyBeaver

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // Set up Logging with SwiftyBeaver

        let console = ConsoleDestination()
        log.addDestination(console)

        LogManager.logger = { message, severity, file, function, line in
            switch severity {
            case .Verbose:
                log.verbose(message, file, function, line: line)
            case .Notice:
                log.debug(message, file, function, line: line)
            case .Info:
                log.info(message, file, function, line: line)
            case .Warning:
                log.warning(message, file, function, line: line)
            case .Fatal:
                log.error(message, file, function, line: line)
            }
        }
        
        LogManager.severity = .Info

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
