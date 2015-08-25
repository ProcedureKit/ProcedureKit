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

    var addressBook: ABAddressBookRef { get }

    func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void)

//    func save() -> ErrorType?
}

// MARK: - Types

public struct AddressBook: AddressBookType {

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

    public enum RecordType: RawRepresentable, Printable {

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

    public enum SourceType: RawRepresentable, Printable {

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

    enum Error: ErrorType {
        case UnknownError
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

    public func requestAccess(completion: (AddressBookPermissionRegistrarError?) -> Void) {
        registrar.requestAccessToAddressBook(addressBook, completion: completion)
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
















// MARK: - Helpers

extension ABPersonImageFormat: Equatable {}

public func ==(a: ABPersonImageFormat, b: ABPersonImageFormat) -> Bool {
    return a.value == b.value
}

extension CFNumberRef: Equatable {}

public func ==(a: CFNumberRef, b: CFNumberRef) -> Bool {
    return CFNumberCompare(a, b, nil) == .CompareEqualTo
}













public protocol AddressBookRecordType {
    var recordID: ABRecordID { get }
    var compositeName: String { get }

    init(recordRef: ABRecordRef)
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

