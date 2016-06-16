//
//  Contacts.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, OSX 10.11, *)
public enum ContactsPermissionError: ErrorProtocol {
    case authorizationDenied
    case authorizationRestricted
    case authorizationNotDetermined
}

@available(iOS 9.0, OSX 10.11, *)
public enum ContactsError: ErrorProtocol {
    case unknownErrorOccured
    case errorOccured(NSError)
}

@available(iOS 9.0, OSX 10.11, *)
public protocol ContactSaveRequestType {
    init()
    func opr_addContact(_ contact: CNMutableContact, toContainerWithIdentifier identifier: String?)
    func opr_updateContact(_ contact: CNMutableContact)
    func opr_deleteContact(_ contact: CNMutableContact)
    func opr_addGroup(_ group: CNMutableGroup, toContainerWithIdentifier identifier: String?)
    func opr_updateGroup(_ group: CNMutableGroup)
    func opr_deleteGroup(_ group: CNMutableGroup)
    func opr_addMember(_ contact: CNContact, toGroup group: CNGroup)
    func opr_removeMember(_ contact: CNContact, fromGroup group: CNGroup)
}

@available(iOS 9.0, OSX 10.11, *)
public protocol ContactStoreType {
    associatedtype SaveRequest: ContactSaveRequestType

    init()
    func opr_authorizationStatusForEntityType(_ entityType: CNEntityType) -> CNAuthorizationStatus
    func opr_requestAccessForEntityType(_ entityType: CNEntityType, completion: (Bool, NSError?) -> Void)
    func opr_defaultContainerIdentifier() -> String
    func opr_unifiedContactWithIdentifier(_ identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact
    func opr_unifiedContactsMatchingPredicate(_ predicate: ContactPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact]
    func opr_groupsMatchingPredicate(_ predicate: GroupPredicate?) throws -> [CNGroup]
    func opr_containersMatchingPredicate(_ predicate: ContainerPredicate?) throws -> [CNContainer]
    func opr_enumerateContactsWithFetchRequest(_ fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws
    func opr_executeSaveRequest(_ saveRequest: SaveRequest) throws
}

@available(iOS 9.0, OSX 10.11, *)
public enum ContainerID {
    case `default`
    case Identifier(String)

    var identifier: String {
        switch self {
        case .default:
            return CNContactStore().defaultContainerIdentifier()
        case .Identifier(let id):
            return id
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
public enum ContainerPredicate {
    case withIdentifiers([ContainerID])
    case ofContactWithIdentifier(String)
    case ofGroupWithIdentifier(String)

    var predicate: Predicate {
        switch self {
        case .withIdentifiers(let IDs):
            return CNContainer.predicateForContainers(withIdentifiers: IDs.map { $0.identifier })
        case .ofContactWithIdentifier(let contactID):
            return CNContainer.predicateForContainerOfContact(withIdentifier: contactID)
        case .ofGroupWithIdentifier(let groupID):
            return CNContainer.predicateForContainerOfGroup(withIdentifier: groupID)
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
public enum ContactPredicate {
    case matchingName(String)
    case withIdentifiers([String])
    case inGroupWithIdentifier(String)
    case inContainerWithID(ContainerID)

    var predicate: Predicate {
        switch self {
        case .matchingName(let name):
            return CNContact.predicateForContacts(matchingName: name)
        case .withIdentifiers(let identifiers):
            return CNContact.predicateForContacts(withIdentifiers: identifiers)
        case .inGroupWithIdentifier(let identifier):
            return CNContact.predicateForContactsInGroup(withIdentifier: identifier)
        case .inContainerWithID(let id):
            return CNContact.predicateForContactsInContainer(withIdentifier: id.identifier)
        }
    }
}


@available(iOS 9.0, OSX 10.11, *)
public enum GroupPredicate {
    case withIdentifiers([String])
    case inContainerWithID(ContainerID)

    var predicate: Predicate {
        switch self {
        case .withIdentifiers(let identifiers):
            return CNGroup.predicateForGroups(withIdentifiers: identifiers)
        case .inContainerWithID(let id):
            return CNGroup.predicateForGroupsInContainer(withIdentifier: id.identifier)
        }
    }
}


// MARK: - Helpers

@available(iOS 9.0, OSX 10.11, *)
extension ContactStoreType {

    public func flatMapAllContactsWithFetchRequest<T>(_ fetchRequest: CNContactFetchRequest, transform: (CNContact) -> T?) throws -> [T] {
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

    public func opr_addContact(_ contact: CNMutableContact, toContainerWithIdentifier identifier: String?) {
        add(contact, toContainerWithIdentifier: identifier)
    }

    public func opr_updateContact(_ contact: CNMutableContact) {
        update(contact)
    }
    public func opr_deleteContact(_ contact: CNMutableContact) {
        delete(contact)
    }

    public func opr_addGroup(_ group: CNMutableGroup, toContainerWithIdentifier identifier: String?) {
        add(group, toContainerWithIdentifier: identifier)
    }

    public func opr_updateGroup(_ group: CNMutableGroup) {
        update(group)
    }

    public func opr_deleteGroup(_ group: CNMutableGroup) {
        delete(group)
    }

    public func opr_addMember(_ contact: CNContact, toGroup group: CNGroup) {
        addMember(contact, to: group)
    }

    public func opr_removeMember(_ contact: CNContact, fromGroup group: CNGroup) {
        removeMember(contact, from: group)
    }
}

@available(iOS 9.0, OSX 10.11, *)
public struct SystemContactStore: ContactStoreType {
    public typealias SaveRequest = CNSaveRequest

    let store: CNContactStore

    public init() {
        store = CNContactStore()
    }

    public func opr_authorizationStatusForEntityType(_ entityType: CNEntityType) -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: entityType)
    }

    public func opr_requestAccessForEntityType(_ entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        store.requestAccess(for: entityType, completionHandler: completion)
    }

    public func opr_defaultContainerIdentifier() -> String {
        return store.defaultContainerIdentifier()
    }

    public func opr_unifiedContactWithIdentifier(_ identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact {
        return try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
    }

    public func opr_unifiedContactsMatchingPredicate(_ predicate: ContactPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        return try store.unifiedContacts(matching: predicate.predicate, keysToFetch: keys)
    }

    public func opr_groupsMatchingPredicate(_ predicate: GroupPredicate?) throws -> [CNGroup] {
        return try store.groups(matching: predicate?.predicate)
    }

    public func opr_containersMatchingPredicate(_ predicate: ContainerPredicate?) throws -> [CNContainer] {
        return try store.containers(matching: predicate?.predicate)
    }

    public func opr_enumerateContactsWithFetchRequest(_ fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        try store.enumerateContacts(with: fetchRequest, usingBlock: block)
    }

    public func opr_executeSaveRequest(_ saveRequest: CNSaveRequest) throws {
        try store.execute(saveRequest)
    }
}




@available(iOS 9.0, OSX 10.11, *)
extension ContainerID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default: return "Default Identifier"
        case .Identifier(let id): return id
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension ContainerID: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

@available(iOS 9.0, OSX 10.11, *)
public func == (lhs: ContainerID, rhs: ContainerID) -> Bool {
    switch (lhs, rhs) {
    case (.default, .default):
        return true
    case let (.Identifier(aId), .Identifier(bId)):
        return aId == bId
    default:
        return false
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension ContainerPredicate: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .withIdentifiers(identifiers):
            return "Container with identifiers: \(identifiers)"
        case let .ofContactWithIdentifier(contactId):
            return "Container with contact id: \(contactId)"
        case let .ofGroupWithIdentifier(groupId):
            return "Container with group id: \(groupId)"
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension ContainerPredicate: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

@available(iOS 9.0, OSX 10.11, *)
public func == (lhs: ContainerPredicate, rhs: ContainerPredicate) -> Bool {
    switch (lhs, rhs) {
    case let (.withIdentifiers(aIds), .withIdentifiers(bIds)):
        return aIds == bIds
    case let (.ofContactWithIdentifier(aId), .ofContactWithIdentifier(bId)):
        return aId == bId
    case let (.ofGroupWithIdentifier(aId), .ofGroupWithIdentifier(bId)):
        return aId == bId
    default:
        return false
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension GroupPredicate: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .withIdentifiers(groupIds):
            let tmp = groupIds.joined(separator: ", ")
            return "groups with identifiers: \(tmp)"
        case let .inContainerWithID(containerId):
            return "groups in container with id: \(containerId.description)"
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension GroupPredicate: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

@available(iOS 9.0, OSX 10.11, *)
public func == (lhs: GroupPredicate, rhs: GroupPredicate) -> Bool {
    switch (lhs, rhs) {
    case let (.withIdentifiers(aIds), .withIdentifiers(bIds)):
        return aIds == bIds
    case let (.inContainerWithID(aId), .inContainerWithID(bId)):
        return aId == bId
    default:
        return false
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension ContactPredicate: CustomStringConvertible {
    public var description: String {
        switch self {
        case .withIdentifiers(let identifiers):
            let tmp = identifiers.joined(separator: ", ")
            return "contacts with identifiers: \(tmp)"
        case .matchingName(let name):
            return "contacts matching name: \(name)"
        case .inContainerWithID(let containerId):
            return "contacts in container with id: \(containerId)"
        case .inGroupWithIdentifier(let groupId):
            return "contacts in group with id: \(groupId)"
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
extension ContactPredicate: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

@available(iOS 9.0, OSX 10.11, *)
public func == (lhs: ContactPredicate, rhs: ContactPredicate) -> Bool {
    switch (lhs, rhs) {
    case let (.withIdentifiers(aIds), .withIdentifiers(bIds)):
        return aIds == bIds
    case let (.matchingName(aName), .matchingName(bName)):
        return aName == bName
    case let (.inContainerWithID(aId), .inContainerWithID(bId)):
        return aId == bId
    case let (.inGroupWithIdentifier(aId), .inGroupWithIdentifier(bId)):
        return aId == bId
    default:
        return false
    }
}
