//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import CloudKit

/// An error protocol for CloudKit errors.
public protocol CloudKitError: Error {

    /// - returns: the original NSError received from CloudKit
    var underlyingError: Error { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

/// Public extensions to extract useful error information
public extension CloudKitError {

    internal var underlyingNSError: NSError {
        return underlyingError as NSError
    }

    /// - returns: the CKErrorCode if possible
    var code: CKError.Code? {
        return CKError.Code(rawValue: underlyingNSError.code)
    }

    /// - returns: an optional Delay, if the underlying error's user info contains CKErrorRetryAfterKey
    var retryAfterDelay: Delay? {
        return (underlyingNSError.userInfo[CKErrorRetryAfterKey] as? NSNumber).flatMap { .by($0.doubleValue) }
    }
}

// MARK: - Concrete types

public struct PKCKError: CloudKitError {
    public let underlyingError: Error
}

// MARK: - Batch error handling

internal extension Array where Element: Equatable {

    func bisect() -> (left: [Element], right: [Element]) {
        let half = count / 2
        return (Array(prefix(upTo: half)), Array(suffix(from: half)))
    }
}

public extension CloudKitBatchModifyOperation where Save: Equatable, Save == AssociatedError.Save, Delete: Equatable, Delete == AssociatedError.Delete {

    typealias ToModify = (toSave: [Save]?, toDelete: [Delete]?)
    typealias ToModifyResponse = (left: ToModify, right: ToModify)

    internal func bisect(error: AssociatedError) -> ToModifyResponse {
        var left: ToModify = (nil, nil)
        var right: ToModify = (nil, nil)

        let remainingToSave = toSave?.filter { !(error.saved?.contains($0) ?? false ) }
        let remainingToDelete = toDelete?.filter { !(error.deleted?.contains($0) ?? false ) }

        if let bisectedToSave = remainingToSave.map({ $0.bisect() }) {
            left.toSave = bisectedToSave.left
            right.toSave = bisectedToSave.right
        }

        if let bisectedToDelete = remainingToDelete.map({ $0.bisect() }) {
            left.toDelete = bisectedToDelete.left
            right.toDelete = bisectedToDelete.right
        }

        return (left, right)
    }
}

public extension CloudKitProcedure where T: CloudKitBatchModifyOperation, T.Save: Equatable, T.Save == T.AssociatedError.Save, T.Delete: Equatable, T.Delete == T.AssociatedError.Delete {

    typealias ToModifyResponse = T.ToModifyResponse

    func setErrorHandlerForLimitExceeded(_ handler: @escaping (T.AssociatedError, LoggerProtocol, ToModifyResponse) -> ToModifyResponse? = { $2 }) {
        set(errorHandlerForCode: .limitExceeded) { [weak self] operation, error, log, suggested in

            guard let strongSelf = self else { return nil }

            log.warning(message: "Received CloudKit Limit Exceeded error: \(error)")

            // Execute the handler
            guard let response = handler(error, log, operation.bisect(error: error)) else { return nil }

            // Create a new procedure for the left hand bisect of the remaining data
            let lhs = CloudKitProcedure { T() }

            // Setup basic configuration such as container & database
            lhs.append(configureBlock: suggested.configure)

            // Set the error handlers
            lhs.set(errorHandlers: strongSelf.errorHandlers)

            // Set the modifications to perform
            lhs.toSave = response.left.toSave
            lhs.toDelete = response.left.toDelete

            // Setup the configuration block for the right hand side
            // which is the original procedure which will be re-tried
            let configure = { (rhs: CKProcedure<T>) in

                // Set the suggested configuration
                suggested.configure(rhs)

                // Set the modifications to perform
                rhs.toSave = response.right.toSave
                rhs.toDelete = response.right.toDelete

                // Set the left half as a dependency
                rhs.add(dependency: lhs)
            }

            // Add the left hand side procedure to the group
            strongSelf.add(child: lhs)

            return (suggested.delay, configure)
        }
    }
}

public extension CloudKitBatchProcessOperation where Process: Equatable, Process == AssociatedError.Process {

    typealias ToProcessResponse = (left: [Process]?, right: [Process]?)

    func bisect(error: AssociatedError) -> ToProcessResponse {
        var left: [Process]? = nil
        var right: [Process]? = nil

        let remainingToProcess = toProcess?.filter { !(error.processed?.contains($0) ?? false) }

        if let bisectedToProcess = remainingToProcess.map({ $0.bisect() }) {
            left = bisectedToProcess.left
            right = bisectedToProcess.right
        }

        return (left, right)
    }
}

public extension CloudKitProcedure where T: CloudKitBatchProcessOperation, T.Process: Equatable, T.Process == T.AssociatedError.Process {

    typealias ToProcessResponse = T.ToProcessResponse

    func setErrorHandlerForLimitExceeded(_ handler: @escaping (T.AssociatedError, LoggerProtocol, ToProcessResponse) -> ToProcessResponse? = { $2 }) {
        set(errorHandlerForCode: .limitExceeded) { [weak self] operation, error, log, suggested in

            guard let strongSelf = self else { return nil }

            log.warning(message: "Received CloudKit Limit Exceeded error: \(error)")

            // Execute the handler
            guard let response = handler(error, log, operation.bisect(error: error)) else { return nil }

            // Create a new procedure for the left hand bisect of the remaining data
            let lhs = CloudKitProcedure { T() }

            // Setup basic configuration such as container & database
            lhs.append(configureBlock: suggested.configure)

            // Set the error handlers
            lhs.set(errorHandlers: strongSelf.errorHandlers)

            // Set the modifications to perform
            lhs.toProcess = response.left

            // Setup the configuration block for the right hand side
            // which is the original procedure which will be re-tried
            let configure = { (rhs: CKProcedure<T>) in

                // Set the suggested configuration
                suggested.configure(rhs)

                // Set the modifications to perform
                rhs.toProcess = response.right

                // Set the left half as a dependency
                rhs.add(dependency: lhs)
            }

            // Add the left hand side procedure to the group
            strongSelf.add(child: lhs)

            return (suggested.delay, configure)
        }
    }
}
