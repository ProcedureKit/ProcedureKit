//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
import CloudKit

// MARK: - Batch Processing

/// An error protocol for batch processing operations
public protocol CloudKitBatchProcessError: CloudKitError {
    associatedtype Process

    var processed: [Process]? { get }
}

// MARK: - Batch Processing

/// A protocol for batch processing operations
public protocol CloudKitBatchProcessOperation: CKOperationProtocol {
    associatedtype Process
    associatedtype AssociatedError: CloudKitBatchProcessError

    var toProcess: [Process]? { get set }
}

// MARK: - Batch Modification

/// An error protocol for batch modifying operations
public protocol CloudKitBatchModifyError: CloudKitError {
    associatedtype Save
    associatedtype Delete

    var saved: [Save]? { get }
    var deleted: [Delete]? { get }
}

public protocol CloudKitBatchModifyOperation: CKOperationProtocol {
    associatedtype Save
    associatedtype Delete
    associatedtype AssociatedError: CloudKitBatchModifyError

    var toSave: [Save]? { get set }
    var toDelete: [Delete]? { get set }
}
