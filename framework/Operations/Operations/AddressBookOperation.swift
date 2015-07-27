//
//  AddressBookOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

public protocol AddressBookAuthenticationManager {
    var status: ABAuthorizationStatus { get }
    func createAddressBook() -> (ABAddressBookRef!, CFErrorRef!)
    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler)
}

struct SystemAddressBookAuthenticationManager: AddressBookAuthenticationManager {

    var status: ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }

    func createAddressBook() -> (ABAddressBookRef!, CFErrorRef!) {
        var addressBookError: Unmanaged<CFErrorRef>? = .None
        var addressBook: ABAddressBookRef? = .None
        if let ref = ABAddressBookCreateWithOptions(nil, &addressBookError) {
            addressBook = ref.takeUnretainedValue()
            return (addressBook, nil)
        }
        else if let addressBookError = addressBookError {
            return (nil, addressBookError.takeUnretainedValue())
        }
        return (nil, nil)
    }

    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler) {
        ABAddressBookRequestAccessWithCompletion(addressBook, completion)
    }
}

public class AddressBookOperation: AccessAddressBook {

    public convenience init(suppressPermissionRequest: Bool = false, handler: AddressBookHandler) {
        self.init(manager: SystemAddressBookAuthenticationManager(), silent: suppressPermissionRequest, handler: handler)
    }

    public init(manager: AddressBookAuthenticationManager, silent: Bool = false, handler: AddressBookHandler) {
        super.init(manager: manager, handler: handler)
        let condition = AddressBookCondition(manager: manager)
        addCondition(silent ? SilentCondition(condition) : condition)
    }
}

