//
//  CloudCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
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
public struct CloudStatus: AuthorizationStatusType {

    /// - returns: the CKAccountStatus
    public let account: CKAccountStatus

    /// - returns: the CKApplicationPermissionStatus?
    public let permissions: CKApplicationPermissionStatus?

    /// - returns: any NSError?
    public let error: NSError?

    init(account: CKAccountStatus, permissions: CKApplicationPermissionStatus? = .None, error: NSError? = .None) {
        self.account = account
        self.permissions = permissions
        self.error = error
    }

    /**
     Determine whether the application permissions have been met.
     This method takes into account, any errors received from CloudKit,
     the account status, application permission status, and the required
     application permissions.
    */
    public func isRequirementMet(requirement: CKApplicationPermissions) -> Bool {
        if let _ = error {
            return false
        }

        switch (requirement, account, permissions) {
        case ([], .Available, _):
            return true
        case (_, .Available, .Some(.Granted)) where requirement != []:
            return true
        default:
            return false
        }
    }
}

/**
 A refined CapabilityRegistrarType for Capability.Cloud. This
 protocol defines two functions which the registrar uses to get
 the current authorization status and request access.
*/
public protocol CloudContainerRegistrarType: CapabilityRegistrarType {

    /**
     Provide an instance of Self with the given identifier. This is
     because we need to determined the capability of a specific cloud 
     kit container.
    */
    static func containerWithIdentifier(identifier: String?) -> Self

    /**
     Get the account status, a CKAccountStatus.

     - parameter completionHandler: a completion handler which receives the account status.
     */
    func opr_accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void)

    /**
     Get the application permission, a CKApplicationPermissions.

     - parameter applicationPermission: the CKApplicationPermissions
     - parameter completionHandler: a CKApplicationPermissionBlock closure
     */
    func opr_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)

    /**
     Request the application permission, a CKApplicationPermissions.

     - parameter applicationPermission: the CKApplicationPermissions
     - parameter completionHandler: a CKApplicationPermissionBlock closure
     */
    func opr_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock)
}

/**
The Cloud capability, which generic over CloudContainerRegistrarType.
 
 Framework consumers should not use this directly, but instead
 use Capability.Cloud. So that its usage is like this:

 ```swift

 GetAuthorizationStatus(Capability.Cloud()) { status in
    // check the status etc.
 }
 ```

 - see: Capability.Cloud
*/
public class _CloudCapability<Registrar: CloudContainerRegistrarType>: NSObject, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: a CKApplicationPermissions, the required permissions for the container
    public let requirement: CKApplicationPermissions

    var hasRequirements: Bool {
        return requirement != []
    }

    let registrar: Registrar

    /**
     Initialize the capability. By default, it requires no extra application permissions.

     Note that framework consumers should not initialized this class directly, but instead
     use Capability.Cloud, which is a typealias of CloudCapability, and has a slightly 
     different initializer to allow supplying the CloudKit container identifier.

     - see: Capability.Cloud
     - see: CloudCapability

     - parameter requirement: the required EKEntityType, defaults to .Event
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: CKApplicationPermissions = [], registrar: Registrar = Registrar()) {
        self.name = "Cloud"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    /// - returns: true, CloudKit is always available
    public func isAvailable() -> Bool {
        return true
    }

    /**
     Get the current authorization status of CloudKit from the Registrar.
     - parameter completion: a CloudStatus -> Void closure.
     */
    public func authorizationStatus(completion: CloudStatus -> Void) {
        verifyAccountStatus(completion: completion)
    }

    /**
     Requests authorization to the Cloud Kit container from the Registrar.
     - parameter completion: a dispatch_block_t
     */
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

/**
 CloudCapability provides an initializer which allows the consumer to provide a
 cloud kit container identifier.
*/
public class CloudCapability<Registrar: CloudContainerRegistrarType>: _CloudCapability<Registrar> {

    /**
     Initialize the CloudCapability with permissions and optionally a specific
     CKContainer identifier.

     - parameter permissions: the CKApplicationPermissions, defaults to empty set.
     - parameter containerId: an String?, defaults to .None which corresponds to the default CKContainer.
    */
    public init(permissions: CKApplicationPermissions = [], containerId: String? = .None) {
        super.init(permissions, registrar: Registrar.containerWithIdentifier(containerId))
    }
}

/**
 A registrar for CKContainer.
*/
public final class CloudContainerRegistrar: NSObject, CloudContainerRegistrarType {

    /// Provide a CloudContainerRegistrar for a CKContainer with the given identifier.
    public static func containerWithIdentifier(identifier: String?) -> CloudContainerRegistrar {
        let container = CloudContainerRegistrar()
        if let id = identifier {
            container.cloudKitContainer = CKContainer(identifier: id)
        }
        return container
    }

    private(set) var cloudKitContainer: CKContainer = CKContainer.defaultContainer()

    /**
     Get the account status, a CKAccountStatus.

     - parameter completionHandler: a completion handler which receives the account status.
     */
    public func opr_accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void) {
        cloudKitContainer.accountStatusWithCompletionHandler(completionHandler)
    }

    /**
     Get the application permission, a CKApplicationPermissions.

     - parameter applicationPermission: the CKApplicationPermissions
     - parameter completionHandler: a CKApplicationPermissionBlock closure
     */
    public func opr_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        cloudKitContainer.statusForApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }

    /**
     Request the application permission, a CKApplicationPermissions.

     - parameter applicationPermission: the CKApplicationPermissions
     - parameter completionHandler: a CKApplicationPermissionBlock closure
     */
    public func opr_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
        cloudKitContainer.requestApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }
}

extension Capability {

    /**
     # Capability.Cloud
     
     This type represents the app's permission to access a particular CKContainer.
     
     For framework consumers - use with `GetAuthorizationStatus`, `Authorize` and
     `AuthorizedFor`. 
     
     For example, authorize usage of the default container
     
     ```swift
     Authorize(Capability.Cloud()) { available, status in
        // etc
     }
     ```

     For example, authorize usage of another container;
     
     ```swift
     Authorize(Capability.Cloud(containerId: "iCloud.com.myapp.my-container-id")) { available, status in
        // etc
     }
     ```
    */
    public typealias Cloud = CloudCapability<CloudContainerRegistrar>
}

extension CloudCapability where Registrar: CloudContainerRegistrar {

    /// - returns: the `CKContainer`
    public var container: CKContainer {
        return registrar.cloudKitContainer
    }
}

@available(*, unavailable, renamed="AuthorizedFor(Cloud())")
public typealias CloudContainerCondition = AuthorizedFor<Capability.Cloud>






