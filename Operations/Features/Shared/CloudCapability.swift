//
//  CloudCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import CloudKit

public struct CloudStatus: AuthorizationStatusType {

    public let account: CKAccountStatus
    public let permissions: CKApplicationPermissionStatus?
    public let error: NSError?

    init(account: CKAccountStatus, permissions: CKApplicationPermissionStatus? = .None, error: NSError? = .None) {
        self.account = account
        self.permissions = permissions
        self.error = error
    }

    public func isRequirementMet(requirement: CKApplicationPermissions) -> Bool {
        guard let _ = error else { return false }
        guard case .Available = account else { return false }

        switch (requirement, permissions) {
        case ([], _):
            return true
        case (_, .Some(.Granted)):
            return true
        default:
            return false
        }
    }
}

public protocol CloudContainerRegistrarType: CapabilityRegistrarType {

    static func containerWithIdentifier(identifier: String?) -> Self

    func opr_accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void)
    func opr_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)
    func opr_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)
}

public class _CloudCapability<Registrar: CloudContainerRegistrarType>: NSObject, CapabilityType {

    public let name: String
    public let requirement: CKApplicationPermissions

    var hasRequirements: Bool {
        return requirement != []
    }

    let registrar: Registrar

    public required init(_ requirement: CKApplicationPermissions = [], registrar: Registrar = Registrar()) {
        self.name = "Cloud"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    public func isAvailable() -> Bool {
        return true
    }

    public func authorizationStatus(completion: CloudStatus -> Void) {
        verifyAccountStatus(completion: completion)
    }

    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        verifyAccountStatus(true) { _ in
            completion()
        }
    }

    func verifyAccountStatus(shouldRequest: Bool = false, completion: CloudStatus -> Void) {
        registrar.opr_accountStatusWithCompletionHandler { status, error in
            switch (status, self.hasRequirements) {
            case (.Available, true):
                self.verifyPermissions(shouldRequest, completion: completion)
            default:
                completion(CloudStatus(account: status, permissions: .None, error: error))
            }
        }
    }

    func verifyPermissions(shouldRequest: Bool = false, completion: CloudStatus -> Void) {
        registrar.opr_statusForApplicationPermission(requirement) { status, error in
            switch (status, shouldRequest) {
            case (.InitialState, true):
                self.requestPermissionsWithCompletion(completion)
            default:
                completion(CloudStatus(account: .Available, permissions: status, error: error))
            }
        }
    }

    func requestPermissionsWithCompletion(completion: CloudStatus -> Void) {
        dispatch_async(Queue.Main.queue) {
            self.registrar.opr_requestApplicationPermission(self.requirement) { status, error in
                completion(CloudStatus(account: .Available, permissions: status, error: error))
            }
        }
    }

}

public class CloudCapability<Registrar: CloudContainerRegistrarType>: _CloudCapability<Registrar> {
    public init(permissions: CKApplicationPermissions = [], containerId: String? = .None) {
        super.init(permissions, registrar: Registrar.containerWithIdentifier(containerId))
    }
}

public final class CloudContainer: NSObject, CloudContainerRegistrarType {

    public static func containerWithIdentifier(identifier: String?) -> CloudContainer {
        let container = CloudContainer()
        if let id = identifier {
            container.container = CKContainer(identifier: id)
        }
        return container
    }

    var container = CKContainer.defaultContainer()

    public func opr_accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void) {
        container.accountStatusWithCompletionHandler(completionHandler)
    }

    public func opr_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        container.statusForApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }

    public func opr_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        container.requestApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }
}

extension Capability {
    public typealias Cloud = CloudCapability<CloudContainer>
}

@available(*, unavailable, renamed="AuthorizedFor(Cloud())")
public typealias CloudContainerCondition = AuthorizedFor<Capability.Cloud>






