//
//  RemoteNotificationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

public protocol RemoteNotificationRegistrarType {
    func opr_registerForRemoteNotifications()
}

extension UIApplication: RemoteNotificationRegistrarType {
    public func opr_registerForRemoteNotifications() {
        registerForRemoteNotifications()
    }
}

public struct RemoteNotificationCondition: OperationCondition {

    public enum Error: ErrorType {
        case ReceivedError(NSError)
    }

    static let queue = OperationQueue()

    public static func didReceiveNotificationToken(token: NSData) {
        NSNotificationCenter
            .defaultCenter()
            .postNotificationName(RemoteNotificationName, object: nil, userInfo: [RemoteNotificationTokenKey: token])
    }

    public static func didFailToRegisterForRemoteNotifications(error: NSError) {
        NSNotificationCenter
            .defaultCenter()
            .postNotificationName(RemoteNotificationName, object: nil, userInfo: [RemoteNotificationErrorKey: error])
    }

    public let name = "Remote Notification"
    public let isMutuallyExclusive = false

    let registrar: RemoteNotificationRegistrarType

    var queue: OperationQueue {
        return RemoteNotificationCondition.queue
    }

    public init() {
        self.init(registrar: UIApplication.sharedApplication())
    }

    public init(registrar: RemoteNotificationRegistrarType) {
        self.registrar = registrar
    }


    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return RemoteNotificationsRegistration(registrar: registrar) { _ in }
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let operation = RemoteNotificationsRegistration(registrar: registrar) { result in
            switch result {
            case .Token(_):
                completion(.Satisfied)
            case .Error(let error):
                completion(.Failed(Error.ReceivedError(error)))
            }
        }
        queue.addOperation(operation)
    }
}

public class RemoteNotificationsRegistration: Operation {

    public enum RegistrationResult {
        case Token(NSData)
        case Error(NSError)
    }

    enum NotificationObserver: Selector {
        case ReceivedResponse = "didReceiveResponse:"
    }

    let registrar: RemoteNotificationRegistrarType
    let handler: RegistrationResult -> Void

    public convenience init(handler: RegistrationResult -> Void) {
        self.init(registrar: UIApplication.sharedApplication(), handler: handler)
    }

    public init(registrar: RemoteNotificationRegistrarType, handler: RegistrationResult -> Void) {
        self.registrar = registrar
        self.handler = handler
        super.init()
        addCondition(MutuallyExclusive<RemoteNotificationsRegistration>())
    }

    public override func execute() {
        dispatch_async(Queue.Main.queue, register)
    }

    func register() {
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self, selector: NotificationObserver.ReceivedResponse.rawValue, name: RemoteNotificationName, object: nil)

        registrar.opr_registerForRemoteNotifications()
    }

    func didReceiveResponse(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        if let token = notification.userInfo?[RemoteNotificationTokenKey] as? NSData {
            handler(.Token(token))
        }
        else if let error = notification.userInfo?[RemoteNotificationErrorKey] as? NSError {
            handler(.Error(error))
        }
        else {
            fatalError("Received a notification with neither a token nor error.")
        }

        finish()
    }
}

private let RemoteNotificationName = "DidRegisterSettingsNotificationName"
private let RemoteNotificationTokenKey = "RemoteNotificationTokenKey"
private let RemoteNotificationErrorKey = "RemoteNotificationErrorKey"

