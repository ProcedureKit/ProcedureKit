//
//  Contacts.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, OSX 10.11, *)
public enum ContactsPermissionError: ErrorType {
    case AuthorizationDenied
    case AuthorizationRestricted
    case AuthorizationNotDetermined
}

@available(iOS 9.0, OSX 10.11, *)
public enum ContactsError: ErrorType {
    case UnknownErrorOccured
    case ErrorOccured(NSError)
}

@available(iOS 9.0, OSX 10.11, *)
public protocol ContactsSaveRequestType {
    init()
    func opr_addContact(contact: CNMutableContact, toContainerWithIdentifier identifier: String?)
    func opr_updateContact(contact: CNMutableContact)
    func opr_deleteContact(contact: CNMutableContact)
    func opr_addGroup(group: CNMutableGroup, toContainerWithIdentifier identifier: String?)
    func opr_updateGroup(group: CNMutableGroup)
    func opr_deleteGroup(group: CNMutableGroup)
    func opr_addMember(contact: CNContact, toGroup group: CNGroup)
    func opr_removeMember(contact: CNContact, fromGroup group: CNGroup)
}

@available(iOS 9.0, OSX 10.11, *)
public protocol ContactStoreType {
    typealias SaveRequest: ContactsSaveRequestType
    
    init()
    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus
    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void)
    func opr_defaultContainerIdentifier() -> String
    func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact
    func opr_unifiedContactsMatchingPredicate(predicate: NSPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact]
    func opr_groupsMatchingPredicate(predicate: NSPredicate?) throws -> [CNGroup]
    func opr_containersMatchingPredicate(predicate: NSPredicate?) throws -> [CNContainer]
    func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws
    func opr_executeSaveRequest(saveRequest: SaveRequest) throws
}

@available(iOS 9.0, OSX 10.11, *)
extension CNContainer {
    public enum ID {
        case Default
        case Identifier(String)
        
        var identifier: String {
            switch self {
            case .Default:
                return CNContactStore().defaultContainerIdentifier()
            case .Identifier(let id):
                return id
            }
        }
    }
    
    public enum Predicate {
        case WithIdentifiers([ID])
        case OfContactWithIdentifier(String)
        case OfGroupWithIdentifier(String)
        
        var predicate: NSPredicate {
            switch self {
            case .WithIdentifiers(let IDs):
                return CNContainer.predicateForContainersWithIdentifiers(IDs.map { $0.identifier })
            case .OfContactWithIdentifier(let contactID):
                return CNContainer.predicateForContainerOfContactWithIdentifier(contactID)
            case .OfGroupWithIdentifier(let groupID):
                return CNContainer.predicateForContainerOfGroupWithIdentifier(groupID)
            }
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension CNContact {
    public enum Predicate {
        case MatchingName(String)
        case WithIdentifiers([String])
        case InGroupWithIdentifier(String)
        case InContainerWithID(CNContainer.ID)
        
        var predicate: NSPredicate {
            switch self {
            case .MatchingName(let name):
                return CNContact.predicateForContactsMatchingName(name)
            case .WithIdentifiers(let identifiers):
                return CNContact.predicateForContactsWithIdentifiers(identifiers)
            case .InGroupWithIdentifier(let identifier):
                return CNContact.predicateForContactsInGroupWithIdentifier(identifier)
            case .InContainerWithID(let id):
                return CNContact.predicateForContactsInContainerWithIdentifier(id.identifier)
            }
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension CNGroup {
    
    public enum Predicate {
        case WithIdentifiers([String])
        case InContainerWithID(CNContainer.ID)
        
        var predicate: NSPredicate {
            switch self {
            case .WithIdentifiers(let identifiers):
                return CNGroup.predicateForGroupsWithIdentifiers(identifiers)
            case .InContainerWithID(let id):
                return CNGroup.predicateForGroupsInContainerWithIdentifier(id.identifier)
            }
        }
    }
}

// MARK: - Helpers

@available(iOS 9.0, OSX 10.11, *)
extension ContactStoreType {
    
    public func flatMapAllContactsWithFetchRequest<T>(fetchRequest: CNContactFetchRequest, transform: CNContact -> T?) throws -> [T] {
        var result = [T]()
        try opr_enumerateContactsWithFetchRequest(fetchRequest) { contact, _ in
            if let tmp = transform(contact) {
                result.append(tmp)
            }
        }
        return result
    }
}

// MARK: - Conformance

@available(iOS 9.0, OSX 10.11, *)
extension CNSaveRequest: ContactsSaveRequestType {
    
    public func opr_addContact(contact: CNMutableContact, toContainerWithIdentifier identifier: String?) {
        addContact(contact, toContainerWithIdentifier: identifier)
    }

    public func opr_updateContact(contact: CNMutableContact) {
        updateContact(contact)
    }
    public func opr_deleteContact(contact: CNMutableContact) {
        deleteContact(contact)
    }
    
    public func opr_addGroup(group: CNMutableGroup, toContainerWithIdentifier identifier: String?) {
        addGroup(group, toContainerWithIdentifier: identifier)
    }
    
    public func opr_updateGroup(group: CNMutableGroup) {
        updateGroup(group)
    }
    
    public func opr_deleteGroup(group: CNMutableGroup) {
        deleteGroup(group)
    }
    
    public func opr_addMember(contact: CNContact, toGroup group: CNGroup) {
        addMember(contact, toGroup: group)
    }
    
    public func opr_removeMember(contact: CNContact, fromGroup group: CNGroup) {
        removeMember(contact, fromGroup: group)
    }
}

@available(iOS 9.0, OSX 10.11, *)
public struct SystemContactStore: ContactStoreType {
    public typealias SaveRequest = CNSaveRequest
    
    let store: CNContactStore
    
    public init() {
        store = CNContactStore()
    }
    
    public func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatusForEntityType(entityType)
    }
    
    public func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        store.requestAccessForEntityType(entityType, completionHandler: completion)
    }
    
    public func opr_defaultContainerIdentifier() -> String {
        return store.defaultContainerIdentifier()
    }
    
    public func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact {
        return try store.unifiedContactWithIdentifier(identifier, keysToFetch: keys)
    }
    
    public func opr_unifiedContactsMatchingPredicate(predicate: NSPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        return try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: keys)
    }
    
    public func opr_groupsMatchingPredicate(predicate: NSPredicate?) throws -> [CNGroup] {
        return try store.groupsMatchingPredicate(predicate)
    }
    
    public func opr_containersMatchingPredicate(predicate: NSPredicate?) throws -> [CNContainer] {
        return try store.containersMatchingPredicate(predicate)
    }
    
    public func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        try store.enumerateContactsWithFetchRequest(fetchRequest, usingBlock: block)
    }
    
    public func opr_executeSaveRequest(saveRequest: CNSaveRequest) throws {
        try store.executeSaveRequest(saveRequest)
    }
}




