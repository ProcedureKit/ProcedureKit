//
//  ContactsOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts

@available(iOS 9.0, OSX 10.11, *)
public class ContactsOperation: Operation {

    public enum ContainerIdentifier {
        case Default
        case Identifier(String)
    }

    public let store = CNContactStore()
    let registrar: ContactsPermissionRegistrar
    let entityType: CNEntityType
    let containerId: ContainerIdentifier

    var allGroupsPredicate: NSPredicate {
        return CNGroup.predicateForGroupsInContainerWithIdentifier(containerIdentifier)
    }

    public var containerIdentifier: String {
        switch containerId {
        case .Default:
            return store.defaultContainerIdentifier()
        case .Identifier(let id):
            return id
        }
    }

    public init(containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts) {
        self.entityType = entityType
        self.containerId = containerId
        self.registrar = store
    }

    init(containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts, registrar: ContactsPermissionRegistrar) {
        self.entityType = entityType
        self.containerId = containerId
        self.registrar = registrar
    }

    public override func execute() {
        requestAccess()
    }

    final func requestAccess() {
        switch registrar.opr_authorizationStatusForEntityType(entityType) {
        case .NotDetermined:
            registrar.opr_requestAccessForEntityType(entityType, completion: requestAccessDidComplete)
        case .Authorized:
            requestAccessDidComplete(true, error: .None)
        default:
            finish(ContactsPermissionError.ContactsAccessDenied)
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
            finish(ContactsPermissionError.ContactsErrorOccured(error))

        case (false, _):
            finish(ContactsPermissionError.ContactsUnknownErrorOccured)
        }
    }

    public func executeContactsTask() throws {
        // no-op
    }

    // Public API

    public func allGroups() throws -> [CNGroup] {
        return try store.groupsMatchingPredicate(allGroupsPredicate)
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
        try store.enumerateContactsWithFetchRequest(fetch) { contact, _ in
            save.addMember(contact, toGroup: group)
        }
        try store.executeSaveRequest(save)
    }
}

@available(iOS 9.0, OSX 10.11, *)
public class ContactsCreateGroup: ContactsOperation {

    let groupName: String

    public init(groupName: String, containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts) {
        self.groupName = groupName
        super.init(entityType: entityType, containerId: containerId)
    }

    init(groupName: String, containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts, registrar: ContactsPermissionRegistrar) {
        self.groupName = groupName
        super.init(entityType: entityType, containerId: containerId, registrar: registrar)
    }

    public override func executeContactsTask() throws {
        let group = CNMutableGroup()
        group.name = groupName

        let save = CNSaveRequest()
        save.addGroup(group, toContainerWithIdentifier: containerIdentifier)

        try store.executeSaveRequest(save)
    }
}

@available(iOS 9.0, OSX 10.11, *)
public class ContactsGetGroup: ContactsOperation {

    let groupName: String

    public var group: CNGroup? = .None

    public init(groupName: String, containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts) {
        self.groupName = groupName
        super.init(entityType: entityType, containerId: containerId)
    }

    init(groupName: String, containerId: ContainerIdentifier = .Default, entityType: CNEntityType = .Contacts, registrar: ContactsPermissionRegistrar) {
        self.groupName = groupName
        super.init(entityType: entityType, containerId: containerId, registrar: registrar)
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


@available(iOS 9.0, OSX 10.11, *)
extension CNContactStore {

    public func flatMapAllContactsWithFetchRequest<T>(fetchRequest: CNContactFetchRequest, transform: CNContact -> T?) throws -> [T] {
        var result = [T]()
        try enumerateContactsWithFetchRequest(fetchRequest) { contact, _ in
            if let tmp = transform(contact) {
                result.append(tmp)
            }
        }
        return result
    }
}









