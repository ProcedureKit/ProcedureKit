//
//  CloudKitOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

public protocol CKOperationType: class { }

public class CloudKitOperation<T where T: CKOperationType, T: NSOperation>: Operation {

    public private(set) var operation: T
    public let recoverFromError: (T, ErrorType) -> T?

    internal private(set) var configure: (T -> T)?

    public init(_ op: T, recovery: (T, ErrorType) -> T? = { _, _ in .None }) {
        operation = op
        recoverFromError = recovery
        super.init()
        name = "CloudKitOperation<\(operation.dynamicType)>"
    }

    public override func cancel() {
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        defer { go(operation) }
        guard let _ = configure else {
            let warning = "A completion block was not set for: \(operation.dynamicType), error handling will not be triggered."
            log.warning(warning)
            operation.addCompletionBlock {
                self.finish()
            }
            return
        }
    }

    private func go(op: T) -> T {
        let _op = configure?(op) ?? op
        produceOperation(_op)
        return _op
    }

    func receivedError(error: ErrorType) {
        guard let op = recoverFromError(operation, error) else {
            finish(error)
            return
        }

        operation = go(op)
    }
}

// MARK: - CKDiscoverAllContactsOperation

public protocol CKDatabaseOperationType: CKOperationType {
    typealias Database
    var database: Database? { get set }
}

extension CKDatabaseOperation: CKDatabaseOperationType { }

extension CloudKitOperation where T: CKDatabaseOperationType {

    public var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

// MARK: - CKDiscoverAllContactsOperation

public protocol CKDiscoverAllContactsOperationType: CKOperationType {
    var discoverAllContactsCompletionBlock: (([CKDiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [CKDiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock?) {
        guard let block = block else {
            configure = .None
            operation.discoverAllContactsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.discoverAllContactsCompletionBlock = { userInfo, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfo)
                    self.finish()
                }
            }
            return op
        }
    }
}

// MARK: - CKDiscoverUserInfosOperation

public protocol CKDiscoverUserInfosOperationType: CKOperationType {
    var emailAddresses: [String]? { get set }
    var userRecordIDs: [CKRecordID]? { get set }
    var discoverUserInfosCompletionBlock: (([String: CKDiscoveredUserInfo]?, [CKRecordID: CKDiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationType { }

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

    public typealias DiscoverUserInfosCompletionBlock = ([String: CKDiscoveredUserInfo]?, [CKRecordID: CKDiscoveredUserInfo]?) -> Void

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [CKRecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock?) {
        guard let block = block else {
            configure = .None
            operation.discoverUserInfosCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.emailAddresses = self.operation.emailAddresses
            op.userRecordIDs = self.operation.userRecordIDs
            op.discoverUserInfosCompletionBlock = { userInfoByEmail, userInfoByRecordID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfoByEmail, userInfoByRecordID)
                    self.finish()
                }
            }

            return op
        }
    }
}

// MARK: - CKFetchNotificationChangesOperation

public protocol CKFetchNotificationChangesOperationType: CKOperationType {
    var previousServerChangeToken: CKServerChangeToken? { get set }
    var resultsLimit: Int { get set }

    var moreComing: Bool { get }
    var notificationChangedBlock: ((CKNotification) -> Void)? { get set }
    var fetchNotificationChangesCompletionBlock: ((CKServerChangeToken?, NSError?) -> Void)? { get set }
}

extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationType { }

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = CKNotification -> Void
    public typealias FetchNotificationChangesCompletionBlock = CKServerChangeToken? -> Void

    public var previousServerChangeToken: CKServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }

    public var moreComing: Bool {
        return operation.moreComing
    }

    public var notificationChangedBlock: ((CKNotification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock?) {
        guard let block = block else {
            configure = .None
            operation.fetchNotificationChangesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.previousServerChangeToken = self.operation.previousServerChangeToken
            op.resultsLimit = self.operation.resultsLimit
            op.notificationChangedBlock = self.operation.notificationChangedBlock
            op.fetchNotificationChangesCompletionBlock = { token, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(token)
                    self.finish()
                }
            }
            return op
        }
    }
}



