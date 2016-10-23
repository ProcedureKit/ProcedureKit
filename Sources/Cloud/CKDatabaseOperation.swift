//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// An extension to make CKDatabaseOperation to conform to the CKDatabaseOperationProtocol.
extension CKDatabaseOperation: CKDatabaseOperationProtocol {

    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}

extension CKProcedure where T: CKDatabaseOperationProtocol {

    var database: T.Database? {
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

extension CKProcedure where T: CKPreviousServerChangeToken {

    var previousServerChangeToken: T.ServerChangeToken? {
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

extension CKProcedure where T: CKResultsLimit {

    var resultsLimit: Int {
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

extension CKProcedure where T: CKMoreComing {

    var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitProcedure where T: CKMoreComing {

    /// - returns: a flag to indicate whether there are more results on the server
    public var moreComing: Bool {
        return current.moreComing
    }
}
// MARK: - CKFetchAllChanges

extension CKProcedure where T: CKFetchAllChanges {

    var fetchAllChanges: Bool {
        get { return operation.fetchAllChanges }
        set { operation.fetchAllChanges = newValue }
    }
}

extension CloudKitProcedure where T: CKFetchAllChanges {

    /// - returns: the previous server change token
    public var fetchAllChanges: Bool {
        get { return current.fetchAllChanges }
        set {
            current.fetchAllChanges = newValue
            appendConfigureBlock { $0.fetchAllChanges = newValue }
        }
    }
}

// MARK: - CKDesiredKeys

extension CKProcedure where T: CKDesiredKeys {

    var desiredKeys: [String]? {
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
