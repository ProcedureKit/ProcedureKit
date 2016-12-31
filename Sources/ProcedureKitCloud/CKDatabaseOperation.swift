//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Database Operation types.
 */
public protocol CKDatabaseOperationProtocol: CKOperationProtocol {

    /// The type of the CloudKit Database
    associatedtype Database

    /// - returns: the CloudKit Database
    var database: Database? { get set }
}

/// An extension to make CKDatabaseOperation to conform to the CKDatabaseOperationProtocol.
extension CKDatabaseOperation: CKDatabaseOperationProtocol {

    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}

extension CKProcedure where T: CKDatabaseOperationProtocol {

    public var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

extension CloudKitProcedure where T: CKDatabaseOperationProtocol {

    /// - returns: the CloudKit database
    public var database: T.Database? {
        get { return current.database }
        set {
            current.database = newValue
            appendConfigureBlock { $0.database = newValue }
        }
    }
}

// MARK: - CKPreviousServerChangeToken

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Operation's which return the previous sever change
 token.
 */
public protocol CKPreviousServerChangeToken: CKOperationProtocol {

    /// - returns: the previous sever change token
    var previousServerChangeToken: ServerChangeToken? { get set }
}

extension CKProcedure where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

extension CloudKitProcedure where T: CKPreviousServerChangeToken {

    /// - returns: the previous server change token
    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return current.previousServerChangeToken }
        set {
            current.previousServerChangeToken = newValue
            appendConfigureBlock { $0.previousServerChangeToken = newValue }
        }
    }
}

// MARK: - CKResultsLimit

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a results limit.
public protocol CKResultsLimit: CKOperationProtocol {

    /// - returns: the results limit
    var resultsLimit: Int { get set }
}

extension CKProcedure where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

extension CloudKitProcedure where T: CKResultsLimit {

    /// - returns: the results limit
    public var resultsLimit: Int {
        get { return current.resultsLimit }
        set {
            current.resultsLimit = newValue
            appendConfigureBlock { $0.resultsLimit = newValue }
        }
    }
}

// MARK: - CKMoreComing

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a flag for more coming.
public protocol CKMoreComing: CKOperationProtocol {

    /// - returns: whether there are more results on the server
    var moreComing: Bool { get }
}

extension CKProcedure where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitProcedure where T: CKMoreComing {

    /// - returns: a flag to indicate whether there are more results on the server
    public var moreComing: Bool {
        return current.moreComing
    }
}

// MARK: - CKDesiredKeys

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have desired keys.
public protocol CKDesiredKeys: CKOperationProtocol {

    /// - returns: the desired keys to fetch or fetched.
    var desiredKeys: [String]? { get set }
}

extension CKProcedure where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

extension CloudKitProcedure where T: CKDesiredKeys {

    /// - returns: the desired keys
    public var desiredKeys: [String]? {
        get { return current.desiredKeys }
        set {
            current.desiredKeys = newValue
            appendConfigureBlock { $0.desiredKeys = newValue }
        }
    }
}

/// A protocol typealias which exposes the properties used by Apple's CloudKit batched operation types.
public typealias CKBatchedOperation = CKResultsLimit & CKMoreComing

/// A protocol typealias which exposes the properties used by Apple's CloudKit fetched operation types.
public typealias CKFetchOperation = CKPreviousServerChangeToken & CKBatchedOperation
