//
//  CloudCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

public protocol CloudContainer {
    func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void)

/* Swift 2.0
    func accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void)
    func statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)
    func requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)
*/

    func accountStatusWithCompletionHandler(completionHandler: ((CKAccountStatus, NSError!) -> Void)!)
    func statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!)
    func requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!)
}

public struct CloudContainerCondition: OperationCondition {

    public enum Error: ErrorType {
        case NotAuthenticated
        case AccountStatusError(NSError?)
        case PermissionRequestRequired
        case PermissionStatusError(NSError?)
        case RequestPermissionError(NSError?)
    }

    internal class CloudKitPermissionsOperation: Operation {
        let container: CloudContainer
        let permissions: CKApplicationPermissions

        init(container: CloudContainer, permissions: CKApplicationPermissions) {
            self.container = container
            self.permissions = permissions
            super.init()

            if permissions & CKApplicationPermissions.PermissionUserDiscoverability != nil {
                // Requesting non-zero permissions will potentially
                // present a system alert.
                addCondition(AlertPresentation())
            }
        }

        override func execute() {
            container.verifyPermissions(permissions, requestPermissionIfNecessary: true) { error in
                self.finish(error)
            }
        }
    }

    public let name = "CloudContainer"
    public let isMutuallyExclusive = false

    let container: CloudContainer
    let permissions: CKApplicationPermissions

    public init(cloudKitContainer: CKContainer, permissions: CKApplicationPermissions = .allZeros) {
        self.container = cloudKitContainer
        self.permissions = permissions
    }

    public init(container: CloudContainer, permissions: CKApplicationPermissions = .allZeros) {
        self.container = container
        self.permissions = permissions
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return CloudKitPermissionsOperation(container: container, permissions: permissions)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        container.verifyPermissions(permissions, requestPermissionIfNecessary: false) { error in
            if let error = error {
                completion(.Failed(error))
            }
            else {
                completion(.Satisfied)
            }
        }
    }
}

extension CloudContainerCondition.Error: Equatable { }

public func ==(a: CloudContainerCondition.Error, b: CloudContainerCondition.Error) -> Bool {
    switch (a, b) {
    case (.NotAuthenticated, .NotAuthenticated):
        return true
    case let (.AccountStatusError(aError), .AccountStatusError(bError)):
        return aError == bError
    case    (.PermissionRequestRequired, .PermissionRequestRequired):
        return true
    case let (.PermissionStatusError(aError), .PermissionStatusError(bError)):
        return aError == bError
    case let (.RequestPermissionError(aError), .RequestPermissionError(bError)):
        return aError == bError
    default:
        return false
    }
}

extension CKContainer: CloudContainer {

    public func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void) {
        verifyAccountStatusForContainer(self, permissions, requestPermissionIfNecessary, completion)
    }
}

public func verifyAccountStatusForContainer(container: CloudContainer, permissions: CKApplicationPermissions, shouldRequest: Bool, completion: ErrorType? -> Void) {
    container.accountStatusWithCompletionHandler { (status, error) in
        
        switch status {
        
        case .Available:
            if permissions != nil {
                verifyPermissionsForContainer(container, permissions, shouldRequest, completion)
            }
            else {
                completion(.None)
            }

        case .NoAccount:
            completion(CloudContainerCondition.Error.NotAuthenticated)
        
        default:
            completion(CloudContainerCondition.Error.AccountStatusError(error))
        }        
    }
}

public func verifyPermissionsForContainer(container: CloudContainer, permissions: CKApplicationPermissions, shouldRequest: Bool, completion: ErrorType? -> Void) {
    container.statusForApplicationPermission(permissions) { (status, error) in
        switch (status, shouldRequest) {
        case (.Granted, _):
            completion(.None)
        case (.InitialState, true):
            requestPermissionsForContainer(container, permissions, completion)
        case (.InitialState, false):
            completion(CloudContainerCondition.Error.PermissionRequestRequired)
        default:
            completion(CloudContainerCondition.Error.PermissionStatusError(error))
        }
    }
}

public func requestPermissionsForContainer(container: CloudContainer, permissions: CKApplicationPermissions, completion: ErrorType? -> Void) {
    dispatch_async(Queue.Main.queue) {
        container.requestApplicationPermission(permissions) { (status, error) in
            if status == .Granted {
                completion(.None)
            }
            else {
                completion(CloudContainerCondition.Error.RequestPermissionError(error))
            }
        }
    }
}




