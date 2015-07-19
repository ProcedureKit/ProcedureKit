//
//  ContactsPermissionCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import Contacts

@available(iOS 9.0, *)
internal protocol ContactsAuthenticationManager {
    static func authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus
    func requestAccessForEntityType(entityType: CNEntityType, completionHandler: (Bool, NSError?) -> Void)
}

@available(iOS 9.0, *)
extension CNContactStore: ContactsAuthenticationManager { }

@available(iOS 9.0, *)
public class ContactsPermissionCondition: OperationCondition {

    public enum Error: ErrorType {
        case NotDetermined
        case NotAuthorized(CNAuthorizationStatus)
    }

    private class ContactsPermissionOperation: Operation {
        let manager: ContactsAuthenticationManager

        init(manager: ContactsAuthenticationManager) {
            self.manager = manager
            super.init()
            addCondition(AlertPresentation())
        }

        private override func execute() {
            let status = manager.dynamicType.authorizationStatusForEntityType(.Contacts)
            switch status {
            case .NotDetermined:
                dispatch_async(Queue.Main.queue, requestPermission)
            default:
                finish()
            }
        }

        private func requestPermission() {
            manager.requestAccessForEntityType(.Contacts) { (granted, error) in
                if granted && error == nil {
                    self.finish()
                }
            }
        }
    }

    public static let name = "Contacts"
    public static let isMutuallyExclusive = false

    internal let manager: ContactsAuthenticationManager

    public convenience init() {
        self.init(manager: CNContactStore())
    }

    internal init(manager: ContactsAuthenticationManager) {
        self.manager = manager
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return ContactsPermissionOperation(manager: manager)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let status = manager.dynamicType.authorizationStatusForEntityType(.Contacts)
        switch status {
        case .NotDetermined:
            completion(.Failed(Error.NotDetermined))
        case .Denied, .Restricted:
            completion(.Failed(Error.NotAuthorized(status)))
        case .Authorized:
            completion(.Satisfied)
        }
    }
}

extension ContactsPermissionCondition.Error: Equatable { }

public func ==(a: ContactsPermissionCondition.Error, b: ContactsPermissionCondition.Error) -> Bool {
    switch (a, b) {
    case (.NotDetermined, .NotDetermined):
        return true
    case let (.NotAuthorized(aStatus), .NotAuthorized(bStatus)):
        return aStatus == bStatus
    default:
        return false
    }
}


