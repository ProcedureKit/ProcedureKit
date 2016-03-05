//
//  AddressBookTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations
import AddressBook
import AddressBookUI

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
class AddressBookSourceKindTests: XCTestCase {

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

@available(iOS, deprecated=9.0)
class AddressBookPropertyKindTests: XCTestCase {

    var propertyKind: AddressBook.PropertyKind!

    func test__given_invalid_property_kind__then_rawValue_is_correct() {
        propertyKind = .Invalid
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABInvalidPropertyType) as ABPropertyType)
    }

    func test__given_string_property_kind__then_rawValue_is_correct() {
        propertyKind = .String
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABStringPropertyType) as ABPropertyType)
    }

    func test__given_integer_property_kind__then_rawValue_is_correct() {
        propertyKind = .Integer
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABIntegerPropertyType) as ABPropertyType)
    }

    func test__given_real_property_kind__then_rawValue_is_correct() {
        propertyKind = .Real
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABRealPropertyType) as ABPropertyType)
    }

    func test__given_datetime_property_kind__then_rawValue_is_correct() {
        propertyKind = .DateTime
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABDateTimePropertyType) as ABPropertyType)
    }

    func test__given_dictionary_property_kind__then_rawValue_is_correct() {
        propertyKind = .Dictionary
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABDictionaryPropertyType) as ABPropertyType)
    }

    func test__given_multistring_property_kind__then_rawValue_is_correct() {
        propertyKind = .MultiString
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABMultiStringPropertyType) as ABPropertyType)
    }

    func test__given_multiinteger_property_kind__then_rawValue_is_correct() {
        propertyKind = .MultiInteger
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABMultiIntegerPropertyType) as ABPropertyType)
    }

    func test__given_multireal_property_kind__then_rawValue_is_correct() {
        propertyKind = .MultiReal
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABMultiRealPropertyType) as ABPropertyType)
    }

    func test__given_multidatetime_property_kind__then_rawValue_is_correct() {
        propertyKind = .MultiDateTime
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABMultiDateTimePropertyType) as ABPropertyType)
    }

    func test__given_multidictionary_property_kind__then_rawValue_is_correct() {
        propertyKind = .MultiDictionary
        XCTAssertEqual(propertyKind.rawValue, numericCast(kABMultiDictionaryPropertyType) as ABPropertyType)
    }

    func test__given_initialized_invalid__then_is_correct() {
        propertyKind = .Invalid
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABInvalidPropertyType))!)
    }

    func test__given_initialized_string__then_is_correct() {
        propertyKind = .String
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABStringPropertyType))!)
    }

    func test__given_initialized_integer__then_is_correct() {
        propertyKind = .Integer
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABIntegerPropertyType))!)
    }

    func test__given_initialized_real__then_is_correct() {
        propertyKind = .Real
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABRealPropertyType))!)
    }

    func test__given_initialized_datetime__then_is_correct() {
        propertyKind = .DateTime
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABDateTimePropertyType))!)
    }

    func test__given_initialized_dictionary__then_is_correct() {
        propertyKind = .Dictionary
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABDictionaryPropertyType))!)
    }

    func test__given_initialized_multistring__then_is_correct() {
        propertyKind = .MultiString
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABMultiStringPropertyType))!)
    }

    func test__given_initialized_multiinteger__then_is_correct() {
        propertyKind = .MultiInteger
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABMultiIntegerPropertyType))!)
    }

    func test__given_initialized_multireal__then_is_correct() {
        propertyKind = .MultiReal
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABMultiRealPropertyType))!)
    }

    func test__given_initialized_multidatetime__then_is_correct() {
        propertyKind = .MultiDateTime
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABMultiDateTimePropertyType))!)
    }

    func test__given_initialized_multidictionary__then_is_correct() {
        propertyKind = .MultiDictionary
        XCTAssertEqual(propertyKind, AddressBook.PropertyKind(rawValue: numericCast(kABMultiDictionaryPropertyType))!)
    }

    func test__given_initialized_with_other_int__then_result_is_nil() {
        XCTAssertTrue(AddressBook.PropertyKind(rawValue: 666) == nil)
    }

    func test__given_property_kind__then_invalid_is_correct() {
        XCTAssertTrue(AddressBook.PropertyKind.Invalid.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.String.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.Integer.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.Real.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.DateTime.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.Dictionary.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.MultiString.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.MultiInteger.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.MultiReal.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.MultiDateTime.invalid)
        XCTAssertFalse(AddressBook.PropertyKind.MultiDictionary.invalid)
    }

    func test__given_property_kind__then_multivalue_is_correct() {
        XCTAssertFalse(AddressBook.PropertyKind.Invalid.multiValue)
        XCTAssertFalse(AddressBook.PropertyKind.String.multiValue)
        XCTAssertFalse(AddressBook.PropertyKind.Integer.multiValue)
        XCTAssertFalse(AddressBook.PropertyKind.Real.multiValue)
        XCTAssertFalse(AddressBook.PropertyKind.DateTime.multiValue)
        XCTAssertFalse(AddressBook.PropertyKind.Dictionary.multiValue)
        XCTAssertTrue(AddressBook.PropertyKind.MultiString.multiValue)
        XCTAssertTrue(AddressBook.PropertyKind.MultiInteger.multiValue)
        XCTAssertTrue(AddressBook.PropertyKind.MultiReal.multiValue)
        XCTAssertTrue(AddressBook.PropertyKind.MultiDateTime.multiValue)
        XCTAssertTrue(AddressBook.PropertyKind.MultiDictionary.multiValue)
    }

    func test__given_invalid_property_kind__then_description_is_correct() {
        propertyKind = .Invalid
        XCTAssertEqual(propertyKind.description, "Invalid")
    }

    func test__given_string_property_kind__then_description_is_correct() {
        propertyKind = .String
        XCTAssertEqual(propertyKind.description, "String")
    }

    func test__given_integer_property_kind__then_description_is_correct() {
        propertyKind = .Integer
        XCTAssertEqual(propertyKind.description, "Integer")
    }

    func test__given_real_property_kind__then_description_is_correct() {
        propertyKind = .Real
        XCTAssertEqual(propertyKind.description, "Real")
    }

    func test__given_datetime_property_kind__then_description_is_correct() {
        propertyKind = .DateTime
        XCTAssertEqual(propertyKind.description, "DateTime")
    }

    func test__given_dictionary_property_kind__then_description_is_correct() {
        propertyKind = .Dictionary
        XCTAssertEqual(propertyKind.description, "Dictionary")
    }

    func test__given_multistring_property_kind__then_description_is_correct() {
        propertyKind = .MultiString
        XCTAssertEqual(propertyKind.description, "MultiString")
    }

    func test__given_multiinteger_property_kind__then_description_is_correct() {
        propertyKind = .MultiInteger
        XCTAssertEqual(propertyKind.description, "MultiInteger")
    }

    func test__given_multireal_property_kind__then_description_is_correct() {
        propertyKind = .MultiReal
        XCTAssertEqual(propertyKind.description, "MultiReal")
    }

    func test__given_multidatetime_property_kind__then_description_is_correct() {
        propertyKind = .MultiDateTime
        XCTAssertEqual(propertyKind.description, "MultiDateTime")
    }

    func test__given_multidictionary_property_kind__then_description_is_correct() {
        propertyKind = .MultiDictionary
        XCTAssertEqual(propertyKind.description, "MultiDictionary")
    }
}

@available(iOS, deprecated=9.0)
class AddressBookStringMultiValueTests: XCTestCase {

    var value = "Testing!"
    var stringMultiValue: AddressBook.StringMultiValue!

    func test__given_initialized_with_nonstring__result_is_nil() {
        stringMultiValue = AddressBook.StringMultiValue(multiValueRepresentation: NSDecimalNumber.one())
        XCTAssertNil(stringMultiValue)
    }

    func test__given_initialized_with_multiValueRepresentation__value_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(stringMultiValue.value, value)
    }

    func test__given_initialized_with_stringLiteral__value_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(stringLiteral: value)
        XCTAssertEqual(stringMultiValue.value, value)
    }

    func test__given_initialized_with_extendedGraphemeClusterLiteral__value_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(extendedGraphemeClusterLiteral: value)
        XCTAssertEqual(stringMultiValue.value, value)
    }

    func test__given_initialized_with_unicodeScalarLiteral__value_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(unicodeScalarLiteral: value)
        XCTAssertEqual(stringMultiValue.value, value)
    }

    func test__multiValueRepresentation__multiValueRepresentation_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(stringMultiValue.multiValueRepresentation as? String, value)
    }

    func test__multiValueRepresentation__description_is_set() {
        stringMultiValue = AddressBook.StringMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(stringMultiValue.description, value)
    }
}

@available(iOS, deprecated=9.0)
class AddressBookDateMultiValueTests: XCTestCase {

    var value = NSDate()
    var dateMultiValue: AddressBook.DateMultiValue!

    func test__given_initialized_with_nondate__result_is_nil() {
        dateMultiValue = AddressBook.DateMultiValue(multiValueRepresentation: NSDecimalNumber.one())
        XCTAssertNil(dateMultiValue)
    }

    func test__given_initialized_with_multiValueRepresentation__value_is_set() {
        dateMultiValue = AddressBook.DateMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(dateMultiValue.value, value)
    }

    func test__multiValueRepresentation__multiValueRepresentation_is_set() {
        dateMultiValue = AddressBook.DateMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(dateMultiValue.multiValueRepresentation as? NSDate, value)
    }

    func test__multiValueRepresentation__description_is_set() {
        dateMultiValue = AddressBook.DateMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(dateMultiValue.description, String(value))
    }

    func test__multiValueRepresentation__debug_description_is_set() {
        dateMultiValue = AddressBook.DateMultiValue(multiValueRepresentation: value)
        XCTAssertEqual(dateMultiValue.debugDescription, String(value))
    }
}

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
class AddressBookReadablePropertyTests: XCTestCase {

    func test__init_with_property() {
        let readable = AddressBookReadableProperty<NSDate>(id: kABPersonCreationDateProperty)
        XCTAssertEqual(readable.id, kABPersonCreationDateProperty)
        XCTAssertNil(readable.reader)
    }

    func test__init_with_property_and_reader() {
        let readable = AddressBookReadableProperty<NSDate>(id: kABPersonCreationDateProperty, reader: { ref in NSDate() })
        XCTAssertEqual(readable.id, kABPersonCreationDateProperty)
        XCTAssertNotNil(readable.reader)
    }
}

@available(iOS, deprecated=9.0)
class AddressBookWritablePropertyTests: XCTestCase {

    func test__init_with_property() {
        let writable = AddressBookWriteableProperty<NSDate>(id: kABPersonModificationDateProperty)
        XCTAssertEqual(writable.id, kABPersonModificationDateProperty)
        XCTAssertNil(writable.reader)
        XCTAssertNil(writable.writer)
    }

    func test__init_with_property_and_reader() {
        let writable = AddressBookWriteableProperty<NSDate>(id: kABPersonModificationDateProperty, reader: { ref in NSDate() })
        XCTAssertEqual(writable.id, kABPersonModificationDateProperty)
        XCTAssertNotNil(writable.reader)
        XCTAssertNil(writable.writer)
    }

    func test__init_with_property_and_reader_and_writer() {
        let writable = AddressBookWriteableProperty<NSDate>(id: kABPersonModificationDateProperty, reader: { ref in NSDate() }, writer: { date in "testing" })
        XCTAssertEqual(writable.id, kABPersonModificationDateProperty)
        XCTAssertNotNil(writable.reader)
        XCTAssertNotNil(writable.writer)
    }
}
