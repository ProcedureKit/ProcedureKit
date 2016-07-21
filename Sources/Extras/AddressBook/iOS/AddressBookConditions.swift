//
//  AddressBookConditions.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

@available(iOS, deprecated: 9.0)
public class AddressBookCondition: Condition {

    public enum Error: ErrorProtocol {
        case authorizationDenied
        case authorizationRestricted
        case authorizationNotDetermined
    }

    internal var registrar: AddressBookPermissionRegistrar = SystemAddressBookRegistrar() {
        didSet {
            removeDependencies()
            if case .notDetermined = registrar.status {
                addDependency(AddressBookOperation(registrar: registrar))
            }
        }
    }

    public override init() {
        super.init()
        name = "Address Book"
        mutuallyExclusive = false

        if case .notDetermined = registrar.status {
            addDependency(AddressBookOperation(registrar: registrar))
        }
    }

    public override func evaluate(_ operation: Procedure, completion: (OperationConditionResult) -> Void) {
        switch registrar.status {
        case .authorized:
            completion(.satisfied)
        case .denied:
            completion(.failed(Error.authorizationDenied))
        case .restricted:
            completion(.failed(Error.authorizationRestricted))
        case .notDetermined:
            // This could be possible, because the condition may have been
            // suppressed with a `SilentCondition`.
            completion(.failed(Error.authorizationNotDetermined))
        }
    }
}
