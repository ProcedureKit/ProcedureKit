//
//  ContactsOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

// MARK: - Public Type Interfaces

@available(iOS 9.0, OSX 10.11, *)
public typealias ContactsOperation = _ContactsOperation<SystemContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias GetContacts = _GetContacts<SystemContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias GetContactsGroup = _GetContactsGroup<SystemContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias AddContactsToGroup = _AddContactsToGroup<SystemContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias RemoveContactsFromGroup = _RemoveContactsFromGroup<SystemContactStore>


// MARK: - Testable Class Interfaces

// MARK: - ContactsAccess

@available(iOS 9.0, OSX 10.11, *)
public class _ContactsAccess<Store: ContactStoreType>: OldOperation {

    let entityType: CNEntityType
    public let store: Store

    init(entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.entityType = entityType
        self.store = contactStore
        super.init()
        name = "Contacts Access"
    }

    public override func execute() {
        requestAccess()
    }

    final func requestAccess() {
        switch store.opr_authorizationStatusForEntityType(entityType) {
        case .notDetermined:
            store.opr_requestAccessForEntityType(entityType, completion: requestAccessDidComplete)
        case .authorized:
            requestAccessDidComplete(true, error: .none)
        case .denied:
            finish(ContactsPermissionError.authorizationDenied)
        case .restricted:
            finish(ContactsPermissionError.authorizationRestricted)
        }
    }

    final func requestAccessDidComplete(_ success: Bool, error: NSError?) {
        switch (success, error) {

        case (true, _):
            do {
                try executeContactsTask()
                finish()
            }
            catch let error {
                finish(error)
            }

        case let (false, .some(error)):
            finish(ContactsError.errorOccured(error))

        case (false, _):
            finish(ContactsError.unknownErrorOccured)
        }
    }

    public func executeContactsTask() throws {
        // no-op
    }
}

// MARK: - ContactsOperation

@available(iOS 9.0, OSX 10.11, *)
public class _ContactsOperation<Store: ContactStoreType>: _ContactsAccess<Store> {

    let containerId: ContainerID

    public var containerIdentifier: String {
        return containerId.identifier
    }

    public init(containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.containerId = containerId
        super.init(entityType: entityType, contactStore: contactStore)
        name = "Contacts OldOperation"
    }

    // Public API

    public func containersWithPredicate(_ predicate: ContainerPredicate) throws -> [CNContainer] {
        return try store.opr_containersMatchingPredicate(predicate)
    }

    public func container() throws -> CNContainer? {
        return try containersWithPredicate(.withIdentifiers([containerId])).first
    }

    public func allGroups() throws -> [CNGroup] {
        return try store.opr_groupsMatchingPredicate(.none)
    }

    public func groupsNamed(_ groupName: String) throws -> [CNGroup] {
        return try allGroups().filter { $0.name == groupName }
    }

    public func createGroupWithName(_ name: String) throws -> CNGroup {
        let group = CNMutableGroup()
        group.name = name

        let save = Store.SaveRequest()
        save.opr_addGroup(group, toContainerWithIdentifier: containerIdentifier)

        try store.opr_executeSaveRequest(save)

        return group
    }

    public func removeGroupWithName(_ name: String) throws {
        if let group = try groupsNamed(name).first {
            let save = Store.SaveRequest()
            // swiftlint:disable force_cast
            save.opr_deleteGroup(group.mutableCopy() as! CNMutableGroup)
            // swiftlint:enable force_cast
            try store.opr_executeSaveRequest(save)
        }
    }

    public func addContactsWithIdentifiers(_ contactIDs: [String], toGroupNamed groupName: String) throws {
        guard contactIDs.count > 0 else { return }

        let group = try groupsNamed(groupName).first ?? createGroupWithName(groupName)
        let save = Store.SaveRequest()

        let fetch = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey])
        fetch.predicate = CNContact.predicateForContacts(withIdentifiers: contactIDs)

        try store.opr_enumerateContactsWithFetchRequest(fetch) { contact, _ in
            save.opr_addMember(contact, toGroup: group)
        }

        try store.opr_executeSaveRequest(save)
    }

    public func removeContactsWithIdentifiers(_ contactIDs: [String], fromGroupNamed groupName: String) throws {
        guard contactIDs.count > 0, let group = try groupsNamed(groupName).first else { return }

        let save = Store.SaveRequest()

        let fetch = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey])
        fetch.predicate = CNContact.predicateForContacts(withIdentifiers: contactIDs)

        try store.opr_enumerateContactsWithFetchRequest(fetch) { contact, _ in
            save.opr_removeMember(contact, fromGroup: group)
        }

        try store.opr_executeSaveRequest(save)
    }
}

// MARK: - GetContacts

@available(iOS 9.0, OSX 10.11, *)
public class _GetContacts<Store: ContactStoreType>: _ContactsOperation<Store> {

    let predicate: ContactPredicate
    let keysToFetch: [CNKeyDescriptor]

    public var contacts = [CNContact]()

    public var contact: CNContact? {
        return contacts.first
    }

    public convenience init(identifier: String, keysToFetch: [CNKeyDescriptor]) {
        self.init(predicate: .withIdentifiers([identifier]), keysToFetch: keysToFetch)
    }

    public init(predicate: ContactPredicate, keysToFetch: [CNKeyDescriptor], containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.predicate = predicate
        self.keysToFetch = keysToFetch
        super.init(containerId: containerId, entityType: entityType, contactStore: contactStore)
        name = "Get Contacts"
    }

    public override func executeContactsTask() throws {
        switch predicate {
        case .withIdentifiers(let identifiers) where identifiers.count == 1:
            let contact = try store.opr_unifiedContactWithIdentifier(identifiers.first!, keysToFetch: keysToFetch)
            contacts = [contact]
        default:
            contacts = try store.opr_unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
        }
    }
}

// MARK: - GetContactsGroup

@available(iOS 9.0, OSX 10.11, *)
public class _GetContactsGroup<Store: ContactStoreType>: _ContactsOperation<Store> {

    let groupName: String
    let createIfNecessary: Bool

    public var group: CNGroup? = .none

    public init(groupName: String, createIfNecessary: Bool = true, containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.groupName = groupName
        self.createIfNecessary = createIfNecessary
        super.init(containerId: containerId, entityType: entityType, contactStore: contactStore)
        name = "Get Contacts Group"
    }

    public override func executeContactsTask() throws {
        group = try groupsNamed(groupName).first

        if createIfNecessary && group == nil {
            group = try createGroupWithName(groupName)
        }
    }
}

// MARK: - RemoveContactsGroup

@available(iOS 9.0, OSX 10.11, *)
public class _RemoveContactsGroup<Store: ContactStoreType>: _GetContactsGroup<Store> {

    public init(groupName: String, containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        super.init(groupName: groupName, createIfNecessary: false, containerId: containerId, entityType: entityType, contactStore: contactStore)
        name = "Remove Contacts Group"
    }

    public override func executeContactsTask() throws {
        try removeGroupWithName(groupName)
    }
}


// MARK: - AddContactsToGroup

@available(iOS 9.0, OSX 10.11, *)
public class _AddContactsToGroup<Store: ContactStoreType>: _GetContactsGroup<Store> {

    let contactIDs: [String]

    public init(groupName: String, createIfNecessary: Bool = true, contactIDs: [String], containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.contactIDs = contactIDs
        super.init(groupName: groupName, createIfNecessary: createIfNecessary, containerId: containerId, entityType: entityType, contactStore: contactStore)
        name = "Add Contacts to Group: \(groupName)"
    }

    public override func executeContactsTask() throws {
        try super.executeContactsTask()
        try addContactsWithIdentifiers(contactIDs, toGroupNamed: groupName)
    }
}

// MARK: - RemoveContactsFromGroup

@available(iOS 9.0, OSX 10.11, *)
public class _RemoveContactsFromGroup<Store: ContactStoreType>: _GetContactsGroup<Store> {

    let contactIDs: [String]
    public init(groupName: String, contactIDs: [String], containerId: ContainerID = .default, entityType: CNEntityType = .contacts, contactStore: Store = Store()) {
        self.contactIDs = contactIDs
        super.init(groupName: groupName, createIfNecessary: false, containerId: containerId, entityType: entityType, contactStore: contactStore)
        name = "Remove Contacts from Group: \(groupName)"
    }

    public override func executeContactsTask() throws {
        try super.executeContactsTask()
        try removeContactsWithIdentifiers(contactIDs, fromGroupNamed: groupName)
    }
}
