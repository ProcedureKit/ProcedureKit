//
//  CloudKitOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

public protocol CloudKitOperationType: class {
    var database: CKDatabase! { get set }
}

/**
    A very simple wrapper for CloudKit database operations.
    
    The database property is set on the operation, and suitable
    for execution on an `OperationQueue`. This means that 
    observers and conditions can be attached.
*/
public class CloudKitOperation<CloudOperation where CloudOperation: CloudKitOperationType, CloudOperation: NSOperation>: GroupOperation {

    public let operation: CloudOperation

    public init(var operation: CloudOperation, database: CKDatabase = CKContainer.defaultContainer().privateCloudDatabase, completion: dispatch_block_t = { }) {
        operation.database = database
        let finished = NSBlockOperation(block: completion)
        finished.addDependency(operation)
        self.operation = operation
        super.init(operations: [operation, finished])
    }
}

extension CKDatabaseOperation: CloudKitOperationType {}
