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
    var updatedGroups = [String]()
    var deletedGroups = [String]()

    var addedMemberToGroup = [String: [CNContact]]()
    var removedMemberFromGroup = [String: [CNContact]]()

    required init() { }
    
    func opr_addContact(contact: CNMutableContact, toContainerWithIdentifier identifier: String?) {
        let containerId = identifier ?? "Default"
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
        let containerId = identifier ?? "Default"
        addedGroups[containerId] = addedGroups[containerId] ?? []
        addedGroups[containerId]!.append(group)
    }

    func opr_updateGroup(group: CNMutableGroup) {
        updatedGroups.append(group.identifier)
    }

    func opr_deleteGroup(group: CNMutableGroup) {
        deletedGroups.append(group.identifier)
    }

    func opr_addMember(contact: CNContact, toGroup group: CNGroup) {
        addedMemberToGroup[group.identifier] = addedMemberToGroup[group.identifier] ?? []
        addedMemberToGroup[group.identifier]!.append(contact)
    }

    func opr_removeMember(contact: CNContact, fromGroup group: CNGroup) {
        removedMemberFromGroup[group.identifier] = removedMemberFromGroup[group.identifier] ?? []
        removedMemberFromGroup[group.identifier]!.append(contact)
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

    var didAccessDefaultContainerIdentifier = false
    var didAccessUnifiedContactWithIdentifier = false
    var didAccessUnifiedContactsMatchingPredicate = false
    var didAccessGroupsMatchingPredicate = false
    var didAccessContainersMatchingPredicate = false
    var didAccessEnumerateContactsWithFetchRequest = false

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
        throw Error.NotImplemented
    }

    func opr_unifiedContactsMatchingPredicate(predicate: ContactPredicate, keysToFetch keys: [CNKeyDescriptor]) throws -> [CNContact] {
        didAccessUnifiedContactsMatchingPredicate = true
        throw Error.NotImplemented
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
        didAccessEnumerateContactsWithFetchRequest = true
        throw Error.NotImplemented
    }

    func opr_executeSaveRequest(saveRequest: TestableContactSaveRequest) throws {
        didExecuteSaveRequest = saveRequest
    }
}

class ContactsTests: XCTestCase {
    
    func test__container_default_identifier() {
        XCTAssertEqual(ContainerID.Default.identifier, CNContactStore().defaultContainerIdentifier())
    }
}

class ContactsOperationTests: OperationTests {

    var container = CNContainer()
    var group = CNMutableGroup()
    var store: TestableContactsStore!
    var operation: _ContactsOperation<TestableContactsStore>!

    override func setUp() {
        super.setUp()
        store = TestableContactsStore(status: .Authorized)
        operation = _ContactsOperation(contactStore: store)
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

class ContactsAccessOperationsTests: OperationTests {

    func test__given_authorization_granted__access_succeeds() {

        let registrar = TestableContactsStore(status: .NotDetermined)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertTrue(registrar.didRequestAccess)
    }
}
