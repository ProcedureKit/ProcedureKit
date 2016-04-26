//
//  ContactsCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, OSX 10.11, *)
public class _ContactsCondition<Store: ContactStoreType>: Condition {

    let entityType: CNEntityType
    let store: Store

    public convenience init(entityType: CNEntityType = .Contacts) {
        self.init(entityType: entityType, registrar: Store())
    }

    init(entityType: CNEntityType = .Contacts, registrar: Store) {
        self.entityType = entityType
        self.store = registrar
        super.init()
        name = "Contacts"

        if case .NotDetermined = store.opr_authorizationStatusForEntityType(entityType) {
            addDependency(_ContactsAccess(entityType: entityType, contactStore: store))
        }
    }

    public override func evaluate(operation: Operation, completion: OperationConditionResult -> Void) {
        switch store.opr_authorizationStatusForEntityType(entityType) {
        case .Authorized:
            completion(.Satisfied)
        case .Denied:
            completion(.Failed(ContactsPermissionError.AuthorizationDenied))
        case .Restricted:
            completion(.Failed(ContactsPermissionError.AuthorizationRestricted))
        case .NotDetermined:
            completion(.Failed(ContactsPermissionError.AuthorizationNotDetermined))
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
public typealias ContactsCondition = _ContactsCondition<SystemContactStore>
