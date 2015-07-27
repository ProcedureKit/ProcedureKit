//
//  AddressBookCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

/**
    A condition for verifying acces to the user's AddressBook
*/

public struct AddressBookCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthorizationDenied
        case AuthorizationRestricted
        case AuthorizationNotDetermined
    }

    public let name = "Address Book"
    public let isMutuallyExclusive = false
    private let manager: AddressBookAuthenticationManager

    public init(manager: AddressBookAuthenticationManager? = .None) {
        self.manager = manager ?? SystemAddressBookAuthenticationManager()
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        switch manager.status {
        case .NotDetermined:
            return AccessAddressBook(manager: manager)
        default:
            return .None
        }
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch manager.status {
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

class AccessAddressBook: Operation {

    enum Error: ErrorType {
        case FailedToCreateAddressBook
        case FailedToAuthorize
    }

    private let manager: AddressBookAuthenticationManager
    private(set) var addressBook: ABAddressBookRef!

    init(manager: AddressBookAuthenticationManager) {
        self.manager = manager
        super.init()
        addCondition(AlertPresentation())
    }

    override func execute() {
        let (addressBook: ABAddressBookRef!, error) = manager.createAddressBook()
        if let addressBook: ABAddressBookRef = addressBook {
            manager.requestAccessToAddressBook(addressBook) { (success, error) in
                if success {
                    self.addressBook = addressBook
                    self.finish()
                }
                else {
                    self.finish(Error.FailedToAuthorize)
                }
            }
        }
        else {
            self.finish(Error.FailedToCreateAddressBook)
        }
    }
}


