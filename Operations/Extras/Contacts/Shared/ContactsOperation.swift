//
//  ContactsOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, *)
public class ContactsOperation: Operation {

    let store = CNContactStore()
    let entityType: CNEntityType
    let registrar: ContactsPermissionRegistrar

    public init(entityType: CNEntityType = .Contacts) {
        self.entityType = entityType
        registrar = store
    }

    init(entityType: CNEntityType = .Contacts, registrar: ContactsPermissionRegistrar) {
        self.entityType = entityType
        self.registrar = registrar
    }

    public override func execute() {
        requestAccess()
    }

    final func requestAccess() {
        switch registrar.opr_authorizationStatusForEntityType(entityType) {
        case .NotDetermined:
            registrar.opr_requestAccessForEntityType(entityType, completion: requestAccessDidComplete)
        default:
            finish(ContactsPermissionsError.ContactsAccessDenied)
        }
    }

    func requestAccessDidComplete(success: Bool, error: NSError?) {
        switch (success, error) {
        case (true, _):
            finish(executeContactsTask())
        case let (false, .Some(error)):
            finish(ContactsPermissionsError.ContactsErrorOccured(error))
        case (false, _):
            finish(ContactsPermissionsError.ContactsUnknownErrorOccured)
        }
    }

    func executeContactsTask() -> ErrorType? {
        return .None
    }
}


