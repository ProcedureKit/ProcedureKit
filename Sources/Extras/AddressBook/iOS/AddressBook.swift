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

    @available(iOS, deprecated=9.0)
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

    @available(iOS, deprecated=9.0)
    var status: ABAuthorizationStatus { get }

    @available(iOS, deprecated=9.0)
    func createAddressBook() -> (ABAddressBookRef?, AddressBookPermissionRegistrarError?)

    @available(iOS, deprecated=9.0)
    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: (AddressBookPermissionRegistrarError?) -> Void)
}

// MARK: - AddressBookExternalChangeObserver

public protocol AddressBookExternalChangeObserver { }

// MARK: - AddressBookType

public protocol AddressBookType {

    associatedtype RecordStorage
    associatedtype PersonStorage
    associatedtype GroupStorage
    associatedtype SourceStorage

    func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void)

    func save() -> ErrorType?

    // Records

    func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType?

    func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType?

    // People

    var numberOfPeople: Int { get }

    @available(iOS, deprecated=9.0)
    func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(id: ABRecordID) -> P?

    func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(name: String) -> [P]

    func people<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S) -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P]

    // Groups

    var numberOfGroups: Int { get }

    @available(iOS, deprecated=9.0)
    func groupWithID<G: AddressBook_GroupType where G.Storage == GroupStorage>(id: ABRecordID) -> G?

    func groups<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> [G]

    func groupsInSource<G: AddressBook_GroupType, S: AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(source: S) -> [G]

    // Sources

    func defaultSource<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> S

    @available(iOS, deprecated=9.0)
    func sourceWithID<S: AddressBook_SourceType where S.Storage == SourceStorage>(id: ABRecordID) -> S?

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

    @available(iOS, deprecated=9.0)
    var id: ABRecordID { get }

    var recordKind: AddressBook.RecordKind { get }

    var compositeName: String { get }

    func value<P: ReadablePropertyType>(forProperty property: P) -> P.ValueType?

    func setValue<P: WriteablePropertyType>(value: P.ValueType?, forProperty property: P) -> ErrorType?
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

    func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(ordering: AddressBook.SortOrdering?) -> [P]

    func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType?

    func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType?
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

@available(iOS, deprecated=9.0)
public final class AddressBook: AddressBookType {

// MARK: - SortOrdering

    public enum SortOrdering: RawRepresentable, CustomStringConvertible {

        public static var current: SortOrdering {
            return SortOrdering(rawValue: ABPersonGetSortOrdering()) ?? .ByLastName
        }

        case ByLastName, ByFirstName

        public var rawValue: ABPersonSortOrdering {
            switch self {
            case .ByLastName:
                return numericCast(kABPersonSortByLastName)
            case .ByFirstName:
                return numericCast(kABPersonSortByFirstName)
            }
        }

        public var description: String {
            switch self {
            case .ByFirstName:
                return "ByFirstName"
            case .ByLastName:
                return "ByLastName"
            }
        }

        public init?(rawValue: ABPersonSortOrdering) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABPersonSortByFirstName:
                self = .ByFirstName
            case kABPersonSortByLastName:
                self = .ByLastName
            default:
                return nil
            }
        }
    }

// MARK: - CompositeNameFormat

    public enum CompositeNameFormat: RawRepresentable, CustomStringConvertible {

        case FirstNameFirst, LastNameFirst

        public var rawValue: ABPersonCompositeNameFormat {
            switch self {
            case .FirstNameFirst:
                return numericCast(kABPersonCompositeNameFormatFirstNameFirst)
            case .LastNameFirst:
                return numericCast(kABPersonCompositeNameFormatLastNameFirst)
            }
        }

        public var description: String {
            switch self {
            case .FirstNameFirst: return "FirstNameFirst"
            case .LastNameFirst: return "LastNameFirst"
            }
        }

        public init?(rawValue: ABPersonCompositeNameFormat) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABPersonCompositeNameFormatFirstNameFirst:
                self = .FirstNameFirst
            case kABPersonCompositeNameFormatLastNameFirst:
                self = .LastNameFirst
            default:
                return nil
            }
        }
    }

// MARK: - RecordKind

    public enum RecordKind: RawRepresentable, CustomStringConvertible {

        case Source, Group, Person

        public var rawValue: ABRecordType {
            switch self {
            case .Source:
                return numericCast(kABSourceType)
            case .Group:
                return numericCast(kABGroupType)
            case .Person:
                return numericCast(kABPersonType)
            }
        }

        public var description: String {
            switch self {
            case .Source:
                return "Source"
            case .Group:
                return "Group"
            case .Person:
                return "Person"
            }
        }

        public init?(rawValue: ABRecordType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABSourceType:
                self = .Source
            case kABGroupType:
                self = .Group
            case kABPersonType:
                self = .Person
            default:
                return nil
            }
        }
    }

// MARK: - SourceKind

    public enum SourceKind: RawRepresentable, CustomStringConvertible {

        case Local, Exchange, ExchangeGAL, MobileMe, LDAP, CardDAV, CardDAVSearch

        public var rawValue: ABSourceType {
            switch self {
            case .Local:
                return numericCast(kABSourceTypeLocal)
            case .Exchange:
                return numericCast(kABSourceTypeExchange)
            case .ExchangeGAL:
                return numericCast(kABSourceTypeExchangeGAL)
            case .MobileMe:
                return numericCast(kABSourceTypeMobileMe)
            case .LDAP:
                return numericCast(kABSourceTypeLDAP)
            case .CardDAV:
                return numericCast(kABSourceTypeCardDAV)
            case .CardDAVSearch:
                return numericCast(kABSourceTypeCardDAVSearch)
            }
        }

        public var description: String {
            switch self {
            case .Local:
                return "Local"
            case .Exchange:
                return "Exchange"
            case .ExchangeGAL:
                return "ExchangeGAL"
            case .MobileMe:
                return "MobileMe"
            case .LDAP:
                return "LDAP"
            case .CardDAV:
                return "CardDAV"
            case .CardDAVSearch:
                return "CardDAVSearch"
            }
        }

        public init?(rawValue: ABSourceType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABSourceTypeLocal:
                self = .Local
            case kABSourceTypeExchange:
                self = .Exchange
            case kABSourceTypeExchangeGAL:
                self = .ExchangeGAL
            case kABSourceTypeMobileMe:
                self = .MobileMe
            case kABSourceTypeLDAP:
                self = .LDAP
            case kABSourceTypeCardDAV:
                self = .CardDAV
            case kABSourceTypeCardDAVSearch:
                self = .CardDAVSearch
            default:
                return nil
            }
        }
    }

// MARK: - PropertyKind

    public enum PropertyKind: RawRepresentable, CustomStringConvertible {

        case Invalid, String, Integer, Real, DateTime, Dictionary, MultiString, MultiInteger, MultiReal, MultiDateTime, MultiDictionary

        public var rawValue: ABPropertyType {
            switch self {
            case .Invalid:
                return numericCast(kABInvalidPropertyType)
            case .String:
                return numericCast(kABStringPropertyType)
            case .Integer:
                return numericCast(kABIntegerPropertyType)
            case .Real:
                return numericCast(kABRealPropertyType)
            case .DateTime:
                return numericCast(kABDateTimePropertyType)
            case .Dictionary:
                return numericCast(kABDictionaryPropertyType)
            case .MultiString:
                return numericCast(kABMultiStringPropertyType)
            case .MultiInteger:
                return numericCast(kABMultiIntegerPropertyType)
            case .MultiReal:
                return numericCast(kABMultiRealPropertyType)
            case .MultiDateTime:
                return numericCast(kABMultiDateTimePropertyType)
            case .MultiDictionary:
                return numericCast(kABMultiDictionaryPropertyType)
            }
        }

        public var invalid: Bool {
            return self == .Invalid
        }

        public var multiValue: Bool {
            switch self {
            case .MultiString, .MultiInteger, .MultiReal, .MultiDateTime, .MultiDictionary:
                return true
            default:
                return false
            }
        }

        public var description: Swift.String {
            switch self {
            case .Invalid:
                return "Invalid"
            case .String:
                return "String"
            case .Integer:
                return "Integer"
            case .Real:
                return "Real"
            case .DateTime:
                return "DateTime"
            case .Dictionary:
                return "Dictionary"
            case .MultiString:
                return "MultiString"
            case .MultiInteger:
                return "MultiInteger"
            case .MultiReal:
                return "MultiReal"
            case .MultiDateTime:
                return "MultiDateTime"
            case .MultiDictionary:
                return "MultiDictionary"
            }
        }

        public init?(rawValue: ABPropertyType) {
            let value: Int = numericCast(rawValue)
            switch value {
            case kABInvalidPropertyType:
                self = .Invalid
            case kABStringPropertyType:
                self = .String
            case kABIntegerPropertyType:
                self = .Integer
            case kABRealPropertyType:
                self = .Real
            case kABDateTimePropertyType:
                self = .DateTime
            case kABDictionaryPropertyType:
                self = .Dictionary
            case kABMultiStringPropertyType:
                self = .MultiString
            case kABMultiIntegerPropertyType:
                self = .MultiInteger
            case kABMultiRealPropertyType:
                self = .MultiReal
            case kABMultiDateTimePropertyType:
                self = .MultiDateTime
            case kABMultiDictionaryPropertyType:
                self = .MultiDictionary
            default:
                return nil
            }
        }

    }

// MARK: - ImageFormat

    public typealias ImageFormat = ABPersonImageFormat

// MARK: - StringMultiValue

    public struct StringMultiValue: MultiValueRepresentable, Equatable, CustomStringConvertible, StringLiteralConvertible {

        public static let propertyKind = AddressBook.PropertyKind.String

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

        public static let propertyKind = AddressBook.PropertyKind.DateTime

        public var value: NSDate

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
            if let value = multiValueRepresentation as? NSDate {
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

    public typealias RecordStorage = ABRecordRef
    public typealias PersonStorage = ABRecordRef
    public typealias GroupStorage = ABRecordRef
    public typealias SourceStorage = ABRecordRef

    public enum Error: ErrorType {

        case Save(NSError?)
        case AddRecord(NSError?)
        case RemoveRecord(NSError?)
        case SetValue((id: ABPropertyID, underlyingError: NSError?))
        case RemoveValue((id: ABPropertyID, underlyingError: NSError?))
        case AddGroupMember(NSError?)
        case RemoveGroupMember(NSError?)

        case UnderlyingError(NSError)
        case UnknownError

        init(error: CFErrorRef?) {
            self = NSError.from(error).map { .UnderlyingError($0) } ?? .UnknownError
        }
    }

    private let registrar: AddressBookPermissionRegistrar

    public let addressBook: ABAddressBookRef!

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

@available(iOS, deprecated=9.0)
extension AddressBook {

    public func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void) {
        registrar.requestAccessToAddressBook(addressBook, completion: completion)
    }

    public func save() -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookSave(addressBook, &error) {
            return .None
        }
        return Error.Save(NSError.from(error?.takeRetainedValue()))
    }
}

@available(iOS, deprecated=9.0)
extension AddressBook { // Records

    public func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookAddRecord(addressBook, record.storage, &error) {
            return .None
        }
        return Error.AddRecord(NSError.from(error?.takeRetainedValue()))
    }

    public func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookRemoveRecord(addressBook, record.storage, &error) {
            return .None
        }
        return Error.RemoveRecord(NSError.from(error?.takeRetainedValue()))
    }
}

@available(iOS, deprecated=9.0)
extension AddressBook { // People

    public var numberOfPeople: Int {
        return ABAddressBookGetPersonCount(addressBook)
    }

    public func createPerson<P: AddressBook_PersonType, S: AddressBookSourceType where P.Storage == PersonStorage, S.Storage == SourceStorage, P.Storage == S.PersonStorage>(source: S? = .None) -> P {
        if let source = source {
            return source.newPerson()
        }
        return P(storage: ABPersonCreate().takeUnretainedValue())
    }

    public func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(id: ABRecordID) -> P? {
        if let record = ABAddressBookGetPersonWithRecordID(addressBook, id) {
            return P(storage: record.takeUnretainedValue())
        }
        return .None
    }

    public func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(name: String) -> [P] {
        if let people = ABAddressBookCopyPeopleWithName(addressBook, name) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func people<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeople(addressBook) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, source.storage) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source.storage, sortOrdering.rawValue) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }
}

@available(iOS, deprecated=9.0)
extension AddressBook { // Groups

    public var numberOfGroups: Int {
        return ABAddressBookGetGroupCount(addressBook)
    }

    public func groupWithID<G: AddressBook_GroupType where G.Storage == GroupStorage>(id: ABRecordID) -> G? {
        if let record = ABAddressBookGetGroupWithRecordID(addressBook, id) {
            return G(storage: record.takeUnretainedValue())
        }
        return .None
    }

    public func groups<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> [G] {
        if let records = ABAddressBookCopyArrayOfAllGroups(addressBook) {
            let values = records.takeRetainedValue() as [ABRecordRef]
            return values.map { G(storage: $0) }
        }
        return []
    }

    public func groupsInSource<G: AddressBook_GroupType, S: AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(source: S) -> [G] {
        if let records = ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.storage) {
            let values = records.takeRetainedValue() as [ABRecordRef]
            return values.map { G(storage: $0) }
        }
        return []
    }
}

@available(iOS, deprecated=9.0)
extension AddressBook { // Sources

    public func defaultSource<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> S {
        let source: ABRecordRef = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        return S(storage: source)
    }

    public func sourceWithID<S: AddressBook_SourceType where S.Storage == SourceStorage>(id: ABRecordID) -> S? {
        if let record = ABAddressBookGetSourceWithRecordID(addressBook, id) {
            return S(storage: record.takeUnretainedValue())
        }
        return .None
    }

    public func sources<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> [S] {
        if let sources = ABAddressBookCopyArrayOfAllSources(addressBook) {
            let values = sources.takeRetainedValue() as [ABRecordRef]
            return values.map { S(storage: $0) }
        }
        return []
    }
}

// MARK: - Property

@available(iOS, deprecated=9.0)
public struct AddressBookReadableProperty<Value>: ReadablePropertyType {
    public typealias ValueType = Value

    public let id: ABPropertyID
    public let reader: ((CFTypeRef) -> ValueType)?

    public init(id: ABPropertyID, reader: ((CFTypeRef) -> ValueType)? = .None) {
        self.id = id
        self.reader = reader
    }
}

@available(iOS, deprecated=9.0)
public struct AddressBookWriteableProperty<Value>: ReadablePropertyType, WriteablePropertyType {
    public typealias ValueType = Value

    public let id: ABPropertyID
    public let reader: ((CFTypeRef) -> ValueType)?
    public let writer: ((ValueType) -> CFTypeRef)?

    public init(id: ABPropertyID, reader: ((CFTypeRef) -> ValueType)? = .None, writer: ((ValueType) -> CFTypeRef)? = .None) {
        self.id = id
        self.reader = reader
        self.writer = writer
    }
}

// MARK: - LabeledValue

@available(iOS, deprecated=9.0)
public struct LabeledValue<Value: MultiValueRepresentable>: CustomStringConvertible, CustomDebugStringConvertible {

    static func read(multiValue: ABMultiValueRef) -> [LabeledValue<Value>] {
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

    static func write(labeledValues: [LabeledValue<Value>]) -> ABMultiValueRef {
        return labeledValues.reduce(ABMultiValueCreateMutable(Value.propertyKind.rawValue).takeRetainedValue() as ABMutableMultiValueRef) { (multiValue, labeledValue) in
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

@available(iOS, deprecated=9.0)
public class AddressBookRecord: AddressBookRecordType, Equatable {

    public let storage: ABRecordRef

    public var id: ABRecordID {
        return ABRecordGetRecordID(storage)
    }

    public var recordKind: AddressBook.RecordKind {
        return AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage))!
    }

    public var compositeName: String {
        assert(recordKind != .Source, "compositeName is not defined for Source records")
        return ABRecordCopyCompositeName(storage).takeRetainedValue() as String
    }

    public required init(storage: ABRecordRef) {
        self.storage = storage
    }

    public func value<P: ReadablePropertyType>(forProperty property: P) -> P.ValueType? {
        if let unmanaged = ABRecordCopyValue(storage, property.id) {
            let value: CFTypeRef = unmanaged.takeRetainedValue()
            return property.reader?(value) ?? value as! P.ValueType
        }
        return .None
    }

    public func setValue<P: WriteablePropertyType>(value: P.ValueType?, forProperty property: P) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if let value = value {
            let transformed: CFTypeRef = property.writer?(value) ?? value as! CFTypeRef
            if ABRecordSetValue(storage, property.id, transformed, &error) {
                return .None
            }
            return AddressBook.Error.SetValue(id: property.id, underlyingError: NSError.from(error?.takeRetainedValue()))
        }
        else {
            if ABRecordRemoveValue(storage, property.id, &error) {
                return .None
            }
            return AddressBook.Error.RemoveValue(id: property.id, underlyingError: NSError.from(error?.takeRetainedValue()))
        }
    }
}

@available(iOS, deprecated=9.0)
public func == (lhs: AddressBookRecord, rhs: AddressBookRecord) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Person

@available(iOS, deprecated=9.0)
public class AddressBookPerson: AddressBookRecord, AddressBookPersonType {

    public struct Property {

        public struct Metadata {
            public static let creationDate      = AddressBookReadableProperty<NSDate>(id: kABPersonCreationDateProperty)
            public static let modificationDate  = AddressBookWriteableProperty<NSDate>(id: kABPersonModificationDateProperty)
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

    public typealias GroupStorage = ABRecordRef
    public typealias SourceStorage = ABRecordRef

    public var compositeNameFormat: AddressBook.CompositeNameFormat {
        return AddressBook.CompositeNameFormat(rawValue: ABPersonGetCompositeNameFormatForRecord(storage))!
    }

    public required init(storage: ABRecordRef) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .Person, "ABRecordRef \(storage) is not a Person.")
        super.init(storage: storage)
    }
}

// MARK: - Group

@available(iOS, deprecated=9.0)
public class AddressBookGroup: AddressBookRecord, AddressBookGroupType {

    public struct Property {
        public static let name = AddressBookWriteableProperty<String>(id: kABGroupNameProperty)
    }

    public typealias PersonStorage = ABRecordRef
    public typealias SourceStorage = ABRecordRef

    public convenience init() {
        let storage: ABRecordRef = ABGroupCreate().takeRetainedValue()
        self.init(storage: storage)
    }

    public required init(storage: ABRecordRef) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .Group, "ABRecordRef \(storage) is not a Group.")
        super.init(storage: storage)
    }

    public func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(ordering: AddressBook.SortOrdering? = .None) -> [P] {
        let result: [ABRecordRef] = {
            if let ordering = ordering, unmanaged = ABGroupCopyArrayOfAllMembersWithSortOrdering(self.storage, ordering.rawValue) {
                return unmanaged.takeRetainedValue() as [ABRecordRef]
            }
            else if let unmanaged = ABGroupCopyArrayOfAllMembers(self.storage) {
                return unmanaged.takeRetainedValue() as [ABRecordRef]
            }
            return []
        }()

        return result.map { P(storage: $0) }
    }

    public func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABGroupAddMember(storage, member.storage, &error) {
            return .None
        }
        return AddressBook.Error.AddGroupMember(NSError.from(error?.takeRetainedValue()))
    }

    public func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABGroupRemoveMember(storage, member.storage, &error) {
            return .None
        }
        return AddressBook.Error.RemoveGroupMember(NSError.from(error?.takeRetainedValue()))
    }
}

// MARK: - Source

@available(iOS, deprecated=9.0)
public class AddressBookSource: AddressBookRecord, AddressBookSourceType {

    public struct Property {
        public static let kind = AddressBookReadableProperty<AddressBook.SourceKind>(id: kABSourceTypeProperty, reader: reader)
    }

    public typealias PersonStorage = ABRecordRef
    public typealias GroupStorage = ABRecordRef

    public var sourceKind: AddressBook.SourceKind {
        return value(forProperty: AddressBookSource.Property.kind)!
    }

    public required init(storage: ABRecordRef) {
        precondition(AddressBook.RecordKind(rawValue: ABRecordGetRecordType(storage)) == .Source, "ABRecordRef \(storage) is not a Source.")
        super.init(storage: storage)
    }

    public func newPerson<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> P {
        let person: ABRecordRef = ABPersonCreateInSource(storage).takeRetainedValue()
        return P(storage: person)
    }

    public func newGroup<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> G {
        let group: ABRecordRef = ABGroupCreateInSource(storage).takeRetainedValue()
        return G(storage: group)
    }
}




// MARK: - Equatable

extension CFNumberRef: Equatable {}

public func == (lhs: CFNumberRef, rhs: CFNumberRef) -> Bool {
    return CFNumberCompare(lhs, rhs, nil) == .CompareEqualTo
}

public func == (lhs: AddressBook.StringMultiValue, rhs: AddressBook.StringMultiValue) -> Bool {
    return lhs.value == rhs.value
}

public func == (lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value == rhs.value
}

public func < (lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value.compare(rhs.value) == .OrderedAscending
}

// MARK: - Helpers

func reader<T: RawRepresentable>(value: CFTypeRef) -> T {
    return T(rawValue: value as! T.RawValue)!
}

func writer<T: RawRepresentable>(value: T) -> CFTypeRef {
    return value.rawValue as! CFTypeRef
}

@available(iOS, deprecated=9.0)
func reader<T: MultiValueRepresentable>(value: CFTypeRef) -> [LabeledValue<T>] {
    return LabeledValue.read(value as ABMultiValueRef)
}

@available(iOS, deprecated=9.0)
func writer<T: MultiValueRepresentable>(value: [LabeledValue<T>]) -> CFTypeRef {
    return LabeledValue.write(value)
}

extension NSError {

    static func from(ref: CFErrorRef?) -> NSError? {
        return unsafeBitCast(ref, NSError.self)
    }
}








public enum AddressBookPermissionRegistrarError: ErrorType {
    case AddressBookUnknownErrorOccured
    case AddressBookAccessDenied
}

@available(iOS, deprecated=9.0)
public struct SystemAddressBookRegistrar: AddressBookPermissionRegistrar {

    public var status: ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }

    public func createAddressBook() -> (ABAddressBookRef?, AddressBookPermissionRegistrarError?) {
        var addressBookError: Unmanaged<CFErrorRef>? = .None
        if let addressBook = ABAddressBookCreateWithOptions(nil, &addressBookError) {
            return (addressBook.takeRetainedValue(), .None)
        }
        else if let error = NSError.from(addressBookError?.takeRetainedValue()) {
            if (error.domain == ABAddressBookErrorDomain as String) && error.code == kABOperationNotPermittedByUserError {
                return (.None, AddressBookPermissionRegistrarError.AddressBookAccessDenied)
            }
        }
        return (.None, AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
    }

    public func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: (AddressBookPermissionRegistrarError?) -> Void) {
        ABAddressBookRequestAccessWithCompletion(addressBook) { (success, error) in
            if success {
                completion(nil)
            }
            else if let _ = error {
                completion(AddressBookPermissionRegistrarError.AddressBookAccessDenied)
            }
            else {
                completion(AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
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
