//
//  AddressBookConditions.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

public struct AddressBookCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthorizationDenied
        case AuthorizationRestricted
        case AuthorizationNotDetermined
    }

    public let name = "Address Book"
    public let isMutuallyExclusive = false
    private let registrar: AddressBookPermissionRegistrar

    public init(registrar: AddressBookPermissionRegistrar? = .None) {
        self.registrar = registrar ?? SystemAddressBookRegistrar()
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        switch registrar.status {
        case .NotDetermined:
            return AddressBookOperation(registrar: registrar)
        default:
            return .None
        }
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
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

public struct AddressBookGroupExistsCondition: OperationCondition {

    private static let queue = OperationQueue()

    public let name = "Address Book"
    public let isMutuallyExclusive = false

    private let create: AddressBookCreateGroup
    private let get: AddressBookGetGroup
    private var queue: OperationQueue {
        return AddressBookGroupExistsCondition.queue
    }

    public init(registrar: AddressBookPermissionRegistrar? = .None, name: String) {
        create = AddressBookCreateGroup(registrar: registrar, name: name)
        get = AddressBookGetGroup(registrar: registrar, name: name)
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return create
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        get.addObserver(BlockObserver { (op, errors) in
            if self.get == op {
                if errors.isEmpty {
                    completion(.Satisfied)
                }
                else if let error = errors.first as? AddressBook.Error {
                    completion(.Failed(error))
                }
            }
        })
        queue.addOperation(get)
    }
}



