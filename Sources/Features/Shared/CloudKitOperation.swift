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

    internal private(set) var configure: (T -> Void)?

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
        defer { go() }
        guard let _ = configure else {
            let warning = "A completion block was not set for: \(operation.dynamicType), error handling will not be triggered."
            log.warning(warning)
            operation.addCompletionBlock {
                self.finish()
            }
            return
        }
    }

    private func go() {
        configure?(operation)
        produceOperation(operation)
    }

    func receivedError(error: ErrorType) {
        guard let op = recoverFromError(operation, error) else {
            finish(error)
            return
        }

        operation = op
        go()
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

        configure = { [unowned self] op in
            op.discoverAllContactsCompletionBlock = { userInfo, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfo)
                    self.finish()
                }
            }
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

        configure = { [unowned self] op in
            op.discoverUserInfosCompletionBlock = { userInfoByEmail, userInfoByRecordID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfoByEmail, userInfoByRecordID)
                    self.finish()
                }
            }
        }
    }
}


































// MARK: - Deprecated


public protocol CloudKitOperationType: class {
    var database: CKDatabase? { get set }
    func begin()
}

/**
    A very simple wrapper for CloudKit database operations.
    
    The database property is set on the operation, and suitable
    for execution on an `OperationQueue`. This means that 
    observers and conditions can be attached.
*/
public class _CloudKitOperation<CloudOperation where CloudOperation: CloudKitOperationType, CloudOperation: NSOperation>: Operation {

    public let operation: CloudOperation

    public init(operation: CloudOperation, database: CKDatabase = CKContainer.defaultContainer().privateCloudDatabase) {
        operation.database = database
        self.operation = operation
        super.init()
        name = "CloudKitOperation<\(operation.dynamicType)>"
    }

    public override func cancel() {
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        guard !cancelled else { return }
        operation.addCompletionBlock {
            self.finish()
        }
        operation.begin()
    }
}

extension CKDatabaseOperation: CloudKitOperationType {

    public func begin() {
        assert(database != nil, "CKDatabase not set on Operation.")
        database!.addOperation(self)
    }
}
