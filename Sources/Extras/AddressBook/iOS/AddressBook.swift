//
//  AddressBook.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable variable_name
// swiftlint:disable force_cast
// swiftlint:disable nesting
// swiftlint:disable cyclomatic_complexity


// MARK: - AddressBook System Wrapper

/*

I looked into https://github.com/a2/Gulliver & https://github.com/SocialbitGmbH/SwiftAddressBook and
created this with inspiration from both.

Wanted to avoid dependencies in Operations, also didn't
like the way Gulliver mixed up SourceType/Kind/RecordType.
Some of the code in SwiftAddressBook wasn't to my liking,
and it lacked the necessary hooks for testability.

*/

// MARK: - Protocols

// MARK: - PropertyType

public protocol PropertyType {
    associatedtype ValueType

    @available(iOS, deprecated:9.0)
    var id: ABPropertyID { get }
}

// MARK: - ReadablePropertyType

public protocol ReadablePropertyType: PropertyType {
    var reader: ((CFTypeRef) -> ValueType)? { get }
}

// MARK: - WriteablePropertyType

public protocol WriteablePropertyType: PropertyType {
    var writer: ((ValueType) -> CFTypeRef)? { get }
}

// MARK: - MultiValueRepresentable

public protocol MultiValueRepresentable {
    static var propertyKind: AddressBook.PropertyKind { get }
    var multiValueRepresentation: CFTypeRef { get }
    init?(multiValueRepresentation: CFTypeRef)
}

// MARK: - AddressBookPermissionRegistrar

public protocol AddressBookPermissionRegistrar {

    @available(iOS, deprecated:9.0)
    var status: ABAuthorizationStatus { get }

    @available(iOS, deprecated:9.0)
    func createAddressBook() -> (ABAddressBook?, AddressBookPermissionRegistrarError?)

    @available(iOS, deprecated:9.0)
    func requestAccessToAddressBook(_ addressBook: ABAddressBook, completion: (AddressBookPermissionRegistrarError?) -> Void)
}

// MARK: - AddressBookExternalChangeObserver

public protocol AddressBookExternalChangeObserver { }

// MARK: - AddressBookType

public protocol AddressBookType {

    associatedtype RecordStorage
    associatedtype PersonStorage
    associatedtype GroupStorage
    associatedtype SourceStorage

    func requestAccess(_ completion: (AddressBookPermissionRegistrarError?) -> Void)

    func save() -> ErrorProtocol?

    // Records

    func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(_ record: R) -> ErrorProtocol?

    func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(_ record: R) -> ErrorProtocol?

    // People

    var numberOfPeople: Int { get }

    @available(iOS, deprecated:9.0)
    func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ id: ABRecordID) -> P?

    func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ name: String) -> [P]

    func people<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(_ source: S) -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(_ source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P]

    // Groups

    var numberOfGroups: Int { get }

    @available(iOS, deprecated:9.0)
    func groupWithID<G: AddressBook_GroupType where G.Storage == GroupStorage>(_ id: ABRecordID) -> G?

    func groups<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> [G]

    func groupsInSource<G: AddressBook_GroupType, S: AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(_ source: S) -> [G]

    // Sources

    func defaultSource<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> S

    @available(iOS, deprecated:9.0)
    func sourceWithID<S: AddressBook_SourceType where S.Storage == SourceStorage>(_ id: ABRecordID) -> S?

    func sources<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> [S]
}

// MARK: - StorageType

public protocol StorageType {
    associatedtype Storage

    var storage: Storage { get }

    init(storage: Storage)
}

// MARK: - AddressBookRecordType

public protocol AddressBookRecordType: StorageType {

    @available(iOS, deprecated:9.0)
    var id: ABRecordID { get }

    var recordKind: AddressBook.RecordKind { get }

    var compositeName: String { get }

    func value<P: ReadablePropertyType>(forProperty property: P) -> P.ValueType?

    func setValue<P: WriteablePropertyType>(_ value: P.ValueType?, forProperty property: P) -> ErrorProtocol?
}

// MARK: - AddressBook_PersonType

public protocol AddressBook_PersonType: AddressBookRecordType {
    associatedtype GroupStorage
    associatedtype SourceStorage
}

// MARK: - AddressBookPersonType

public protocol AddressBookPersonType: AddressBook_PersonType {

    var compositeNameFormat: AddressBook.CompositeNameFormat { get }
}

// MARK: - AddressBook_GroupType

public protocol AddressBook_GroupType: AddressBookRecordType {
    associatedtype PersonStorage
    associatedtype SourceStorage
}

// MARK: - AddressBookGroupType

public protocol AddressBookGroupType: AddressBook_GroupType {

    func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ ordering: AddressBook.SortOrdering?) -> [P]

    func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ member: P) -> ErrorProtocol?

    func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ member: P) -> ErrorProtocol?
}

// MARK: - AddressBook_SourceType

public protocol AddressBook_SourceType: AddressBookRecordType {
    associatedtype PersonStorage
    associatedtype GroupStorage
}

// MARK: - AddressBookSourceType

public protocol AddressBookSourceType: AddressBook_SourceType {

    var sourceKind: AddressBook.SourceKind { get }

    func newPerson<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> P

    func newGroup<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> G
}


// MARK: - Types

@available(iOS, deprecated:9.0)
public final class AddressBook: AddressBookType {

// MARK: - SortOrdering

    public enum SortOrdering: RawRepresentable, CustomStringConvertible {

        public static var current: SortOrdering {
            return SortOrdering(rawValue: ABPersonGetSortOrdering()) ?? .byLastName
        }

        case byLastName, byFirstName

        public var rawValue: ABPersonSortOrdering {
            switch self {
            case .byLastName:
                return numericCast(kABPersonSortByLastName)
            case .byFirstName:
                return numericCast(kABPersonSortByFirstName)
            }
        }

        public var description: String {
            switch self {
            case .byFirstName:
                return "ByFirstName"
            case .byLastName:
                return "ByLastName"
            }
        }

        public init?(rawValue: ABPersonSortOrdering) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABPersonSortByFirstName:
                self = .byFirstName
            case kABPersonSortByLastName:
                self = .byLastName
            default:
                return nil
            }
        }
    }

// MARK: - CompositeNameFormat

    public enum CompositeNameFormat: RawRepresentable, CustomStringConvertible {

        case firstNameFirst, lastNameFirst

        public var rawValue: ABPersonCompositeNameFormat {
            switch self {
            case .firstNameFirst:
                return numericCast(kABPersonCompositeNameFormatFirstNameFirst)
            case .lastNameFirst:
                return numericCast(kABPersonCompositeNameFormatLastNameFirst)
            }
        }

        public var description: String {
            switch self {
            case .firstNameFirst: return "FirstNameFirst"
            case .lastNameFirst: return "LastNameFirst"
            }
        }

        public init?(rawValue: ABPersonCompositeNameFormat) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABPersonCompositeNameFormatFirstNameFirst:
                self = .firstNameFirst
            case kABPersonCompositeNameFormatLastNameFirst:
                self = .lastNameFirst
            default:
                return nil
            }
        }
    }

// MARK: - RecordKind

    public enum RecordKind: RawRepresentable, CustomStringConvertible {

        case source, group, person

        public var rawValue: ABRecordType {
            switch self {
            case .source:
                return numericCast(kABSourceType)
            case .group:
                return numericCast(kABGroupType)
            case .person:
                return numericCast(kABPersonType)
            }
        }

        public var description: String {
            switch self {
            case .source:
                return "Source"
            case .group:
                return "Group"
            case .person:
                return "Person"
            }
        }

        public init?(rawValue: ABRecordType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABSourceType:
                self = .source
            case kABGroupType:
                self = .group
            case kABPersonType:
                self = .person
            default:
                return nil
            }
        }
    }

// MARK: - SourceKind

    public enum SourceKind: RawRepresentable, CustomStringConvertible {

        case local, exchange, exchangeGAL, mobileMe, ldap, cardDAV, cardDAVSearch

        public var rawValue: ABSourceType {
            switch self {
            case .local:
                return numericCast(kABSourceTypeLocal)
            case .exchange:
                return numericCast(kABSourceTypeExchange)
            case .exchangeGAL:
                return numericCast(kABSourceTypeExchangeGAL)
            case .mobileMe:
                return numericCast(kABSourceTypeMobileMe)
            case .ldap:
                return numericCast(kABSourceTypeLDAP)
            case .cardDAV:
                return numericCast(kABSourceTypeCardDAV)
            case .cardDAVSearch:
                return numericCast(kABSourceTypeCardDAVSearch)
            }
        }

        public var description: String {
            switch self {
            case .local:
                return "Local"
            case .exchange:
                return "Exchange"
            case .exchangeGAL:
                return "ExchangeGAL"
            case .mobileMe:
                return "MobileMe"
            case .ldap:
                return "LDAP"
            case .cardDAV:
                return "CardDAV"
            case .cardDAVSearch:
                return "CardDAVSearch"
            }
        }

        public init?(rawValue: ABSourceType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABSourceTypeLocal:
                self = .local
            case kABSourceTypeExchange:
                self = .exchange
            case kABSourceTypeExchangeGAL:
                self = .exchangeGAL
            case kABSourceTypeMobileMe:
                self = .mobileMe
            case kABSourceTypeLDAP:
                self = .ldap
            case kABSourceTypeCardDAV:
                self = .cardDAV
            case kABSourceTypeCardDAVSearch:
                self = .cardDAVSearch
            default:
                return nil
            }
        }
    }

// MARK: - PropertyKind

    public enum PropertyKind: RawRepresentable, CustomStringConvertible {

        case Invalid, string, integer, real, dateTime, dictionary, multiString, multiInteger, multiReal, multiDateTime, multiDictionary

        public var rawValue: ABPropertyType {
            switch self {
            case .Invalid:
                return numericCast(kABInvalidPropertyType)
            case .string:
                return numericCast(kABStringPropertyType)
            case .integer:
                return numericCast(kABIntegerPropertyType)
            case .real:
                return numericCast(kABRealPropertyType)
            case .dateTime:
                return numericCast(kABDateTimePropertyType)
            case .dictionary:
                return numericCast(kABDictionaryPropertyType)
            case .multiString:
                return numericCast(kABMultiStringPropertyType)
            case .multiInteger:
                return numericCast(kABMultiIntegerPropertyType)
            case .multiReal:
                return numericCast(kABMultiRealPropertyType)
            case .multiDateTime:
                return numericCast(kABMultiDateTimePropertyType)
            case .multiDictionary:
                return numericCast(kABMultiDictionaryPropertyType)
            }
        }

        public var invalid: Bool {
            return self == .Invalid
        }

        public var multiValue: Bool {
            switch self {
            case .multiString, .multiInteger, .multiReal, .multiDateTime, .multiDictionary:
                return true
            default:
                return false
            }
        }

        public var description: Swift.String {
            switch self {
            case .Invalid:
                return "Invalid"
            case .string:
                return "String"
            case .integer:
                return "Integer"
            case .real:
                return "Real"
            case .dateTime:
                return "DateTime"
            case .dictionary:
                return "Dictionary"
            case .multiString:
                return "MultiString"
            case .multiInteger:
                return "MultiInteger"
            case .multiReal:
                return "MultiReal"
            case .multiDateTime:
                return "MultiDateTime"
            case .multiDictionary:
                return "MultiDictionary"
            }
        }

        public init?(rawValue: ABPropertyType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABInvalidPropertyType:
                self = .Invalid
            case kABStringPropertyType:
                self = .string
            case kABIntegerPropertyType:
                self = .integer
            case kABRealPropertyType:
                self = .real
            case kABDateTimePropertyType:
                self = .dateTime
            case kABDictionaryPropertyType:
                self = .dictionary
            case kABMultiStringPropertyType:
                self = .multiString
            case kABMultiIntegerPropertyType:
                self = .multiInteger
            case kABMultiRealPropertyType:
                self = .multiReal
            case kABMultiDateTimePropertyType:
                self = .multiDateTime
            case kABMultiDictionaryPropertyType:
                self = .multiDictionary
            default:
                return nil
            }
        }

    }

// MARK: - ImageFormat

    public typealias ImageFormat = ABPersonImageFormat

// MARK: - StringMultiValue

    public struct StringMultiValue: MultiValueRepresentable, Equatable, CustomStringConvertible, StringLiteralConvertible {

        public static let propertyKind = AddressBook.PropertyKind.string

        public var value: String

        public var multiValueRepresentation: CFTypeRef {
            return value
        }

        public var description: String {
            return value
        }

        public init?(multiValueRepresentation: CFTypeRef) {
            if let value = multiValueRepresentation as? String {
                self.value = value
            }
            else {
                return nil
            }
        }

        public init(stringLiteral value: String) {
            self.value = value
        }

        public  init(extendedGraphemeClusterLiteral value: String) {
            self.value = value
        }

        public  init(unicodeScalarLiteral value: String) {
            self.value = value
        }
    }

// MARK: - DateMultiValue

    public struct DateMultiValue: MultiValueRepresentable, Comparable, CustomStringConvertible, CustomDebugStringConvertible {

        public static let propertyKind = AddressBook.PropertyKind.dateTime

        public var value: Date

        public var multiValueRepresentation: CFTypeRef {
            return value
        }

        public var description: String {
            return String(value)
        }

        public var debugDescription: String {
            return String(reflecting: value)
        }

        public init?(multiValueRepresentation: CFTypeRef) {
            if let value = multiValueRepresentation as? Date {
                self.value = value
            }
            else {
                return nil
            }
        }
    }

// MARK: - Labels

    public struct Labels {
        public struct Date {
            public static let anniversary = kABPersonAnniversaryLabel as String
        }
        public struct General {
            public static let home      = kABHomeLabel as String
            public static let work      = kABWorkLabel as String
            public static let other     = kABOtherLabel as String
        }
        public struct Telephone {
            public static let mobile    = kABPersonPhoneMobileLabel as String
            public static let iPhone    = kABPersonPhoneIPhoneLabel as String
            public static let main      = kABPersonPhoneMainLabel as String
            public static let homeFAX   = kABPersonPhoneHomeFAXLabel as String
            public static let workFAX   = kABPersonPhoneWorkFAXLabel as String
            public static let otherFAX  = kABPersonPhoneOtherFAXLabel as String
            public static let pager     = kABPersonPhonePagerLabel as String
        }
        public struct Relations {
            public static let mother    = kABPersonMotherLabel as String
            public static let father    = kABPersonFatherLabel as String
            public static let parent    = kABPersonParentLabel as String
            public static let brother   = kABPersonBrotherLabel as String
            public static let sister    = kABPersonSisterLabel as String
            public static let child     = kABPersonChildLabel as String
            public static let friend    = kABPersonFriendLabel as String
            public static let spouse    = kABPersonSpouseLabel as String
            public static let partner   = kABPersonPartnerLabel as String
            public static let assistant = kABPersonAssistantLabel as String
            public static let manager   = kABPersonManagerLabel as String
        }
        public struct URLs {
            public static let homePage  = kABPersonHomePageLabel as String
        }
    }

// MARK: - Main Type

    public typealias RecordStorage = ABRecord
    public typealias PersonStorage = ABRecord
    public typealias GroupStorage = ABRecord
    public typealias SourceStorage = ABRecord

    public enum Error: ErrorProtocol {

        case save(NSError?)
        case addRecord(NSError?)
        case removeRecord(NSError?)
        case setValue((id: ABPropertyID, underlyingError: NSError?))
        case removeValue((id: ABPropertyID, underlyingError: NSError?))
        case addGroupMember(NSError?)
        case removeGroupMember(NSError?)

        case underlyingError(NSError)
        case unknownError

        init(error: Unmanaged<CFError>?) {
            self = NSError.from(error).map { .underlyingError($0) } ?? .unknownError
        }
    }

    private let registrar: AddressBookPermissionRegistrar

    public let addressBook: ABAddressBook!

    public init?(registrar: AddressBookPermissionRegistrar = SystemAddressBookRegistrar()) {
        self.registrar = registrar
        let (addressBook, _) = registrar.createAddressBook()
        if let addressBook = addressBook {
            self.addressBook = addressBook
        }
        else {
            self.addressBook = nil
            return nil
        }
    }

}

@available(iOS, deprecated:9.0)
extension AddressBook {

    public func requestAccess(_ completion: (AddressBookPermissionRegistrarError?) -> Void) {
        registrar.requestAccessToAddressBook(addressBook, completion: completion)
    }

    public func save() -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if ABAddressBookSave(addressBook, &error) {
            return .none
        }
        return Error.save(NSError.from(error))
    }
}

@available(iOS, deprecated:9.0)
extension AddressBook { // Records

    public func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(_ record: R) -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if ABAddressBookAddRecord(addressBook, record.storage, &error) {
            return .none
        }
        return Error.addRecord(NSError.from(error))
    }

    public func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(_ record: R) -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if ABAddressBookRemoveRecord(addressBook, record.storage, &error) {
            return .none
        }
        return Error.removeRecord(NSError.from(error))
    }
}

@available(iOS, deprecated:9.0)
extension AddressBook { // People

    public var numberOfPeople: Int {
        return ABAddressBookGetPersonCount(addressBook)
    }

    public func createPerson<P: AddressBook_PersonType, S: AddressBookSourceType where P.Storage == PersonStorage, S.Storage == SourceStorage, P.Storage == S.PersonStorage>(_ source: S? = .none) -> P {
        if let source = source {
            return source.newPerson()
        }
        return P(storage: ABPersonCreate().takeUnretainedValue())
    }

    public func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ id: ABRecordID) -> P? {
        if let record = ABAddressBookGetPersonWithRecordID(addressBook, id) {
            return P(storage: record.takeUnretainedValue())
        }
        return .none
    }

    public func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ name: String) -> [P] {
        if let people = ABAddressBookCopyPeopleWithName(addressBook, name) {
            let values = people.takeRetainedValue() as [ABRecord]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func people<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeople(addressBook) {
            let values = people.takeRetainedValue() as [ABRecord]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(_ source: S) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, source.storage) {
            let values = people.takeRetainedValue() as [ABRecord]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(_ source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source.storage, sortOrdering.rawValue) {
            let values = people.takeRetainedValue() as [ABRecord]
            return values.map { P(storage: $0) }
        }
        return []
    }
}

@available(iOS, deprecated:9.0)
extension AddressBook { // Groups

    public var numberOfGroups: Int {
        return ABAddressBookGetGroupCount(addressBook)
    }

    public func groupWithID<G: AddressBook_GroupType where G.Storage == GroupStorage>(_ id: ABRecordID) -> G? {
        if let record = ABAddressBookGetGroupWithRecordID(addressBook, id) {
            return G(storage: record.takeUnretainedValue())
        }
        return .none
    }

    public func groups<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> [G] {
        if let records = ABAddressBookCopyArrayOfAllGroups(addressBook) {
            let values = records.takeRetainedValue() as [ABRecord]
            return values.map { G(storage: $0) }
        }
        return []
    }

    public func groupsInSource<G: AddressBook_GroupType, S: AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(_ source: S) -> [G] {
        if let records = ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.storage) {
            let values = records.takeRetainedValue() as [ABRecord]
            return values.map { G(storage: $0) }
        }
        return []
    }
}

@available(iOS, deprecated:9.0)
extension AddressBook { // Sources

    public func defaultSource<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> S {
        let source: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        return S(storage: source)
    }

    public func sourceWithID<S: AddressBook_SourceType where S.Storage == SourceStorage>(_ id: ABRecordID) -> S? {
        if let record = ABAddressBookGetSourceWithRecordID(addressBook, id) {
            return S(storage: record.takeUnretainedValue())
        }
        return .none
    }

    public func sources<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> [S] {
        if let sources = ABAddressBookCopyArrayOfAllSources(addressBook) {
            let values = sources.takeRetainedValue() as [ABRecord]
            return values.map { S(storage: $0) }
        }
        return []
    }
}

// MARK: - Property

@available(iOS, deprecated:9.0)
public struct AddressBookReadableProperty<Value>: ReadablePropertyType {
    public typealias ValueType = Value

    public let id: ABPropertyID
    public let reader: ((CFTypeRef) -> ValueType)?

    public init(id: ABPropertyID, reader: ((CFTypeRef) -> ValueType)? = .none) {
        self.id = id
        self.reader = reader
    }
}

@available(iOS, deprecated:9.0)
public struct AddressBookWriteableProperty<Value>: ReadablePropertyType, WriteablePropertyType {
    public typealias ValueType = Value

    public let id: ABPropertyID
    public let reader: ((CFTypeRef) -> ValueType)?
    public let writer: ((ValueType) -> CFTypeRef)?

    public init(id: ABPropertyID, reader: ((CFTypeRef) -> ValueType)? = .none, writer: ((ValueType) -> CFTypeRef)? = .none) {
        self.id = id
        self.reader = reader
        self.writer = writer
    }
}

// MARK: - LabeledValue

@available(iOS, deprecated:9.0)
public struct LabeledValue<Value: MultiValueRepresentable>: CustomStringConvertible, CustomDebugStringConvertible {

    static func read(_ multiValue: ABMultiValue) -> [LabeledValue<Value>] {
        assert(AddressBook.PropertyKind(rawValue: ABMultiValueGetPropertyType(multiValue)) == Value.propertyKind, "ABMultiValueRef has incompatible property kind.")
        let count: Int = ABMultiValueGetCount(multiValue)
        return (0..<count).reduce([LabeledValue<Value>]()) { (acc, index) in
            var acc = acc
            let representation: CFTypeRef = ABMultiValueCopyValueAtIndex(multiValue, index).takeRetainedValue()
            if let value = Value(multiValueRepresentation: representation), unmanagedLabel = ABMultiValueCopyLabelAtIndex(multiValue, index) {
                let label = unmanagedLabel.takeRetainedValue() as String
                let labeledValue = LabeledValue(label: label, value: value)
                acc.append(labeledValue)
            }
            return acc
        }
    }

    static func write(_ labeledValues: [LabeledValue<Value>]) -> ABMultiValue {
        return labeledValues.reduce(ABMultiValueCreateMutable(Value.propertyKind.rawValue).takeRetainedValue() as ABMutableMultiValue) { (multiValue, labeledValue) in
            ABMultiValueAddValueAndLabel(multiValue, labeledValue.value.multiValueRepresentation, labeledValue.label, nil)
            return multiValue
        }
    }

    public let label: String
    public let value: Value

    public var description: String {
        return "\(label): \(String(value))"
    }

    public var debugDescription: String {
        return "\(label): \(String(reflecting: value))"
    }

    public init(label: String, value: Value) {
        self.label = label
        self.value = value
    }
}

// MARK: - Record

@available(iOS, deprecated:9.0)
public class AddressBookRecord: AddressBookRecordType, Equatable {

    public let storage: ABRecord

    public var id: ABRecordID {
        return ABRecordGetRecordID(storage)
    }

    public var recordKind: AddressBook.RecordKind {
        return AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage))!
    }

    public var compositeName: String {
        assert(recordKind != .source, "compositeName is not defined for Source records")
        return ABRecordCopyCompositeName(storage).takeRetainedValue() as String
    }

    public required init(storage: ABRecord) {
        self.storage = storage
    }

    public func value<P: ReadablePropertyType>(forProperty property: P) -> P.ValueType? {
        if let unmanaged = ABRecordCopyValue(storage, property.id) {
            let value: CFTypeRef = unmanaged.takeRetainedValue()
            return property.reader?(value) ?? value as! P.ValueType
        }
        return .none
    }

    public func setValue<P: WriteablePropertyType>(_ value: P.ValueType?, forProperty property: P) -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if let value = value {
            let transformed: CFTypeRef = property.writer?(value) ?? value as! CFTypeRef
            if ABRecordSetValue(storage, property.id, transformed, &error) {
                return .none
            }
            return AddressBook.Error.setValue(id: property.id, underlyingError: NSError.from(error))
        }
        else {
            if ABRecordRemoveValue(storage, property.id, &error) {
                return .none
            }
            return AddressBook.Error.removeValue(id: property.id, underlyingError: NSError.from(error))
        }
    }
}

@available(iOS, deprecated:9.0)
public func == (lhs: AddressBookRecord, rhs: AddressBookRecord) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Person

@available(iOS, deprecated:9.0)
public class AddressBookPerson: AddressBookRecord, AddressBookPersonType {

    public struct Property {

        public struct Metadata {
            public static let creationDate      = AddressBookReadableProperty<Date>(id: kABPersonCreationDateProperty)
            public static let modificationDate  = AddressBookWriteableProperty<Date>(id: kABPersonModificationDateProperty)
        }

        public struct Name {
            public static let prefix        = AddressBookWriteableProperty<String>(id: kABPersonPrefixProperty)
            public static let first         = AddressBookWriteableProperty<String>(id: kABPersonFirstNameProperty)
            public static let middle        = AddressBookWriteableProperty<String>(id: kABPersonMiddleNameProperty)
            public static let last          = AddressBookWriteableProperty<String>(id: kABPersonLastNameProperty)
            public static let suffix        = AddressBookWriteableProperty<String>(id: kABPersonSuffixProperty)
            public static let nickname      = AddressBookWriteableProperty<String>(id: kABPersonNicknameProperty)
        }

        public struct Phonetic {
            public static let first         = AddressBookWriteableProperty<String>(id: kABPersonFirstNamePhoneticProperty)
            public static let middle        = AddressBookWriteableProperty<String>(id: kABPersonMiddleNamePhoneticProperty)
            public static let last          = AddressBookWriteableProperty<String>(id: kABPersonLastNamePhoneticProperty)
        }

        public struct Work {
            public static let organization  = AddressBookWriteableProperty<String>(id: kABPersonOrganizationProperty)
            public static let deptartment   = AddressBookWriteableProperty<String>(id: kABPersonDepartmentProperty)
            public static let job           = AddressBookWriteableProperty<String>(id: kABPersonJobTitleProperty)
        }

        public static let emails            = AddressBookWriteableProperty<[LabeledValue<AddressBook.StringMultiValue>]>(id: kABPersonEmailProperty, reader: reader, writer: writer)
        public static let telephones        = AddressBookWriteableProperty<[LabeledValue<AddressBook.StringMultiValue>]>(id: kABPersonPhoneProperty, reader: reader, writer: writer)
        public static let notes             = AddressBookWriteableProperty<String>(id: kABPersonNoteProperty)
    }

    public typealias GroupStorage = ABRecord
    public typealias SourceStorage = ABRecord

    public var compositeNameFormat: AddressBook.CompositeNameFormat {
        return AddressBook.CompositeNameFormat(rawValue: ABPersonGetCompositeNameFormatForRecord(storage))!
    }

    public required init(storage: ABRecord) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .person, "ABRecordRef \(storage) is not a Person.")
        super.init(storage: storage)
    }
}

// MARK: - Group

@available(iOS, deprecated:9.0)
public class AddressBookGroup: AddressBookRecord, AddressBookGroupType {

    public struct Property {
        public static let name = AddressBookWriteableProperty<String>(id: kABGroupNameProperty)
    }

    public typealias PersonStorage = ABRecord
    public typealias SourceStorage = ABRecord

    public convenience init() {
        let storage: ABRecord = ABGroupCreate().takeRetainedValue()
        self.init(storage: storage)
    }

    public required init(storage: ABRecord) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .group, "ABRecordRef \(storage) is not a Group.")
        super.init(storage: storage)
    }

    public func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ ordering: AddressBook.SortOrdering? = .none) -> [P] {
        let result: [ABRecord] = {
            if let ordering = ordering, unmanaged = ABGroupCopyArrayOfAllMembersWithSortOrdering(self.storage, ordering.rawValue) {
                return unmanaged.takeRetainedValue() as [ABRecord]
            }
            else if let unmanaged = ABGroupCopyArrayOfAllMembers(self.storage) {
                return unmanaged.takeRetainedValue() as [ABRecord]
            }
            return []
        }()

        return result.map { P(storage: $0) }
    }

    public func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ member: P) -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if ABGroupAddMember(storage, member.storage, &error) {
            return .none
        }
        return AddressBook.Error.addGroupMember(NSError.from(error))
    }

    public func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ member: P) -> ErrorProtocol? {
        var error: Unmanaged<CFError>? = .none
        if ABGroupRemoveMember(storage, member.storage, &error) {
            return .none
        }
        return AddressBook.Error.removeGroupMember(NSError.from(error))
    }
}

// MARK: - Source

@available(iOS, deprecated:9.0)
public class AddressBookSource: AddressBookRecord, AddressBookSourceType {

    public struct Property {
        public static let kind = AddressBookReadableProperty<AddressBook.SourceKind>(id: kABSourceTypeProperty, reader: reader)
    }

    public typealias PersonStorage = ABRecord
    public typealias GroupStorage = ABRecord

    public var sourceKind: AddressBook.SourceKind {
        return value(forProperty: AddressBookSource.Property.kind)!
    }

    public required init(storage: ABRecord) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .source, "ABRecordRef \(storage) is not a Source.")
        super.init(storage: storage)
    }

    public func newPerson<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> P {
        let person: ABRecord = ABPersonCreateInSource(storage).takeRetainedValue()
        return P(storage: person)
    }

    public func newGroup<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> G {
        let group: ABRecord = ABGroupCreateInSource(storage).takeRetainedValue()
        return G(storage: group)
    }
}




// MARK: - Equatable

extension CFNumber: Equatable {}

public func == (lhs: CFNumber, rhs: CFNumber) -> Bool {
    return CFNumberCompare(lhs, rhs, nil) == .compareEqualTo
}

public func == (lhs: AddressBook.StringMultiValue, rhs: AddressBook.StringMultiValue) -> Bool {
    return lhs.value == rhs.value
}

public func == (lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value == rhs.value
}

public func < (lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value.compare(rhs.value) == .orderedAscending
}

// MARK: - Helpers

func reader<T: RawRepresentable>(_ value: CFTypeRef) -> T {
    return T(rawValue: value as! T.RawValue)!
}

func writer<T: RawRepresentable>(_ value: T) -> CFTypeRef {
    return value.rawValue as! CFTypeRef
}

@available(iOS, deprecated:9.0)
func reader<T: MultiValueRepresentable>(_ value: CFTypeRef) -> [LabeledValue<T>] {
    return LabeledValue.read(value as ABMultiValue)
}

@available(iOS, deprecated:9.0)
func writer<T: MultiValueRepresentable>(_ value: [LabeledValue<T>]) -> CFTypeRef {
    return LabeledValue.write(value)
}

extension NSError {

    static func from(_ ref: Unmanaged<CFError>?) -> NSError? {
        return ref.map { unsafeBitCast($0.takeRetainedValue(), to: NSError.self) }
    }
}








public enum AddressBookPermissionRegistrarError: ErrorProtocol {
    case addressBookUnknownErrorOccured
    case addressBookAccessDenied
}

@available(iOS, deprecated:9.0)
public struct SystemAddressBookRegistrar: AddressBookPermissionRegistrar {

    public var status: ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }

    public func createAddressBook() -> (ABAddressBook?, AddressBookPermissionRegistrarError?) {
        var addressBookError: Unmanaged<CFError>? = .none
        if let addressBook = ABAddressBookCreateWithOptions(nil, &addressBookError) {
            return (addressBook.takeRetainedValue(), .none)
        }
        else if let error = NSError.from(addressBookError) {
            if (error.domain == ABAddressBookErrorDomain as String) && error.code == kABOperationNotPermittedByUserError {
                return (.none, AddressBookPermissionRegistrarError.addressBookAccessDenied)
            }
        }
        return (.none, AddressBookPermissionRegistrarError.addressBookUnknownErrorOccured)
    }

    public func requestAccessToAddressBook(_ addressBook: ABAddressBook, completion: (AddressBookPermissionRegistrarError?) -> Void) {
        ABAddressBookRequestAccessWithCompletion(addressBook) { (success, error) in
            if success {
                completion(nil)
            }
            else if let _ = error {
                completion(AddressBookPermissionRegistrarError.addressBookAccessDenied)
            }
            else {
                completion(AddressBookPermissionRegistrarError.addressBookUnknownErrorOccured)
            }
        }
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable nesting
// swiftlint:enable force_cast
// swiftlint:enable variable_name
// swiftlint:disable type_body_length
// swiftlint:disable file_length
