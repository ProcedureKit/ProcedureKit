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

    public convenience init(entityType: CNEntityType = .contacts) {
        self.init(entityType: entityType, registrar: Store())
    }

    init(entityType: CNEntityType = .contacts, registrar: Store) {
        self.entityType = entityType
        self.store = registrar
        super.init()
        name = "Contacts"

        if case .notDetermined = store.opr_authorizationStatusForEntityType(entityType) {
            addDependency(_ContactsAccess(entityType: entityType, contactStore: store))
        }
    }

    public override func evaluate(_ operation: Operation, completion: (OperationConditionResult) -> Void) {
        switch store.opr_authorizationStatusForEntityType(entityType) {
        case .authorized:
            completion(.satisfied)
        case .denied:
            completion(.failed(ContactsPermissionError.authorizationDenied))
        case .restricted:
            completion(.failed(ContactsPermissionError.authorizationRestricted))
        case .notDetermined:
            completion(.failed(ContactsPermissionError.authorizationNotDetermined))
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
public typealias ContactsCondition = _ContactsCondition<SystemContactStore>
