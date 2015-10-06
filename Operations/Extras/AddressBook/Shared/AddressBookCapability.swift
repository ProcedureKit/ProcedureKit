//
//  AddressBookCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import AddressBook
import Contacts

public enum AddressBookAuthorizationStatus: Int, AuthorizationStatusType {

    public enum EntityType {
        case Contacts
    }

    case NotDetermined
    case Restricted
    case Denied
    case Authorized

    public func isRequirementMet(requirement: EntityType) -> Bool {
        if case .Authorized = self {
            return true
        }
        return false
    }
}

public protocol AddressBookRegistrarType: CapabilityRegistrarType {

    func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus
    func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void)
}

public class _AddressBookCapability<Registrar: AddressBookRegistrarType>: NSObject, CapabilityType {

    public let name = "Address Book"
    public let requirement: AddressBookAuthorizationStatus.EntityType

    let registrar: Registrar

    public required init(_ requirement: AddressBookAuthorizationStatus.EntityType = .Contacts, registrar: Registrar = Registrar()) {
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    public func isAvailable() -> Bool {
        return true
    }

    public func authorizationStatus(completion: AddressBookAuthorizationStatus -> Void) {
        completion(registrar.opr_authorizationStatusForRequirement(requirement))
    }

    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        switch registrar.opr_authorizationStatusForRequirement(requirement) {
        case .NotDetermined:
            registrar.opr_requestAccessForRequirement(requirement) { success, error in
                completion()
            }
        default:
            completion()
        }
    }
}

public class UnifiedAddressBook: AddressBookRegistrarType {

    let registrar: AddressBookRegistrarType

    public required init() {
        if #available(iOS 9.0, OSX 10.11, *) {
            registrar = SystemContactStore()
        }
        else {
            registrar = SystemAddressBookRegistrar()
        }
    }

    public func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus {
        return registrar.opr_authorizationStatusForRequirement(entityType)
    }

    public func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void) {
        registrar.opr_requestAccessForRequirement(entityType, completion: completion)
    }
}

@available(iOSApplicationExtension 9.0, *)
extension SystemContactStore: AddressBookRegistrarType {

    public func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus {
        return opr_authorizationStatusForEntityType(CNEntityType(entity: entityType)).addressBookAuthorizationStatus
    }

    public func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void) {
        opr_requestAccessForEntityType(CNEntityType(entity: entityType), completion: completion)
    }
}

extension SystemAddressBookRegistrar: AddressBookRegistrarType {

    public func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus {
        return status.addressBookAuthorizationStatus
    }

    public func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void) {
    }
}

extension Capability {
    public typealias AddressBook = _AddressBookCapability<UnifiedAddressBook>
}


/// MARK - Helpers

@available(iOS 9.0, OSX 10.11, *)
extension CNAuthorizationStatus {
    var addressBookAuthorizationStatus: AddressBookAuthorizationStatus {
        switch self {
        case .NotDetermined: return .NotDetermined
        case .Restricted: return .Restricted
        case .Denied: return .Denied
        case .Authorized: return .Authorized
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension CNEntityType {
    init(entity: AddressBookAuthorizationStatus.EntityType) {
        self = .Contacts
    }
}

@available(iOS, deprecated=9.0)
extension ABAuthorizationStatus {
    var addressBookAuthorizationStatus: AddressBookAuthorizationStatus {
        switch self {
        case .NotDetermined: return .NotDetermined
        case .Restricted: return .Restricted
        case .Denied: return .Denied
        case .Authorized: return .Authorized
        }
    }
}



