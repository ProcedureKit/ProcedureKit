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

    public init(suppressPermissionRequest silent: Bool = false, handler: AddressBookHandler) {
        super.init(manager: SystemAddressBookAuthenticationManager(), handler: handler)
        let condition = AddressBookCondition(manager: manager)
        addCondition(silent ? SilentCondition(condition) : condition)
    }

    /** Testing Interface Only! */
    public init(manager: AddressBookAuthenticationManager, silent: Bool = false, handler: AddressBookHandler) {
        super.init(manager: manager, handler: handler)
        let condition = AddressBookCondition(manager: manager)
        addCondition(silent ? SilentCondition(condition) : condition)
    }
}

public class AddressBookMapAllRecords<T>: AddressBookOperation {

    public init(suppressPermissionRequest silent: Bool = false, inGroupWithName groupName: String? = .None, transform: (addressBook: ABAddressBookRef, record: ABRecordRef) -> T?, completion: [T] -> Void) {

        let getGroup: (ABAddressBookRef, String) -> ABRecordRef? = { (addressBook, searchTerm) in
            let groups = ABAddressBookCopyArrayOfAllGroups(addressBook)?.takeRetainedValue() as! [ABRecordRef]
            let groupNames = groups.map { ABRecordCopyValue($0, kABGroupNameProperty)?.takeRetainedValue() as! String }
            let filtered = groups.filter { record in
                let name = ABRecordCopyValue(record, kABGroupNameProperty).takeRetainedValue() as! String
                return name == searchTerm
            }
            return filtered.first
        }

        let getAllRecords: ABAddressBookRef -> [ABRecordRef] = { addressBook in
            if let groupName = groupName, group: ABRecordRef = getGroup(addressBook, groupName) {
                return ABGroupCopyArrayOfAllMembers(group).takeRetainedValue() as! [ABRecordRef]
            }
            else {
                return ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as! [ABRecordRef]
            }
        }

        super.init(suppressPermissionRequest: silent, handler: { (addressBook, continueWithError) in
            // Get all the records, map them with the transform, use flatMap to trim an .None elements.
            completion(getAllRecords(addressBook).flatMap { flatMap(transform(addressBook: addressBook, record: $0), { [$0] }) ?? [] })
            continueWithError(error: nil)
        })

        if let groupName = groupName {
            addCondition(AddressBookGroupExistsCondition(name: groupName, manager: manager))
        }
    }
}

public struct AddressBookGroupExistsCondition: OperationCondition {

    enum Error: ErrorType {
        case GroupDoesNotExist([String])
    }

    static let queue = OperationQueue()

    public let name = "Address Book Group Exists"
    public let isMutuallyExclusive = false

    public let groupName: String
    private let manager: AddressBookAuthenticationManager

    private var queue: OperationQueue {
        return AddressBookGroupExistsCondition.queue
    }

    public init(name: String, manager: AddressBookAuthenticationManager? = .None) {
        self.groupName = name
        self.manager = manager ?? SystemAddressBookAuthenticationManager()
    }


    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return AddressBookCreateGroup(groupName: groupName)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let operation = AddressBookOperation { [searchTerm = self.groupName] (addressBook, continueWithError) -> Void in
            let groups = ABAddressBookCopyArrayOfAllGroups(addressBook)?.takeRetainedValue() as! [ABRecordRef]
            let groupNames = groups.map { ABRecordCopyValue($0, kABGroupNameProperty)?.takeRetainedValue() as! String }
            let filtered = groupNames.filter { $0 == searchTerm }
            if filtered.count == 0 {
                completion(.Failed(Error.GroupDoesNotExist(groupNames)))
            }
            else {
                completion(.Satisfied)
            }
            continueWithError(error: nil)
        }
        queue.addOperation(operation)
    }
}

public class AddressBookCreateGroup: AddressBookOperation {

    enum Error: ErrorType {
        case FailedToSetGroupNameProperty(CFError?)
        case FailedToAddGroupRecord(CFError?)
        case FailedToSaveAddressBook(CFError?)
    }

    public init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        super.init(suppressPermissionRequest: silent, handler: { (addressBook, continueWithError) in

            let group: ABRecordRef = ABGroupCreate().takeRetainedValue()
            var error: Unmanaged<CFError>?
            if !ABRecordSetValue(group, kABGroupNameProperty, groupName, &error) {
                continueWithError(error: Error.FailedToSetGroupNameProperty(error?.takeRetainedValue()))
            }
            else if !ABAddressBookAddRecord(addressBook, group, &error) {
                continueWithError(error: Error.FailedToAddGroupRecord(error?.takeRetainedValue()))
            }
            else if !ABAddressBookSave(addressBook, &error) {
                continueWithError(error: Error.FailedToSaveAddressBook(error?.takeRetainedValue()))
            }
        })
    }
}













