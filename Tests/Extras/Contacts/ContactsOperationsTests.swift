//
//  ContactsOperationsTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import XCTest
import Contacts

@testable import Operations

@available(iOS 9.0, OSX 10.11, *)
class TestableContactSaveRequest: ContactSaveRequestType {

    var addedContacts = [String: [CNMutableContact]]()
    var updatedContacts = [CNMutableContact]()
    var deletedContacts = [CNMutableContact]()

    var addedGroups = [String: [CNMutableGroup]]()
    var updatedGroups = [CNMutableGroup]()
    var deletedGroupNames = [String]()

    var addedMemberToGroup = [String: [CNContact]]()
    var removedMemberFromGroup = [String: [CNContact]]()

    required init() { }

    func opr_addContact(contact: CNMutableContact, toContainerWithIdentifier identifier: String?) {
        let containerId = identifier ?? ContainerID.Default.identifier
        addedContacts[containerId] = addedContacts[containerId] ?? []
        addedContacts[containerId]!.append(contact)
    }

    func opr_updateContact(contact: CNMutableContact) {
        updatedContacts.append(contact)
    }

    func opr_deleteContact(contact: CNMutableContact) {
        deletedContacts.append(contact)
    }

    func opr_addGroup(group: CNMutableGroup, toContainerWithIdentifier identifier: String?) {
        let containerId = identifier ?? ContainerID.Default.identifier
        addedGroups[containerId] = addedGroups[containerId] ?? []
        addedGroups[containerId]!.append(group)
    }

    func opr_updateGroup(group: CNMutableGroup) {
        updatedGroups.append(group)
    }

    func opr_deleteGroup(group: CNMutableGroup) {
        deletedGroupNames.append(group.name)
    }

    func opr_addMember(contact: CNContact, toGroup group: CNGroup) {
        addedMemberToGroup[group.name] = addedMemberToGroup[group.name] ?? []
        addedMemberToGroup[group.name]!.append(contact)
    }

    func opr_removeMember(contact: CNContact, fromGroup group: CNGroup) {
        removedMemberFromGroup[group.name] = removedMemberFromGroup[group.name] ?? []
        removedMemberFromGroup[group.name]!.append(contact)
    }
}

@available(iOS 9.0, OSX 10.11, *)
class TestableContactsStore: ContactStoreType {

    enum Error: ErrorType {
        case NotImplemented
    }

    var didAccessStatus = false
    var didRequestAccess = false
    var didExecuteSaveRequest: TestableContactSaveRequest? = .None
    var didAccessEnumerateContactsWithFetchRequest: CNContactFetchRequest? = .None

    var didAccessDefaultContainerIdentifier = false
    var didAccessUnifiedContactWithIdentifier = false
    var didAccessUnifiedContactsMatchingPredicate = false
    var didAccessGroupsMatchingPredicate = false
    var didAccessContainersMatchingPredicate = false

    var contactsByIdentifier = Dictionary<String, CNContact>()
    var contactsMatchingPredicate = Dictionary<ContactPredicate, [CNContact]>()
    var contactsToEnumerate = Array<CNMutableContact>()
    var containersMatchingPredicate = Dictionary<ContainerPredicate, [CNContainer]>()
    var groupsMatchingPredicate = Dictionary<GroupPredicate, [CNGroup]>()

    var requestedEntityType: CNEntityType? = .None
    var accessError: NSError? = .None

    var status: CNAuthorizationStatus
    let accessRequestShouldSucceed: Bool

    required init() {
        self.status = .NotDetermined
        self.accessRequestShouldSucceed = true
    }

    init(status: CNAuthorizationStatus, accessRequestShouldSucceed: Bool = true) {
        self.status = status
        self.accessRequestShouldSucceed = accessRequestShouldSucceed
    }

    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        didAccessStatus = true
        requestedEntityType = entityType
        return status
    }

    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        didRequestAccess = true
        requestedEntityType = entityType
        if accessRequestShouldSucceed {
            status = .Authorized
            completion(true, .None)
        }
        else {
            status = .Denied
            completion(false, accessError)
        }
    }

    func opr_defaultContainerIdentifier() -> String {
        didAccessDefaultContainerIdentifier = true
        return "not implmented"
    }

    func opr_unifiedContactWithIdentifier(identifier: String, keysToFetch keys: [CNKeyDescriptor]) throws -> CNContact {
        didAccessUnifiedContactWithIdentifier = true
        if let contact = contactsByIdentifier[identifier] {
            return contact
        }
        throw NSError(domain: CNErrorDomain, code: CNErrorCode.RecordDoesNotExist.rawValue, userInfo: nil)
    }

    func opr_unifiedContactsMatchingPredicate(predicate: ContactPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        didAccessUnifiedContactsMatchingPredicate = true
        if let contacts = contactsMatchingPredicate[predicate] {
            return contacts
        }
        throw NSError(domain: CNErrorDomain, code: CNErrorCode.RecordDoesNotExist.rawValue, userInfo: nil)
    }

    func opr_groupsMatchingPredicate(predicate: GroupPredicate?) throws -> [CNGroup] {
        didAccessGroupsMatchingPredicate = true
        if let predicate = predicate {
            return groupsMatchingPredicate[predicate] ?? []
        }
        return groupsMatchingPredicate.values.flatMap { $0 }
    }

    func opr_containersMatchingPredicate(predicate: ContainerPredicate?) throws -> [CNContainer] {
        didAccessContainersMatchingPredicate = true
        if let predicate = predicate {
            return containersMatchingPredicate[predicate] ?? []
        }
        return containersMatchingPredicate.values.flatMap { $0 }
    }

    func opr_enumerateContactsWithFetchRequest(fetchRequest: CNContactFetchRequest, usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        didAccessEnumerateContactsWithFetchRequest = fetchRequest
        var stop: ObjCBool = false
        for contact in contactsToEnumerate {
            block(contact, &stop)
            if stop { break }
        }
    }

    func opr_executeSaveRequest(saveRequest: TestableContactSaveRequest) throws {
        didExecuteSaveRequest = saveRequest
    }
}

class ContactsTests: OperationTests {

    var container = CNContainer()
    var group = CNMutableGroup()
    var contact = CNMutableContact()
    var store: TestableContactsStore!

    override func setUp() {
        super.setUp()
        store = TestableContactsStore(status: .Authorized)
    }

    func setUpForContactWithIdentifier(contactId: String) -> CNContact {
        store.contactsByIdentifier[contactId] = contact
        return contact
    }

    func createContactsForPredicate(predicate: ContactPredicate) -> [CNContact] {
        switch predicate {
        case .WithIdentifiers(let identifiers):
            return identifiers.map { _ in CNContact() }
        case .MatchingName(let name):
            return (0..<3).map { i in
                let contact = CNMutableContact()
                contact.givenName = "\(name) \(i)"
                return contact
            }
        case .InGroupWithIdentifier(_):
            return (0..<3).map { _ in CNContact() }
        case .InContainerWithID(_):
            return (0..<3).map { _ in CNContact() }
        }
    }

    func setUpForContactsWithPredicate(predicate: ContactPredicate) -> [CNContact] {
        let contacts = createContactsForPredicate(predicate)
        store.contactsMatchingPredicate[predicate] = contacts
        return contacts
    }

    func setUpForGroupsWithName(groupName: String) -> CNGroup {
        group.name = groupName
        store.groupsMatchingPredicate[.InContainerWithID(.Default)] = [group]
        return group
    }

    func setUpForContactEnumerationWithContactIds(contactIds: [String]) {
        store.contactsToEnumerate = contactIds.map { _ in CNMutableContact() }
    }
}

class ContactsOperationTests: ContactsTests {

    var operation: _ContactsOperation<TestableContactsStore>!

    override func setUp() {
        super.setUp()
        operation = _ContactsOperation(contactStore: store)
    }

    func test__container_default_identifier() {
        XCTAssertEqual(ContainerID.Default.identifier, CNContactStore().defaultContainerIdentifier())
    }

    func test__given_access__container_predicate_with_identifiers() {

        let identifiers: [ContainerID] = [ .Default ]
        store.containersMatchingPredicate[.WithIdentifiers(identifiers)] = [container]

        let containers = try! operation.containersWithPredicate(.WithIdentifiers([.Default]))

        XCTAssertTrue(store.didAccessContainersMatchingPredicate)
        XCTAssertEqual(container, containers.first!)
    }

    func test__given_access__container_of_contact_with_identifier() {

        let contactId = "contact_123"
        store.containersMatchingPredicate[.OfContactWithIdentifier(contactId)] = [container]

        let containers = try! operation.containersWithPredicate(.OfContactWithIdentifier(contactId))

        XCTAssertTrue(store.didAccessContainersMatchingPredicate)
        XCTAssertEqual(container, containers.first!)
    }

    func test__given_access__container_of_group_with_identifier() {
        let groupId = "group_123"
        store.containersMatchingPredicate[.OfGroupWithIdentifier(groupId)] = [container]

        let containers = try! operation.containersWithPredicate(.OfGroupWithIdentifier(groupId))

        XCTAssertTrue(store.didAccessContainersMatchingPredicate)
        XCTAssertEqual(container, containers.first!)
    }

    func test__given_access__get_container() {
        store.containersMatchingPredicate[ .WithIdentifiers([.Default]) ] = [container]
        let _container = try! operation.container()
        XCTAssertTrue(_container != nil)
        XCTAssertEqual(_container, container)
    }

    func test__given_access__get_container_with_identifier() {
        store.containersMatchingPredicate[.WithIdentifiers([ .Identifier("container_123") ])] = [container]
        operation = _ContactsOperation(containerId: .Identifier("container_123"), contactStore: store)
        let _container = try! operation.container()
        XCTAssertTrue(_container != nil)
        XCTAssertEqual(_container, container)
    }

    func test__given_access__get_all_groups() {
        store.groupsMatchingPredicate[.WithIdentifiers([ "group_123" ])] = [group]
        let groups = try! operation.allGroups()
        XCTAssertTrue(store.didAccessGroupsMatchingPredicate)
        XCTAssertEqual(group, groups.first!)
    }

    func test__given_access__get_group_named() {
        group.name = "Test Group"
        store.groupsMatchingPredicate[.WithIdentifiers([ "group_123" ])] = [group]
        let groups = try! operation.groupsNamed("Test Group")
        XCTAssertTrue(store.didAccessGroupsMatchingPredicate)
        XCTAssertEqual(group, groups.first!)
    }
}

class GetContactsOperationTest: ContactsTests {

    var operation: _GetContacts<TestableContactsStore>!

    func test__get_contact_sets_operation_name() {
        operation = _GetContacts(identifier: "contact_123", keysToFetch: [])
        XCTAssertEqual(operation.name!, "Get Contacts")
    }

    func test__get_contact_by_identifier_convenience_initializer() {
        let contactId = "contact_123"
        operation = _GetContacts(identifier: contactId, keysToFetch: [])
        XCTAssertEqual(operation.predicate, ContactPredicate.WithIdentifiers([contactId]))
    }

    func test__getting_contact_by_identifier() {
        let contactId = "contact_123"
        let contact = setUpForContactWithIdentifier(contactId)
        operation = _GetContacts(predicate: .WithIdentifiers([contactId]), keysToFetch: [], contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(store.didAccessUnifiedContactWithIdentifier)
        XCTAssertNotNil(operation.contact)
        XCTAssertEqual(contact, operation.contact!)
    }

    func test__getting_contacts_by_name() {
        let predicate: ContactPredicate = .MatchingName("Dan")
        let contacts = setUpForContactsWithPredicate(predicate)
        operation = _GetContacts(predicate: predicate, keysToFetch: [CNContainerNameKey], contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(store.didAccessUnifiedContactsMatchingPredicate)
        XCTAssertTrue(operation.contacts.count > 0)
        XCTAssertEqual(contacts, operation.contacts)
    }
}

class GetContactsGroupOperationTests: ContactsTests {

    let groupName = "test group"
    let containerId = "test container"
    var operation: _GetContactsGroup<TestableContactsStore>!

    func test__get_contacts_group_sets_operation_name() {
        operation = _GetContactsGroup(groupName: groupName, contactStore: store)
        XCTAssertEqual(operation.name!, "Get Contacts Group")
    }

    func test__get_contacts_group_sets_create_if_necessary() {
        operation = _GetContactsGroup(groupName: groupName, contactStore: store)
        XCTAssertTrue(operation.createIfNecessary)
    }

    func test__get_contacts_group_sets_group_name_correctly() {
        operation = _GetContactsGroup(groupName: groupName, contactStore: store)
        XCTAssertEqual(operation.groupName, groupName)
    }

    func test__get_contacts_group_retrieves_group() {
        let group = setUpForGroupsWithName(groupName)
        operation = _GetContactsGroup(groupName: groupName, contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(store.didAccessGroupsMatchingPredicate)
        XCTAssertNil(store.didExecuteSaveRequest)
        XCTAssertEqual(operation.group!, group)
    }

    func test__get_contacts_group_creates_group_if_necessary() {
        operation = _GetContactsGroup(groupName: groupName, containerId: .Identifier(containerId), contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(store.didAccessGroupsMatchingPredicate)

        guard let executedSaveRequest = store.didExecuteSaveRequest else {
            XCTFail("Did not execute a save request.")
            return
        }

        guard let addedGroup = executedSaveRequest.addedGroups[containerId]?.first else {
            XCTFail("Did not add a group to the save request.")
            return
        }

        XCTAssertEqual(addedGroup.name, groupName)
        XCTAssertEqual(operation.group!, addedGroup)
    }
}

class RemoveContactsGroupOperationTests: ContactsTests {

    let groupName = "test group"
    let containerId = "test container"
    var operation: _RemoveContactsGroup<TestableContactsStore>!

    func test__remove_contacts_group_sets_operation_name() {
        operation = _RemoveContactsGroup(groupName: groupName, contactStore: store)
        XCTAssertEqual(operation.name!, "Remove Contacts Group")
    }

    func test__remove_contacts_does_nothing_if_group_does_not_exist() {
        operation = _RemoveContactsGroup(groupName: groupName, contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertNil(store.didExecuteSaveRequest)
    }

    func test__remove_contacts_group_removes_group() {
        let _ = setUpForGroupsWithName(groupName)
        operation = _RemoveContactsGroup(groupName: groupName, contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let executedSaveRequest = store.didExecuteSaveRequest else {
            XCTFail("Did not execute a save request.")
            return
        }

        guard let deletedGroupName = executedSaveRequest.deletedGroupNames.first else {
            XCTFail("Did not get the name of the deleted group.")
            return
        }

        XCTAssertEqual(deletedGroupName, groupName)
    }
}

class AddContactsToGroupOperationTests: ContactsTests {

    let groupName = "test group"
    let contactIds = [ "contact_0", "contact_1", "contact_2" ]
    let containerId = "test container"
    var operation: _AddContactsToGroup<TestableContactsStore>!

    func test__add_contacts_to_group_sets_operation_name() {
        operation = _AddContactsToGroup(groupName: groupName, contactIDs: contactIds, contactStore: store)
        XCTAssertEqual(operation.name!, "Add Contacts to Group: \(groupName)")
    }

    func test__add_contacts_to_group_when_group_exists() {
        let _ = setUpForGroupsWithName(groupName)
        setUpForContactEnumerationWithContactIds(contactIds)
        operation = _AddContactsToGroup(groupName: groupName, contactIDs: contactIds, contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let executedSaveRequest = store.didExecuteSaveRequest else {
            XCTFail("Did not execute a save request.")
            return
        }

        guard let addedMembers = executedSaveRequest.addedMemberToGroup[groupName] else {
            XCTFail("Did not add any members to this group in the save request.")
            return
        }

        XCTAssertEqual(store.contactsToEnumerate, addedMembers)
    }
}

class RemoveContactsFromGroupOperationTests: ContactsTests {
    let groupName = "test group"
    let contactIds = [ "contact_0", "contact_1", "contact_2" ]
    let containerId = "test container"
    var operation: _RemoveContactsFromGroup<TestableContactsStore>!

    func test__remove_contacts_from_group_sets_operation_name() {
        operation = _RemoveContactsFromGroup(groupName: groupName, contactIDs: contactIds, contactStore: store)
        XCTAssertEqual(operation.name!, "Remove Contacts from Group: \(groupName)")
    }

    func test__remove_contacts_from_group() {
        let _ = setUpForGroupsWithName(groupName)
        setUpForContactEnumerationWithContactIds(contactIds)
        operation = _RemoveContactsFromGroup(groupName: groupName, contactIDs: contactIds, contactStore: store)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let executedSaveRequest = store.didExecuteSaveRequest else {
            XCTFail("Did not execute a save request.")
            return
        }

        guard let removedMembers = executedSaveRequest.removedMemberFromGroup[groupName] else {
            XCTFail("Did not add any members to this group in the save request.")
            return
        }

        XCTAssertEqual(store.contactsToEnumerate, removedMembers)
    }
}

class ContactsAccessOperationsTests: OperationTests {

    func test__given_authorization_granted__access_succeeds() {

        let registrar = TestableContactsStore(status: .NotDetermined)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertTrue(registrar.didRequestAccess)
    }

    func test__given_authorization_already_granted__access_succeeds() {

        let registrar = TestableContactsStore(status: .Authorized)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertFalse(registrar.didRequestAccess)
    }

    func test__given_authorization_denied__access_fails() {
        let registrar = TestableContactsStore(status: .NotDetermined, accessRequestShouldSucceed: false)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertTrue(registrar.didRequestAccess)
    }
}
