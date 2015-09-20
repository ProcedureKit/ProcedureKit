//
//  AddressBookTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import XCTest
@testable import Operations
import AddressBook
import AddressBookUI

class AddressBookSortOrderingTests: XCTestCase {

    var ordering: AddressBook.SortOrdering!

    func test__given_by_last_name__then_rawValue_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(ordering.rawValue, numericCast(kABPersonSortByLastName) as UInt32)
    }

    func test__given_by_first_name__then_rawValue_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(ordering.rawValue, numericCast(kABPersonSortByFirstName) as UInt32)
    }

    func test__given_by_first_name__then_description_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(ordering.description, "ByFirstName")
    }

    func test__given_by_last_name__then_description_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(ordering.description, "ByLastName")
    }

    func test__given_initialized_by_last_name__then_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(ordering, AddressBook.SortOrdering(rawValue: numericCast(kABPersonSortByLastName))!)
    }

    func test__given_initialized_by_first_name__then_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(ordering, AddressBook.SortOrdering(rawValue: numericCast(kABPersonSortByFirstName))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.SortOrdering(rawValue: 666) == nil)
    }
}

class AddressBookCompositeNameFormatTests: XCTestCase {

    var format: AddressBook.CompositeNameFormat!

    func test__given_first_name_first__then_rawValue_is_correct() {
        format = .FirstNameFirst
        XCTAssertEqual(format.rawValue, numericCast(kABPersonCompositeNameFormatFirstNameFirst) as UInt32)
    }

    func test__given_last_name_first__then_rawValue_is_correct() {
        format = .LastNameFirst
        XCTAssertEqual(format.rawValue, numericCast(kABPersonCompositeNameFormatLastNameFirst) as UInt32)
    }

    func test__given_first_name_first__then_description_is_correct() {
        format = .FirstNameFirst
        XCTAssertEqual(format.description, "FirstNameFirst")
    }

    func test__given_last_name_first__then_description_is_correct() {
        format = .LastNameFirst
        XCTAssertEqual(format.description, "LastNameFirst")
    }

    func test__given_initialized_first_name_first__then_is_correct() {
        format = .FirstNameFirst
        XCTAssertEqual(format, AddressBook.CompositeNameFormat(rawValue: numericCast(kABPersonCompositeNameFormatFirstNameFirst))!)
    }

    func test__given_initialized_last_name_first__then_is_correct() {
        format = .LastNameFirst
        XCTAssertEqual(format, AddressBook.CompositeNameFormat(rawValue: numericCast(kABPersonCompositeNameFormatLastNameFirst))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.CompositeNameFormat(rawValue: 666) == nil)
    }
}

class AddressBookRecordTypeTests: XCTestCase {

    var recordKind: AddressBook.RecordKind!

    func test__given_source_type__then_rawValue_is_correct() {
        recordKind = .Source
        XCTAssertEqual(recordKind.rawValue, numericCast(kABSourceType) as UInt32)
    }

    func test__given_group_type__then_rawValue_is_correct() {
        recordKind = .Group
        XCTAssertEqual(recordKind.rawValue, numericCast(kABGroupType) as UInt32)
    }

    func test__given_person_type__then_rawValue_is_correct() {
        recordKind = .Person
        XCTAssertEqual(recordKind.rawValue, numericCast(kABPersonType) as UInt32)
    }

    func test__given_source_type__then_description_is_correct() {
        recordKind = .Source
        XCTAssertEqual(recordKind.description, "Source")
    }

    func test__given_group_type__then_description_is_correct() {
        recordKind = .Group
        XCTAssertEqual(recordKind.description, "Group")
    }

    func test__given_person_type__then_description_is_correct() {
        recordKind = .Person
        XCTAssertEqual(recordKind.description, "Person")
    }

    func test__given_initialized_source__then_is_correct() {
        recordKind = .Source
        XCTAssertEqual(recordKind, AddressBook.RecordKind(rawValue: numericCast(kABSourceType))!)
    }

    func test__given_initialized_group__then_is_correct() {
        recordKind = .Group
        XCTAssertEqual(recordKind, AddressBook.RecordKind(rawValue: numericCast(kABGroupType))!)
    }

    func test__given_initialized_person__then_is_correct() {
        recordKind = .Person
        XCTAssertEqual(recordKind, AddressBook.RecordKind(rawValue: numericCast(kABPersonType))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.RecordKind(rawValue: 666) == nil)
    }
}

class AddressBookSourceTypeTests: XCTestCase {

    var sourceKind: AddressBook.SourceKind!

    func test__given_local_source__then_rawValue_is_correct() {
        sourceKind = .Local
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeLocal) as Int32)
    }

    func test__given_exchange_source__then_rawValue_is_correct() {
        sourceKind = .Exchange
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeExchange) as Int32)
    }

    func test__given_exchangegal_source__then_rawValue_is_correct() {
        sourceKind = .ExchangeGAL
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeExchangeGAL) as Int32)
    }

    func test__given_mobileme_source__then_rawValue_is_correct() {
        sourceKind = .MobileMe
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeMobileMe) as Int32)
    }

    func test__given_ldap_source__then_rawValue_is_correct() {
        sourceKind = .LDAP
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeLDAP) as Int32)
    }

    func test__given_carddav_source__then_rawValue_is_correct() {
        sourceKind = .CardDAV
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeCardDAV) as Int32)
    }

    func test__given_carddavsearch_source__then_rawValue_is_correct() {
        sourceKind = .CardDAVSearch
        XCTAssertEqual(sourceKind.rawValue, numericCast(kABSourceTypeCardDAVSearch) as Int32)
    }

    func test__given_local_source__then_description_is_correct() {
        sourceKind = .Local
        XCTAssertEqual(sourceKind.description, "Local")
    }

    func test__given_exchange_source__then_description_is_correct() {
        sourceKind = .Exchange
        XCTAssertEqual(sourceKind.description, "Exchange")
    }

    func test__given_exchangegal_source__then_description_is_correct() {
        sourceKind = .ExchangeGAL
        XCTAssertEqual(sourceKind.description, "ExchangeGAL")
    }

    func test__given_mobileme_source__then_description_is_correct() {
        sourceKind = .MobileMe
        XCTAssertEqual(sourceKind.description, "MobileMe")
    }

    func test__given_ldap_source__then_description_is_correct() {
        sourceKind = .LDAP
        XCTAssertEqual(sourceKind.description, "LDAP")
    }

    func test__given_carddav_source__then_description_is_correct() {
        sourceKind = .CardDAV
        XCTAssertEqual(sourceKind.description, "CardDAV")
    }

    func test__given_carddavsearch_source__then_description_is_correct() {
        sourceKind = .CardDAVSearch
        XCTAssertEqual(sourceKind.description, "CardDAVSearch")
    }

    func test__given_initialized_local__then_is_correct() {
        sourceKind = .Local
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeLocal))!)
    }

    func test__given_initialized_exchange__then_is_correct() {
        sourceKind = .Exchange
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeExchange))!)
    }

    func test__given_initialized_exchangegal__then_is_correct() {
        sourceKind = .ExchangeGAL
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeExchangeGAL))!)
    }

    func test__given_initialized_mobileme__then_is_correct() {
        sourceKind = .MobileMe
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeMobileMe))!)
    }

    func test__given_initialized_ldap__then_is_correct() {
        sourceKind = .LDAP
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeLDAP))!)
    }

    func test__given_initialized_carddav__then_is_correct() {
        sourceKind = .CardDAV
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeCardDAV))!)
    }

    func test__given_initialized_carddavsearch__then_is_correct() {
        sourceKind = .CardDAVSearch
        XCTAssertEqual(sourceKind, AddressBook.SourceKind(rawValue: numericCast(kABSourceTypeCardDAVSearch))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.SourceKind(rawValue: 666) == nil)
    }
}

class AddressBooksTests: XCTestCase {

    var addressBook: AddressBook!
    var registrar: TestableAddressBookRegistrar!

    override func setUp() {
        registrar = TestableAddressBookRegistrar(status: .Authorized)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        registrar.addressBook = posedAddressBook as CFTypeRef
    }

    func test__given_authorization__address_book_access_request_is_received_by_registrar() {

        addressBook = AddressBook(registrar: registrar)
        addressBook.requestAccess { error in
            XCTAssertTrue(error == nil)
        }
        XCTAssertTrue(registrar.didRequestAccess)
    }

    func test__given_denied_authorization__address_book_access_request_returns_error() {

        registrar.requestShouldSucceed = false
        registrar.accessError = CFErrorCreate(nil, "me.danthorpe.Operations.AddressBook", -666, nil)

        addressBook = AddressBook(registrar: registrar)
        addressBook.requestAccess { error in
            if let error = error {
                switch error {
                case .AddressBookAccessDenied:
                    break
                default:
                    XCTFail("Incorrect error received")
                }
            }
        }
        XCTAssertTrue(registrar.didRequestAccess)
    }
}

#endif
