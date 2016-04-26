//
//  AddressBookConditions.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

@available(iOS, deprecated=9.0)
public class AddressBookCondition: Condition {

    public enum Error: ErrorType {
        case AuthorizationDenied
        case AuthorizationRestricted
        case AuthorizationNotDetermined
    }

    internal var registrar: AddressBookPermissionRegistrar = SystemAddressBookRegistrar() {
        didSet {
            removeDependencies()
            if case .NotDetermined = registrar.status {
                addDependency(AddressBookOperation(registrar: registrar))
            }
        }
    }

    public override init() {
        super.init()
        name = "Address Book"
        mutuallyExclusive = false

        if case .NotDetermined = registrar.status {
            addDependency(AddressBookOperation(registrar: registrar))
        }
    }

    public override func evaluate(operation: Operation, completion: OperationConditionResult -> Void) {
        switch registrar.status {
        case .Authorized:
            completion(.Satisfied)
        case .Denied:
            completion(.Failed(Error.AuthorizationDenied))
        case .Restricted:
            completion(.Failed(Error.AuthorizationRestricted))
        case .NotDetermined:
            // This could be possible, because the condition may have been
            // suppressed with a `SilentCondition`.
            completion(.Failed(Error.AuthorizationNotDetermined))
        }
    }
}
