//
//  ContactsOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
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
public protocol ContactsPermissionRegistrar {
    init()    
    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus
    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void)
}

@available(iOS 9.0, OSX 10.11, *)
public protocol ContactStoreType: ContactsPermissionRegistrar {
    func opr_defaultContainerIdentifier() -> String
    func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact
    func opr_unifiedContactsMatchingPredicate(predicate: NSPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact]
    func opr_groupsMatchingPredicate(predicate: NSPredicate?) throws -> [CNGroup]
    func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws
    func opr_executeSaveRequest(saveRequest: CNSaveRequest) throws
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

// MARK: - Public Type Interfaces

@available(iOS 9.0, OSX 10.11, *)
public typealias ContactsOperation = _ContactsOperation<CNContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias GetContacts = _GetContacts<CNContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias CreateContactsGroup = _CreateContactsGroup<CNContactStore>

@available(iOS 9.0, OSX 10.11, *)
public typealias GetContactsGroup = _GetContactsGroup<CNContactStore>




// MARK: - Testable Class Interfaces

// MARK: - ContactsAccess

@available(iOS 9.0, OSX 10.11, *)
public class _ContactsAccess<Store: ContactsPermissionRegistrar>: Operation {
    public let store: Store
    let entityType: CNEntityType

    init(entityType: CNEntityType = .Contacts, contactStore: Store) {
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
        case .NotDetermined:
            store.opr_requestAccessForEntityType(entityType, completion: requestAccessDidComplete)
        case .Authorized:
            requestAccessDidComplete(true, error: .None)
        case .Denied:
            finish(ContactsPermissionError.AuthorizationDenied)
        case .Restricted:
            finish(ContactsPermissionError.AuthorizationRestricted)
        }
    }

    final func requestAccessDidComplete(success: Bool, error: NSError?) {
        switch (success, error) {

        case (true, _):
            do {
                try executeContactsTask()
                finish()
            }
            catch let error {
                finish(error)
            }

        case let (false, .Some(error)):
            finish(ContactsError.ErrorOccured(error))

        case (false, _):
            finish(ContactsError.UnknownErrorOccured)
        }
    }

    public func executeContactsTask() throws {
        // no-op
    }
}

// MARK: - ContactsOperation

@available(iOS 9.0, OSX 10.11, *)
public class _ContactsOperation<Store: ContactStoreType>: _ContactsAccess<Store> {

    let containerId: CNContainer.ID

    public var containerIdentifier: String {
        return containerId.identifier
    }

    public init(containerId: CNContainer.ID = .Default, entityType: CNEntityType = .Contacts, contactStore: Store = Store()) {
        self.containerId = containerId
        super.init(entityType: entityType, contactStore: Store())
        name = "Contacts Operation"
    }

    // Public API

    public func allGroups() throws -> [CNGroup] {
        return try store.opr_groupsMatchingPredicate(.None)
    }

    public func groupsNamed(groupName: String) throws -> [CNGroup] {
        return try allGroups().filter { $0.name == groupName }
    }

    public func addContactsWithIdentifiers(contactIDs: [String], toGroupNamed groupName: String) throws {
        guard contactIDs.count > 0 else { return }

        let save = CNSaveRequest()

        let group: CNGroup = try {
            if let group = try self.groupsNamed(groupName).first {
                return group
            }
            let group = CNMutableGroup()
            group.name = groupName
            save.addGroup(group, toContainerWithIdentifier: containerIdentifier)
            return group
        }()

        let fetch = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey])
        fetch.predicate = CNContact.predicateForContactsWithIdentifiers(contactIDs)
        try store.opr_enumerateContactsWithFetchRequest(fetch) { contact, _ in
            save.addMember(contact, toGroup: group)
        }
        try store.opr_executeSaveRequest(save)
    }
}

// MARK: - GetContacts

@available(iOS 9.0, OSX 10.11, *)
public class _GetContacts<Store: ContactStoreType>: _ContactsOperation<Store> {

    let predicate: CNContact.Predicate
    let keysToFetch: [CNKeyDescriptor]

    public var contacts = [CNContact]()

    public var contact: CNContact? {
        return contacts.first
    }

    public convenience init(identifier: String, keysToFetch: [CNKeyDescriptor]) {
        self.init(predicate: .WithIdentifiers([identifier]), keysToFetch: keysToFetch)
    }

    public init(predicate: CNContact.Predicate, keysToFetch: [CNKeyDescriptor], containerId: CNContainer.ID = .Default, entityType: CNEntityType = .Contacts, contactStore: Store = Store()) {
        self.predicate = predicate
        self.keysToFetch = keysToFetch
        super.init(containerId: containerId, entityType: entityType, contactStore: contactStore)
    }
    
    public override func executeContactsTask() throws {
        switch predicate {
        case .WithIdentifiers(let identifiers) where identifiers.count == 1:
            let contact = try store.opr_unifiedContactWithIdentifier(identifiers.first!, keysToFetch: keysToFetch)
            contacts = [contact]
        default:
            contacts = try store.opr_unifiedContactsMatchingPredicate(predicate.predicate, keysToFetch: keysToFetch)
        }
    }
}

@available(iOS 9.0, OSX 10.11, *)
public class _CreateContactsGroup<Store: ContactStoreType>: _ContactsOperation<Store> {

    let groupName: String

    public init(groupName: String, containerId: CNContainer.ID = .Default, entityType: CNEntityType = .Contacts, contactStore: Store = Store()) {
        self.groupName = groupName
        super.init(containerId: containerId, entityType: entityType, contactStore: contactStore)
    }

    public override func executeContactsTask() throws {
        let group = CNMutableGroup()
        group.name = groupName

        let save = CNSaveRequest()
        save.addGroup(group, toContainerWithIdentifier: containerIdentifier)

        try store.opr_executeSaveRequest(save)
    }
}

@available(iOS 9.0, OSX 10.11, *)
public class _GetContactsGroup<Store: ContactStoreType>: _ContactsOperation<Store> {

    let groupName: String

    public var group: CNGroup? = .None

    public init(groupName: String, containerId: CNContainer.ID = .Default, entityType: CNEntityType = .Contacts, contactStore: Store = Store()) {
        self.groupName = groupName
        super.init(containerId: containerId, entityType: entityType, contactStore: contactStore)
    }

    public override func executeContactsTask() throws {
        do {
            group = try groupsNamed(groupName).first
            finish()
        }
        catch let error {
            finish(error)
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
extension CNContactStore: ContactStoreType {

    public func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        return self.dynamicType.authorizationStatusForEntityType(entityType)
    }

    public func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        requestAccessForEntityType(entityType, completionHandler: completion)
    }

    public func opr_defaultContainerIdentifier() -> String {
        return defaultContainerIdentifier()
    }

    public func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact {
        return try unifiedContactWithIdentifier(identifier, keysToFetch: keys)
    }

    public func opr_unifiedContactsMatchingPredicate(predicate: NSPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        return try unifiedContactsMatchingPredicate(predicate, keysToFetch: keys)
    }

    public func opr_groupsMatchingPredicate(predicate: NSPredicate?) throws -> [CNGroup] {
        return try groupsMatchingPredicate(predicate)
    }

    public func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        try enumerateContactsWithFetchRequest(fetchRequest, usingBlock: block)
    }

    public func opr_executeSaveRequest(saveRequest: CNSaveRequest) throws {
        try executeSaveRequest(saveRequest)
    }
}






