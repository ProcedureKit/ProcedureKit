//
//  CloudKitError.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/04/2016.
//
//

import Foundation
import CloudKit

/// An error type for CloudKit errors.
public protocol CloudKitErrorType: ErrorType {

    /// - returns: the original NSError received from CloudKit
    var underlyingError: NSError { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

public extension CloudKitErrorType {

    var code: CKErrorCode? {
        return CKErrorCode(rawValue: underlyingError.code)
    }

    var retryAfterDelay: Delay? {
        return (underlyingError.userInfo[CKErrorRetryAfterKey] as? NSNumber).map { Delay.By($0.doubleValue) }
    }
}

public protocol BatchModifyErrorType: CloudKitErrorType {
    associatedtype Save
    associatedtype Delete

    var saved: [Save]? { get }
    var deleted: [Delete]? { get }
}

public protocol BatchProcessErrorType: CloudKitErrorType {
    associatedtype Process

    var processed: [Process]? { get }
}

public struct CloudKitError: CloudKitErrorType {

    public let underlyingError: NSError

    init(error: NSError) {
        underlyingError = error
    }
}



// MARK: - Batch Modify Error Handling

public extension CloudKitOperation where T: BatchModifyOperationType, T.Save == T.Error.Save, T.Save: Equatable, T.Delete == T.Error.Delete, T.Delete: Equatable {

    typealias ToModify = (toSave: [T.Save]?, toDelete: [T.Delete]?)
    typealias ToModifyResponse = (left: ToModify, right: ToModify)

    func setErrorHandlerForLimitExceeded(handler: (error: T.Error, log: LoggerType, suggested: ToModifyResponse) -> ToModifyResponse? = { $2 }) {
        setErrorHandlerForCode(.LimitExceeded) { [unowned self] error, log, suggested in

            log.warning("Received CloudKit Limit Exceeded error: \(error)")

            var left: ToModify = (.None, .None)
            var right: ToModify = (.None, .None)

            let remainingToSave = self.operation.toSave?.filter { error.saved?.contains($0) ?? false }
            if let toSave = remainingToSave {
                let numberOfToSave = toSave.count
                left.toSave = Array(toSave.prefixUpTo(numberOfToSave/2))
                right.toSave = Array(toSave.suffixFrom(numberOfToSave/2))
            }

            let remainingToDelete = self.operation.toDelete?.filter { error.deleted?.contains($0) ?? false }
            if let toDelete = remainingToDelete {
                let numberToDelete = toDelete.count
                left.toDelete = Array(toDelete.prefixUpTo(numberToDelete/2))
                right.toDelete = Array(toDelete.suffixFrom(numberToDelete/2))
            }

            // Execute the handler, and guard against a nil response
            guard let response = handler(error: error, log: log, suggested: (left: left, right: right)) else {
                return .None
            }

            // Create a new operation to bisect the remaining data
            let lhs: CloudKitOperation<T> = CloudKitOperation { T() }

            lhs.toSave = response.left.toSave
            lhs.toDelete = response.left.toDelete

            // Setup basic configuration such as container & database
            lhs.addConfigureBlock(suggested.configure)

            // Set error handlers
            lhs.setErrorHandlers(self.errorHandlers)
            lhs.setErrorHandlerForLimitExceeded(handler)

            let configure = { (rhs: OPRCKOperation<T>) in

                // Set the suggest configuration to rhs, will include container, database etc
                suggested.configure(rhs)

                // Set the properies for the subscriptions to save/delete
                rhs.toSave = response.right.toSave
                rhs.toDelete = response.right.toDelete

                // Set the left half as dependency
                rhs.addDependency(lhs)
            }

            // Add the lhs operation as a child of the original operation
            self.addOperation(lhs)

            return (suggested.delay, configure)
        }
    }
}

public extension CloudKitOperation where T: BatchProcessOperationType {

}
