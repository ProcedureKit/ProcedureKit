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
public protocol ContactSaveRequestType {
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
    typealias SaveRequest: ContactSaveRequestType
    
    init()
    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus
    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void)
    func opr_defaultContainerIdentifier() -> String
    func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact
    func opr_unifiedContactsMatchingPredicate(predicate: Contact.Predicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact]
    func opr_groupsMatchingPredicate(predicate: Group.Predicate?) throws -> [CNGroup]
    func opr_containersMatchingPredicate(predicate: Container.Predicate?) throws -> [CNContainer]
    func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws
    func opr_executeSaveRequest(saveRequest: SaveRequest) throws
}

@available(iOS 9.0, OSX 10.11, *)
public struct Container {
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
public struct Contact {

    public enum Predicate {
        case MatchingName(String)
        case WithIdentifiers([String])
        case InGroupWithIdentifier(String)
        case InContainerWithID(Container.ID)
        
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
public struct Group {
    
    public enum Predicate {
        case WithIdentifiers([String])
        case InContainerWithID(Container.ID)
        
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
extension CNSaveRequest: ContactSaveRequestType {
    
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
    
    public func opr_unifiedContactsMatchingPredicate(predicate: Contact.Predicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        return try store.unifiedContactsMatchingPredicate(predicate.predicate, keysToFetch: keys)
    }
    
    public func opr_groupsMatchingPredicate(predicate: Group.Predicate?) throws -> [CNGroup] {
        return try store.groupsMatchingPredicate(predicate?.predicate)
    }
    
    public func opr_containersMatchingPredicate(predicate: Container.Predicate?) throws -> [CNContainer] {
        return try store.containersMatchingPredicate(predicate?.predicate)
    }
    
    public func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        try store.enumerateContactsWithFetchRequest(fetchRequest, usingBlock: block)
    }
    
    public func opr_executeSaveRequest(saveRequest: CNSaveRequest) throws {
        try store.executeSaveRequest(saveRequest)
    }
}





extension Container.ID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Default: return "Default Identifier"
        case .Identifier(let id): return id
        }
    }
}

extension Container.ID: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(a: Container.ID, b: Container.ID) -> Bool {
    switch (a, b) {
    case (.Default, .Default):
        return true
    case let (.Identifier(aId), .Identifier(bId)):
        return aId == bId
    default:
        return false
    }
}

extension Container.Predicate: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .WithIdentifiers(identifiers):
            return "Container with identifiers: \(identifiers)"
        case let .OfContactWithIdentifier(contactId):
            return "Container with contact id: \(contactId)"
        case let .OfGroupWithIdentifier(groupId):
            return "Container with group id: \(groupId)"
        }
    }
}

extension Container.Predicate: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(a: Container.Predicate, b: Container.Predicate) -> Bool {
    switch (a, b) {
    case let (.WithIdentifiers(aIds), .WithIdentifiers(bIds)):
        return aIds == bIds
    case let (.OfContactWithIdentifier(aId), .OfContactWithIdentifier(bId)):
        return aId == bId
    case let (.OfGroupWithIdentifier(aId), .OfGroupWithIdentifier(bId)):
        return aId == bId
    default:
        return false
    }
}

extension Group.Predicate: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .WithIdentifiers(groupIds):
            return groupIds.joinWithSeparator(" ")
        case let .InContainerWithID(containerId):
            return containerId.description
        }
    }
}

extension Group.Predicate: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(a: Group.Predicate, b: Group.Predicate) -> Bool {
    switch (a, b) {
    case let (.WithIdentifiers(aIds), .WithIdentifiers(bIds)):
        return aIds == bIds
    case let (.InContainerWithID(aId), .InContainerWithID(bId)):
        return aId == bId
    default:
        return false
    }
}


