//
//  AddressBook.swift
//  Operations
//
//  Created by Daniel Thorpe on 06/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation

public struct SystemAddressBook: AddressBookRegistrarType {

    public init() { }

    public func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus {
        fatalError("This is a dummy type to satisfy the OS X compiler.")
    }

    public func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void) {
        fatalError("This is a dummy type to satisfy the OS X compiler.")
    }
}

