//
//  AddressBook.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

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

public protocol PropertyType {
    typealias ValueType
    var id: ABPropertyID { get }
}

public protocol ReadablePropertyType: PropertyType {
    var reader: ((CFTypeRef) -> ValueType)? { get }
}

public protocol WriteablePropertyType: PropertyType {
    var writer: ((ValueType) -> CFTypeRef)? { get }
}

public protocol MultiValueRepresentable {
    static var propertyKind: AddressBook.PropertyKind { get }
    var multiValueRepresentation: CFTypeRef { get }
    init?(multiValueRepresentation: CFTypeRef)
}

public protocol AddressBookPermissionRegistrar {
    var status: ABAuthorizationStatus { get }
    func createAddressBook() -> (ABAddressBookRef?, AddressBookPermissionRegistrarError?)
    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: (AddressBookPermissionRegistrarError?) -> Void)
}


public protocol AddressBookType {

    typealias RecordStorage
    typealias PersonStorage
    typealias GroupStorage
    typealias SourceStorage

    func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void)

    func save() -> ErrorType?

    // Records

    func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType?

    func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType?

    // People

    var numberOfPeople: Int { get }

    func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(id: ABRecordID) -> P?

    func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(name: String) -> [P]

    func people<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S) -> [P]

    func peopleInSource<P: AddressBook_PersonType, S: AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P]

    // Groups

    var numberOfGroups: Int { get }

    func groupWithID<G: AddressBook_GroupType where G.Storage == GroupStorage>(id: ABRecordID) -> G?

    func groups<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> [G]

    func groupsInSource<G: AddressBook_GroupType, S: AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(source: S) -> [G]

    // Sources

    func defaultSource<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> S

    func sourceWithID<S: AddressBook_SourceType where S.Storage == SourceStorage>(id: ABRecordID) -> S?

    func sources<S: AddressBook_SourceType where S.Storage == SourceStorage>() -> [S]
}

public protocol StorageType {
    typealias Storage

    var storage: Storage { get }

    init(storage: Storage)
}

public protocol AddressBookRecordType: StorageType {

    var id: ABRecordID { get }

    var recordKind: AddressBook.RecordKind { get }

    var compositeName: String { get }

    func value<P: ReadablePropertyType>(forProperty property: P) -> P.ValueType?

    func setValue<P: WriteablePropertyType>(value: P.ValueType?, forProperty property: P) -> ErrorType?
}

public protocol AddressBook_PersonType: AddressBookRecordType {
    typealias GroupStorage
    typealias SourceStorage
}

public protocol AddressBookPersonType: AddressBook_PersonType {

    var compositeNameFormat: AddressBook.CompositeNameFormat { get }
}

public protocol AddressBook_GroupType: AddressBookRecordType {
    typealias PersonStorage
    typealias SourceStorage
}

public protocol AddressBookGroupType: AddressBook_GroupType {

    func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(ordering: AddressBook.SortOrdering?) -> [P]

    func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType?

    func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType?
}

public protocol AddressBook_SourceType: AddressBookRecordType {
    typealias PersonStorage
    typealias GroupStorage
}

public protocol AddressBookSourceType: AddressBook_SourceType {

    var sourceKind: AddressBook.SourceKind { get }

    func newPerson<P: AddressBook_PersonType where P.Storage == PersonStorage>() -> P

    func newGroup<G: AddressBook_GroupType where G.Storage == GroupStorage>() -> G
}


// MARK: - Types

public final class AddressBook: AddressBookType {

// MARK: - SortOrdering

    public enum SortOrdering: RawRepresentable, Printable {

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

    public enum CompositeNameFormat: RawRepresentable, Printable {

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

    public enum RecordKind: RawRepresentable, Printable {

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

    public enum SourceKind: RawRepresentable, Printable {

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

    public enum PropertyKind: RawRepresentable, Printable {

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
            return self != .Invalid
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

    public enum ImageFormat: RawRepresentable, Printable {

        case OriginalSize, Thumbnail

        public var rawValue: ABPersonImageFormat {
            switch self {
            case .OriginalSize:
                return kABPersonImageFormatOriginalSize
            case .Thumbnail:
                return kABPersonImageFormatThumbnail
            }
        }

        public var description: String {
            switch self {
            case .OriginalSize:
                return "OriginalSize"
            case .Thumbnail:
                return "Thumbnail"
            }
        }

        public init?(rawValue: ABPersonImageFormat) {
            switch rawValue.value {
            case kABPersonImageFormatOriginalSize.value:
                self = .OriginalSize
            case kABPersonImageFormatThumbnail.value:
                self = .Thumbnail
            default:
                return nil
            }
        }
    }

// MARK: - StringMultiValue

    public struct StringMultiValue: MultiValueRepresentable, Equatable, Printable, StringLiteralConvertible {

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

        public init(stringLiteral value: String){
            self.value = value
        }

        public  init(extendedGraphemeClusterLiteral value: String){
            self.value = value
        }

        public  init(unicodeScalarLiteral value: String){
            self.value = value
        }
    }

// MARK: - DateMultiValue

    public struct DateMultiValue: MultiValueRepresentable, Comparable, Printable, DebugPrintable {

        public static let propertyKind = AddressBook.PropertyKind.DateTime

        public var value: NSDate

        public var multiValueRepresentation: CFTypeRef {
            return value
        }

        public var description: String {
            return toString(value)
        }

        public var debugDescription: String {
            return toDebugString(value)
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

    enum Error: ErrorType {
        case UnderlyingError(NSError)
        case UnknownError

        init(error: Unmanaged<CFErrorRef>?) {
            if let error = error {
                self = .UnderlyingError(unsafeBitCast(error.takeUnretainedValue(), NSError.self))
            }
            else {
                self = .UnknownError
            }
        }
    }

    private let registrar: AddressBookPermissionRegistrar

    public let addressBook: ABAddressBookRef

    public init(registrar: AddressBookPermissionRegistrar = SystemAddressBookRegistrar()) {
        self.registrar = registrar
        let (addressBook: ABAddressBookRef?, error) = registrar.createAddressBook()
        if let addressBook: ABAddressBookRef = addressBook {
            self.addressBook = addressBook
        }
        else if let error = error {
            // Preparing the way for Swift 2.0 where this 
            // initializer will potentially throw
            fatalError("Error creating address book: \(error)")
        }
        else {
            fatalError("Unknown error creating address book")
        }
    }

}

extension AddressBook {

    public func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void) {
        registrar.requestAccessToAddressBook(addressBook, completion: completion)
    }

    public func save() -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookSave(addressBook, &error) {
            return .None
        }

        return AddressBook.Error(error: error)
    }
}

extension AddressBook { // Records

    public func addRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookAddRecord(addressBook, record.storage, &error) {
            return .None
        }
        return AddressBook.Error(error: error)
    }

    public func removeRecord<R: AddressBookRecordType where R.Storage == RecordStorage>(record: R) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABAddressBookRemoveRecord(addressBook, record.storage, &error) {
            return .None
        }
        return AddressBook.Error(error: error)
    }
}

extension AddressBook { // People

    public var numberOfPeople: Int {
        return ABAddressBookGetPersonCount(addressBook)
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

    public func people<P : AddressBook_PersonType where P.Storage == PersonStorage>() -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeople(addressBook) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P : AddressBook_PersonType, S : AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, source.storage) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }

    public func peopleInSource<P : AddressBook_PersonType, S : AddressBook_SourceType where P.Storage == PersonStorage, S.Storage == SourceStorage>(source: S, withSortOrdering sortOrdering: AddressBook.SortOrdering) -> [P] {
        if let people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source.storage, sortOrdering.rawValue) {
            let values = people.takeRetainedValue() as [ABRecordRef]
            return values.map { P(storage: $0) }
        }
        return []
    }
}

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

    public func groupsInSource<G: AddressBook_GroupType, S : AddressBook_SourceType where G.Storage == GroupStorage, S.Storage == SourceStorage>(source: S) -> [G] {
        if let records = ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.storage) {
            let values = records.takeRetainedValue() as [ABRecordRef]
            return values.map { G(storage: $0) }
        }
        return []
    }
}

extension AddressBook { // Sources

    public func defaultSource<S : AddressBook_SourceType where S.Storage == SourceStorage>() -> S {
        let source: ABRecordRef = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        return S(storage: source)
    }

    public func sourceWithID<S : AddressBook_SourceType where S.Storage == SourceStorage>(id: ABRecordID) -> S? {
        if let record = ABAddressBookGetSourceWithRecordID(addressBook, id) {
            return S(storage: record.takeUnretainedValue())
        }
        return .None
    }

    public func sources<S : AddressBook_SourceType where S.Storage == SourceStorage>() -> [S] {
        if let sources = ABAddressBookCopyArrayOfAllSources(addressBook) {
            let values = sources.takeRetainedValue() as [ABRecordRef]
            return values.map { S(storage: $0) }
        }
        return []
    }
}

// MARK: - Property

public struct AddressBookReadableProperty<Value>: ReadablePropertyType {
    typealias ValueType = Value

    public let id: ABPropertyID
    public let reader: ((CFTypeRef) -> ValueType)?

    public init(id: ABPropertyID, reader: ((CFTypeRef) -> ValueType)? = .None) {
        self.id = id
        self.reader = reader
    }
}

public struct AddressBookWriteableProperty<Value>: ReadablePropertyType, WriteablePropertyType {
    typealias ValueType = Value

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

public struct LabeledValue<Value: MultiValueRepresentable>: DebugPrintable, Printable {

    static func read(multiValue: ABMultiValueRef) -> [LabeledValue<Value>] {
        assert(AddressBook.PropertyKind(rawValue: ABMultiValueGetPropertyType(multiValue)) == Value.propertyKind, "ABMultiValueRef has incompatible property kind.")
        let count: Int = ABMultiValueGetCount(multiValue)
        return reduce(0..<count, [LabeledValue<Value>]()) { (var acc, index) in
            let representation: CFTypeRef = ABMultiValueCopyValueAtIndex(multiValue, index).takeRetainedValue()
            if let value = Value(multiValueRepresentation: representation) {
                let label = ABMultiValueCopyLabelAtIndex(multiValue, index).takeRetainedValue() as String
                let labeledValue = LabeledValue(label: label, value: value)
                acc.append(labeledValue)
            }
            return acc
        }
    }

    static func write(labeledValues: [LabeledValue<Value>]) -> ABMultiValueRef {
        return reduce(labeledValues, ABMultiValueCreateMutable(Value.propertyKind.rawValue).takeRetainedValue() as ABMutableMultiValueRef) { (multiValue, labeledValue) -> ABMutableMultiValueRef in
            ABMultiValueAddValueAndLabel(multiValue, labeledValue.value.multiValueRepresentation, labeledValue.label, nil)
        }
    }

    public let label: String
    public let value: Value

    public var description: String {
        return "\(label): \(toString(value))"
    }

    public var debugDescription: String {
        return "\(label): \(toDebugString(value))"
    }

    public init(label: String, value: Value) {
        self.label = label
        self.value = value
    }
}

// MARK: - Record

public class AddressBookRecord: AddressBookRecordType {

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
        }
        else {
            if ABRecordRemoveValue(storage, property.id, &error) {
                return .None
            }
        }

        return AddressBook.Error(error: error)
    }
}

// MARK: - Person

public class AddressBookPerson: AddressBookRecord, AddressBookPersonType {

    public struct Property {

        public struct Metadata {
            public static let creationDate      = AddressBookReadableProperty<NSDate>(id: kABPersonCreationDateProperty)
            public static let modificationDate  = AddressBookReadableProperty<NSDate>(id: kABPersonModificationDateProperty)
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

    public func members<P: AddressBook_PersonType where P.Storage == PersonStorage>(_ ordering: AddressBook.SortOrdering? = .None) -> [P] {
        let result: [ABRecordRef] = {
            if let ordering = ordering {
                return ABGroupCopyArrayOfAllMembersWithSortOrdering(self.storage, ordering.rawValue).takeRetainedValue() as [ABRecordRef]
            }
            else {
                return ABGroupCopyArrayOfAllMembers(self.storage).takeRetainedValue() as [ABRecordRef]
            }
        }()

        return result.map { P(storage: $0) }
    }

    public func add<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABGroupAddMember(storage, member.storage, &error) {
            return .None
        }
        return AddressBook.Error(error: error)
    }

    public func remove<P: AddressBook_PersonType where P.Storage == PersonStorage>(member: P) -> ErrorType? {
        var error: Unmanaged<CFErrorRef>? = .None
        if ABGroupRemoveMember(storage, member.storage, &error) {
            return .None
        }
        return AddressBook.Error(error: error)
    }
}

// MARK: - Source

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

    public func newGroup<G : AddressBook_GroupType where G.Storage == GroupStorage>() -> G {
        let group: ABRecordRef = ABGroupCreateInSource(storage).takeRetainedValue()
        return G(storage: group)
    }
}














// MARK: - Equatable

extension ABPersonImageFormat: Equatable {}

public func ==(a: ABPersonImageFormat, b: ABPersonImageFormat) -> Bool {
    return a.value == b.value
}

extension CFNumberRef: Equatable {}

public func ==(a: CFNumberRef, b: CFNumberRef) -> Bool {
    return CFNumberCompare(a, b, nil) == .CompareEqualTo
}

public func ==(a: AddressBook.StringMultiValue, b: AddressBook.StringMultiValue) -> Bool {
    return a.value == b.value
}

public func ==(lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value == rhs.value
}

public func <(lhs: AddressBook.DateMultiValue, rhs: AddressBook.DateMultiValue) -> Bool {
    return lhs.value.compare(rhs.value) == .OrderedAscending
}

// MARK: - Helpers

func reader<T: RawRepresentable>(value: CFTypeRef) -> T {
    return T(rawValue: value as! T.RawValue)!
}

func writer<T: RawRepresentable>(value: T) -> CFTypeRef {
    return value.rawValue as! CFTypeRef
}

func reader<T: MultiValueRepresentable>(value: CFTypeRef) -> [LabeledValue<T>] {
    return LabeledValue.read(value as ABMultiValueRef)
}

func writer<T: MultiValueRepresentable>(value: [LabeledValue<T>]) -> CFTypeRef {
    return LabeledValue.write(value)
}










public enum AddressBookPermissionRegistrarError: ErrorType {
    case AddressBookUnknownErrorOccured
    case AddressBookCreationFailed(CFErrorRef)
    case AddressBookAccessFailed(CFErrorRef)
}

public struct SystemAddressBookRegistrar: AddressBookPermissionRegistrar {

    public var status: ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }

    public func createAddressBook() -> (ABAddressBookRef?, AddressBookPermissionRegistrarError?) {
        var addressBookError: Unmanaged<CFErrorRef>? = .None
        if let addressBook = ABAddressBookCreateWithOptions(nil, &addressBookError) {
            return (addressBook.takeRetainedValue(), .None)
        }
        else if let error = addressBookError {
            return (.None, AddressBookPermissionRegistrarError.AddressBookCreationFailed(error.takeUnretainedValue()))
        }
        else {
            return (.None, AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
        }
    }

    public func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: (AddressBookPermissionRegistrarError?) -> Void) {
        ABAddressBookRequestAccessWithCompletion(addressBook) { (success, error) in
            if success {
                completion(nil)
            }
            else if let error = error {
                completion(AddressBookPermissionRegistrarError.AddressBookAccessFailed(error))
            }
            else {
                completion(AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
            }
        }
    }
}

