//
//  AddressBookTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations
import AddressBook
import AddressBookUI

class AddressBookSortOrderingTests: XCTestCase {

    var ordering: AddressBook.SortOrdering!

    func test__given_by_last_name__then_rawValue_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(ordering.rawValue, numericCast(kABPersonSortByLastName))
    }

    func test__given_by_first_name__then_rawValue_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(ordering.rawValue, numericCast(kABPersonSortByFirstName))
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
        XCTAssertEqual(format.rawValue, numericCast(kABPersonCompositeNameFormatFirstNameFirst))
    }

    func test__given_last_name_first__then_rawValue_is_correct() {
        format = .LastNameFirst
        XCTAssertEqual(format.rawValue, numericCast(kABPersonCompositeNameFormatLastNameFirst))
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

    var recordType: AddressBook.RecordType!

    func test__given_source_type__then_rawValue_is_correct() {
        recordType = .Source
        XCTAssertEqual(recordType.rawValue, numericCast(kABSourceType))
    }

    func test__given_group_type__then_rawValue_is_correct() {
        recordType = .Group
        XCTAssertEqual(recordType.rawValue, numericCast(kABGroupType))
    }

    func test__given_person_type__then_rawValue_is_correct() {
        recordType = .Person
        XCTAssertEqual(recordType.rawValue, numericCast(kABPersonType))
    }

    func test__given_source_type__then_description_is_correct() {
        recordType = .Source
        XCTAssertEqual(recordType.description, "Source")
    }

    func test__given_group_type__then_description_is_correct() {
        recordType = .Group
        XCTAssertEqual(recordType.description, "Group")
    }

    func test__given_person_type__then_description_is_correct() {
        recordType = .Person
        XCTAssertEqual(recordType.description, "Person")
    }

    func test__given_initialized_source__then_is_correct() {
        recordType = .Source
        XCTAssertEqual(recordType, AddressBook.RecordType(rawValue: numericCast(kABSourceType))!)
    }

    func test__given_initialized_group__then_is_correct() {
        recordType = .Group
        XCTAssertEqual(recordType, AddressBook.RecordType(rawValue: numericCast(kABGroupType))!)
    }

    func test__given_initialized_person__then_is_correct() {
        recordType = .Person
        XCTAssertEqual(recordType, AddressBook.RecordType(rawValue: numericCast(kABPersonType))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.RecordType(rawValue: 666) == nil)
    }
}

class AddressBookSourceTypeTests: XCTestCase {

    var sourceType: AddressBook.SourceType!

    func test__given_local_source__then_rawValue_is_correct() {
        sourceType = .Local
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeLocal))
    }

    func test__given_exchange_source__then_rawValue_is_correct() {
        sourceType = .Exchange
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeExchange))
    }

    func test__given_exchangegal_source__then_rawValue_is_correct() {
        sourceType = .ExchangeGAL
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeExchangeGAL))
    }

    func test__given_mobileme_source__then_rawValue_is_correct() {
        sourceType = .MobileMe
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeMobileMe))
    }

    func test__given_ldap_source__then_rawValue_is_correct() {
        sourceType = .LDAP
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeLDAP))
    }

    func test__given_carddav_source__then_rawValue_is_correct() {
        sourceType = .CardDAV
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeCardDAV))
    }

    func test__given_carddavsearch_source__then_rawValue_is_correct() {
        sourceType = .CardDAVSearch
        XCTAssertEqual(sourceType.rawValue, numericCast(kABSourceTypeCardDAVSearch))
    }

    func test__given_local_source__then_description_is_correct() {
        sourceType = .Local
        XCTAssertEqual(sourceType.description, "Local")
    }

    func test__given_exchange_source__then_description_is_correct() {
        sourceType = .Exchange
        XCTAssertEqual(sourceType.description, "Exchange")
    }

    func test__given_exchangegal_source__then_description_is_correct() {
        sourceType = .ExchangeGAL
        XCTAssertEqual(sourceType.description, "ExchangeGAL")
    }

    func test__given_mobileme_source__then_description_is_correct() {
        sourceType = .MobileMe
        XCTAssertEqual(sourceType.description, "MobileMe")
    }

    func test__given_ldap_source__then_description_is_correct() {
        sourceType = .LDAP
        XCTAssertEqual(sourceType.description, "LDAP")
    }

    func test__given_carddav_source__then_description_is_correct() {
        sourceType = .CardDAV
        XCTAssertEqual(sourceType.description, "CardDAV")
    }

    func test__given_carddavsearch_source__then_description_is_correct() {
        sourceType = .CardDAVSearch
        XCTAssertEqual(sourceType.description, "CardDAVSearch")
    }

    func test__given_initialized_local__then_is_correct() {
        sourceType = .Local
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeLocal))!)
    }

    func test__given_initialized_exchange__then_is_correct() {
        sourceType = .Exchange
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeExchange))!)
    }

    func test__given_initialized_exchangegal__then_is_correct() {
        sourceType = .ExchangeGAL
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeExchangeGAL))!)
    }

    func test__given_initialized_mobileme__then_is_correct() {
        sourceType = .MobileMe
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeMobileMe))!)
    }

    func test__given_initialized_ldap__then_is_correct() {
        sourceType = .LDAP
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeLDAP))!)
    }

    func test__given_initialized_carddav__then_is_correct() {
        sourceType = .CardDAV
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeCardDAV))!)
    }

    func test__given_initialized_carddavsearch__then_is_correct() {
        sourceType = .CardDAVSearch
        XCTAssertEqual(sourceType, AddressBook.SourceType(rawValue: numericCast(kABSourceTypeCardDAVSearch))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.SourceType(rawValue: 666) == nil)
    }
}

class AddressBookImageFormatTests: XCTestCase {

    var format: AddressBook.ImageFormat!

    func test__given_originalsize__then_rawValue_is_correct() {
        format = .OriginalSize
        XCTAssertEqual(format.rawValue, kABPersonImageFormatOriginalSize)
    }

    func test__given_thumbnail__then_rawValue_is_correct() {
        format = .Thumbnail
        XCTAssertEqual(format.rawValue, kABPersonImageFormatThumbnail)
    }

    func test__given_originalsize__then_description_is_correct() {
        format = .OriginalSize
        XCTAssertEqual(format.description, "OriginalSize")
    }

    func test__given_thumbnail__then_description_is_correct() {
        format = .Thumbnail
        XCTAssertEqual(format.description, "Thumbnail")
    }

    func test__given_initialized_originalsize__then_is_correct() {
        format = .OriginalSize
        XCTAssertEqual(format, AddressBook.ImageFormat(rawValue: kABPersonImageFormatOriginalSize)!)
    }

    func test__given_initialized_thumbnail__then_is_correct() {
        format = .Thumbnail
        XCTAssertEqual(format, AddressBook.ImageFormat(rawValue: kABPersonImageFormatThumbnail)!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.ImageFormat(rawValue: ABPersonImageFormat(666)) == nil)
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
        let posedError = NSError(domain: "me.danthorpe.Operations.AddressBook", code: -666, userInfo: nil)
        registrar.accessError = posedError as! CFErrorRef

        addressBook = AddressBook(registrar: registrar)
        addressBook.requestAccess { error in
            if let error = error {
                switch error {
                case .AddressBookAccessFailed(_):
                    break
                default:
                    XCTFail("Incorrect error received")
                }
            }
        }
        XCTAssertTrue(registrar.didRequestAccess)
    }
}












