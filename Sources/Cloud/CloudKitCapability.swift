//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/**
 # Cloud Status

 Value represents the current CloudKit status for the user.

 CloudKit has a relatively convoluted status API.

 First, we must check the user's accout status, i.e. are
 they logged in to iCloud.

 Next, we check the status for the application permissions.

 Then, we might need to request the application permissions.
 */
public struct CloudKitStatus: AuthorizationStatus {

    public typealias Requirement = CKApplicationPermissions

    /// - returns: the CKAccountStatus
    public let account: CKAccountStatus

    /// - returns: the CKApplicationPermissionStatus?
    public let permissions: CKApplicationPermissionStatus?

    /// - returns: any NSError?
    public let error: Error?

    /**
     Determine whether the application permissions have been met.
     This method takes into account, any errors received from CloudKit,
     the account status, application permission status, and the required
     application permissions.
     */
    public func meets(requirement: CKApplicationPermissions?) -> Bool {
        guard error == nil else { return false }

        guard let requirement = requirement else {
            return account == .available
        }

        switch (requirement, account, permissions) {
        case ([], .available, _):
            return true
        case (_, .available, .some(.granted)) where requirement != []:
            return true
        default:
            return false
        }
    }
}

extension Capability {

    public class CloudKit: CapabilityProtocol {

        public private(set) var requirement: CKApplicationPermissions?

        internal let containerId: String?

        internal var storedRegistrar: CloudKitContainerRegistrar? = nil
        internal var registrar: CloudKitContainerRegistrar {
            get {
                storedRegistrar = storedRegistrar ?? containerId.map { CKContainer(identifier: $0) } ?? CKContainer.default()
                return storedRegistrar!
            }
        }

        public init(_ requirement: CKApplicationPermissions? = nil, containerId: String? = nil) {
            self.requirement = requirement
            self.containerId = containerId
        }

        public func isAvailable() -> Bool {
            return true
        }

        public func getAuthorizationStatus(_ completion: @escaping (CloudKitStatus) -> Void) {
            verifyAccountStatus(completion: completion)
        }

        public func requestAuthorization(withCompletion completion: @escaping () -> Void) {
            verifyAccountStatus(andPermissions: true, completion: { _ in completion() })
        }

        func verifyAccountStatus(andPermissions shouldVerifyAndRequestPermissions: Bool = false, completion: @escaping (CloudKitStatus) -> Void) {
            let hasRequirements = requirement.map { $0 != [] } ?? false
            registrar.pk_accountStatus { [weak self] accountStatus, error in
                switch (accountStatus, hasRequirements) {
                case (.available, true):
                    self?.verifyApplicationPermissions(andRequestPermission: shouldVerifyAndRequestPermissions, completion: completion)
                default:
                    completion(CloudKitStatus(account: accountStatus, permissions: nil, error: error))
                }
            }
        }

        func verifyApplicationPermissions(andRequestPermission shouldRequestPermission: Bool = false, completion: @escaping (CloudKitStatus) -> Void) {
            registrar.pk_status(forApplicationPermission: requirement!) { [weak self] permissionStatus, error in
                switch (permissionStatus, shouldRequestPermission) {
                case (.initialState, true):
                    self?.requestPermissions(withCompletion: completion)
                default:
                    completion(CloudKitStatus(account: .available, permissions: permissionStatus, error: error))
                }
            }
        }

        func requestPermissions(withCompletion completion: @escaping (CloudKitStatus) -> Void) {
            DispatchQueue.main.async {
                self.registrar.pk_requestApplicationPermission(self.requirement!) { permissionStatus, error in
                    completion(CloudKitStatus(account: .available, permissions: permissionStatus, error: error))
                }
            }
        }
    }
}
