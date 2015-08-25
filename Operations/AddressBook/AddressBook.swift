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

    var numberOfPeople: Int { get }

    func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void)

    func save() -> ErrorType?

    func personWithID<P: AddressBook_PersonType where P.Storage == PersonStorage>(id: ABRecordID) -> P?

    func peopleWithName<P: AddressBook_PersonType where P.Storage == PersonStorage>(name: String) -> [P]
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

    public var numberOfPeople: Int {
        return ABAddressBookGetPersonCount(addressBook)
    }

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

public struct AddressBookWriteableProperty<Value>: WriteablePropertyType {
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














// MARK: - Helpers

extension ABPersonImageFormat: Equatable {}

public func ==(a: ABPersonImageFormat, b: ABPersonImageFormat) -> Bool {
    return a.value == b.value
}

extension CFNumberRef: Equatable {}

public func ==(a: CFNumberRef, b: CFNumberRef) -> Bool {
    return CFNumberCompare(a, b, nil) == .CompareEqualTo
}

func reader<T: RawRepresentable>(value: CFTypeRef) -> T {
    return T(rawValue: value as! T.RawValue)!
}

func writer<T: RawRepresentable>(value: T) -> CFTypeRef {
    return value.rawValue as! CFTypeRef
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

