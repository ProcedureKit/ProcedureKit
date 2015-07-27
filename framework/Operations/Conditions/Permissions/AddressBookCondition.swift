//
//  AddressBookCondition.swift
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

/**
    A condition for verifying acces to the user's AddressBook
*/

public struct AddressBookCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthenticationDenied
        case AuthenticationRestricted
        case AuthenticationNotDetermined
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
            return RequestAddressBookPermission(manager: manager)
        default:
            return .None
        }
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch manager.status {
        case .Authorized:
            completion(.Satisfied)
        case .Denied:
            completion(.Failed(Error.AuthenticationDenied))
        case .Restricted:
            completion(.Failed(Error.AuthenticationRestricted))
        case .NotDetermined:
            // This could be possible, because the condition may have been
            // suppressed with a `SilentCondition`.
            completion(.Failed(Error.AuthenticationNotDetermined))
        }
    }
}

class RequestAddressBookPermission: Operation {

    enum Error: ErrorType {
        case FailedToCreateAddressBook
        case FailedToAuthorize
    }

    private let manager: AddressBookAuthenticationManager

//    private(set) var addressBook: ABAddressBookRef? = .None

    init(manager: AddressBookAuthenticationManager) {
        self.manager = manager
        super.init()
        addCondition(AlertPresentation())
    }

    override func execute() {
        switch manager.status {
        case .NotDetermined:
            dispatch_async(Queue.Main.queue, requestPermission)
        default:
            finish()
        }
    }

    func requestPermission() {
        let (addressBook: ABAddressBookRef!, error) = manager.createAddressBook()
        if let addressBook: ABAddressBookRef = addressBook {
            manager.requestAccessToAddressBook(addressBook) { (success, error) in
                if success {
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
