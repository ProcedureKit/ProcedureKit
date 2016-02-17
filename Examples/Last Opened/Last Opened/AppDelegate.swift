//
//  AppDelegate.swift
//  Last Opened
//
//  Created by Daniel Thorpe on 11/01/2016.
//  Copyright © 2016 Daniel Thorpe. All rights reserved.
//

import UIKit
import Operations

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Operations.LogManager.severity = .Verbose
        return true
    }
}

