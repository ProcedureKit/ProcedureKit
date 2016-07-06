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

public class RemoteNotificationCondition: Condition {

    public enum Error: ErrorProtocol {
        case receivedError(NSError)
    }

    static let queue = OperationQueue()

    public static func didReceiveNotificationToken(_ token: Data) {
        NotificationCenter
            .default
            .post(name: Notification.Name(rawValue: RemoteNotificationName), object: nil, userInfo: [RemoteNotificationTokenKey: token])
    }

    public static func didFailToRegisterForRemoteNotifications(_ error: NSError) {
        NotificationCenter
            .default
            .post(name: Notification.Name(rawValue: RemoteNotificationName), object: nil, userInfo: [RemoteNotificationErrorKey: error])
    }

    internal var registrar: RemoteNotificationRegistrarType = UIApplication.shared() {
        didSet {
            removeDependencies()
            addDependency(RemoteNotificationsRegistration(registrar: registrar) { _ in })
        }
    }

    var queue: OperationQueue {
        return RemoteNotificationCondition.queue
    }

    public override init() {
        super.init()
        name = "Remote Notification"
        mutuallyExclusive = false
        addDependency(RemoteNotificationsRegistration(registrar: registrar) { _ in })
    }

    public override func evaluate(_ operation: Operation, completion: (OperationConditionResult) -> Void) {
        let operation = RemoteNotificationsRegistration(registrar: registrar) { result in
            switch result {
            case .token(_):
                completion(.satisfied)
            case .error(let error):
                completion(.failed(Error.receivedError(error)))
            }
        }
        queue.addOperation(operation)
    }
}

public class RemoteNotificationsRegistration: Operation {

    public enum RegistrationResult {
        case token(Data)
        case error(NSError)
    }

    enum NotificationObserver {
        case receivedResponse

        var selector: Selector {
            switch self {
            case .receivedResponse:
                return #selector(RemoteNotificationsRegistration.didReceiveResponse(_:))
            }
        }
    }

    let registrar: RemoteNotificationRegistrarType
    let handler: (RegistrationResult) -> Void

    public convenience init(handler: (RegistrationResult) -> Void) {
        self.init(registrar: UIApplication.shared(), handler: handler)
    }

    public init(registrar: RemoteNotificationRegistrarType, handler: (RegistrationResult) -> Void) {
        self.registrar = registrar
        self.handler = handler
        super.init()
        addCondition(MutuallyExclusive<RemoteNotificationsRegistration>())
    }

    public override func execute() {
        Queue.main.queue.async(execute: register)
    }

    func register() {
        NotificationCenter
            .default
            .addObserver(self, selector: NotificationObserver.receivedResponse.selector, name: NSNotification.Name(rawValue: RemoteNotificationName), object: nil)

        registrar.opr_registerForRemoteNotifications()
    }

    func didReceiveResponse(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)

        if let token = (notification as NSNotification).userInfo?[RemoteNotificationTokenKey] as? Data {
            handler(.token(token))
        }
        else if let error = (notification as NSNotification).userInfo?[RemoteNotificationErrorKey] as? NSError {
            handler(.error(error))
        }
        else {
            fatalError("Received a notification with neither a token nor error.")
        }

        finish()
    }
}

// swiftlint:disable variable_name
private let RemoteNotificationName = "RemoteNotificationName"
private let RemoteNotificationTokenKey = "RemoteNotificationTokenKey"
private let RemoteNotificationErrorKey = "RemoteNotificationErrorKey"
// swiftlint:enable variable_name
