//
//  ContactsCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, *)
protocol ContactsPermissionRegistrar {
    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus
    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void)
}

public enum ContactsPermissionsError: ErrorType {
    case ContactsUnknownErrorOccured
    case ContactsErrorOccured(NSError)
    case ContactsAccessDenied
}

@available(iOS 9.0, *)
extension CNContactStore: ContactsPermissionRegistrar {
    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        return self.dynamicType.authorizationStatusForEntityType(entityType)
    }
    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        requestAccessForEntityType(entityType, completionHandler: completion)
    }
}

@available(iOS 9.0, *)
public struct ContactsCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthorizationDenied
        case AuthorizationRestricted
        case AuthorizationNotDetermined
    }

    public let name = "Address Book"
    public let isMutuallyExclusive = false

    let entityType: CNEntityType
    let registrar: ContactsPermissionRegistrar

    public init(entityType: CNEntityType = .Contacts) {
        self.entityType = entityType
        registrar = CNContactStore()
    }

    init(entityType: CNEntityType = .Contacts, registrar: ContactsPermissionRegistrar) {
        self.entityType = entityType
        self.registrar = registrar
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        switch registrar.opr_authorizationStatusForEntityType(entityType) {
        case .NotDetermined:
            return ContactsOperation(entityType: entityType, registrar: registrar)
        default:
            return .None
        }
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch registrar.opr_authorizationStatusForEntityType(entityType) {
        case .Authorized:
            completion(.Satisfied)
        case .Denied:
            completion(.Failed(Error.AuthorizationDenied))
        case .Restricted:
            completion(.Failed(Error.AuthorizationRestricted))
        case .NotDetermined:
            completion(.Failed(Error.AuthorizationNotDetermined))
        }
    }
}



