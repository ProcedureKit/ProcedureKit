//
//  CloudCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

internal protocol CloudContainer {
    func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void)
}

public struct CloudKitContainerCondition: OperationCondition {

    enum Error: ErrorType {
        case AccountStatusError(NSError?)
        case PermissionStatusError(NSError?)
        case RequestPermissionError(NSError?)
    }

    private class CloudKitPermissionsOperation: Operation {
        let container: CloudContainer
        let permissions: CKApplicationPermissions

        init(container: CloudContainer, permissions: CKApplicationPermissions) {
            self.container = container
            self.permissions = permissions
            super.init()

            if permissions != [] {
                // Requesting non-zero permissions will potentially
                // present a system alert.
                addCondition(SystemAlertPresentation())
            }
        }

        private override func execute() {
            container.verifyPermissions(permissions, requestPermissionIfNecessary: true) { error in
                self.finish(error)
            }
        }
    }

    public static let name = "CloudContainer"
    public static let isMutuallyExclusive = false

    let container: CloudContainer
    let permissions: CKApplicationPermissions

    public init(cloudKitContainer: CKContainer, permissions: CKApplicationPermissions = []) {
        self.container = cloudKitContainer
        self.permissions = permissions
    }

    internal init(container: CloudContainer, permissions: CKApplicationPermissions = []) {
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

extension CKContainer: CloudContainer {

    func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void) {
        verifyAccountStatusForContainer(self, permissions: permissions, shouldRequest: requestPermissionIfNecessary, completion: completion)
    }
}

private func verifyAccountStatusForContainer(container: CKContainer, permissions: CKApplicationPermissions, shouldRequest: Bool, completion: ErrorType? -> Void) {
    container.accountStatusWithCompletionHandler { (status, error) in
        if status == .Available {
            if permissions != [] {
                verifyPermissionsForContainer(container, permissions: permissions, shouldRequest: shouldRequest, completion: completion)
            }
            else {
                completion(.None)
            }
        }
        else {
            completion(CloudKitContainerCondition.Error.AccountStatusError(error))
        }
    }
}

private func verifyPermissionsForContainer(container: CKContainer, permissions: CKApplicationPermissions, shouldRequest: Bool, completion: ErrorType? -> Void) {
    container.statusForApplicationPermission(permissions) { (status, error) in
        if status == .Granted {
            completion(.None)
        }
        else if shouldRequest && status == .InitialState {

        }
        else {
            completion(CloudKitContainerCondition.Error.PermissionStatusError(error))
        }
    }
}

private func requestPermissionsForContainer(container: CKContainer, permissions: CKApplicationPermissions, completion: ErrorType? -> Void) {
    dispatch_async(Queue.Main.queue) {
        container.requestApplicationPermission(permissions) { (status, error) in
            if status == .Granted {
                completion(.None)
            }
            else {
                completion(CloudKitContainerCondition.Error.RequestPermissionError(error))
            }
        }
    }
}




