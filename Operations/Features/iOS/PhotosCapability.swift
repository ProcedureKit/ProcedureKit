//
//  PhotosCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Photos

/**
 A refined CapabilityRegistrarType for Capability.Photos. This
 protocol defines two functions which the registrar uses to get
 the current authorization status and request access.
*/
public protocol PhotosCapabilityRegistrarType: CapabilityRegistrarType {

    /// - returns: the current PHAuthorizationStatus
    func opr_authorizationStatus() -> PHAuthorizationStatus

    /**
     Request authorization to photos.
     - parameter handler: a PHAuthorizationStatus -> Void closure
    */
    func opr_requestAuthorization(handler: PHAuthorizationStatus -> Void)
}

extension PHPhotoLibrary: PhotosCapabilityRegistrarType {

    /// - returns: the current PHAuthorizationStatus
    public func opr_authorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    /**
     Request authorization to photos.
     - parameter handler: a PHAuthorizationStatus -> Void closure
     */
    public func opr_requestAuthorization(handler: PHAuthorizationStatus -> Void) {
        PHPhotoLibrary.requestAuthorization(handler)
    }
}

extension PHAuthorizationStatus: AuthorizationStatusType {

    /// - returns: true if authorization was granted. There are no requirements.
    public func isRequirementMet(requirement: Void) -> Bool {
        if case .Authorized = self {
            return true
        }
        return false
    }
}

/**
 The Photos capability, which is generic over an PhotosCapabilityRegistrarType.

 Framework consumers should not use this directly, but instead
 use Capability.Photos. So that its usage is like this:

 ```swift

 GetAuthorizationStatus(Capability.Photos()) { status in
    // check the status etc.
 }
 ```

 - see: Capability.Photos
 */
public class _PhotosCapability<Registrar: PhotosCapabilityRegistrarType>: NSObject, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: the EKEntityType, the required type of the capability
    public let requirement: Void

    let registrar: Registrar

    /**
     Initialize the capability. There is no requirement type

     - parameter requirement: Void - defaults to ()
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: Void = (), registrar: Registrar = Registrar()) {
        self.name = "Photos"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    /// - returns: true, Photos is always available
    public func isAvailable() -> Bool {
        return true
    }

    /**
     Get the current authorization status of Photos from the Registrar.
     - parameter completion: a PHAuthorizationStatus -> Void closure.
     */
    public func authorizationStatus(completion: PHAuthorizationStatus -> Void) {
        completion(registrar.opr_authorizationStatus())
    }

    /**
     Request authorization to Photos from the Registrar.
     - parameter completion: a dispatch_block_t
     */
    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        switch registrar.opr_authorizationStatus() {
        case .NotDetermined:
            registrar.opr_requestAuthorization { _ in
                completion()
            }
        default:
            completion()
        }
    }
}

public extension Capability {

    /**
     # Capability.Photos

     This type represents the app's permission to access the Photo library.

     For framework consumers - use with `GetAuthorizationStatus`, `Authorize` and
     `AuthorizedFor`. For example

     Get the current authorization status for accessing the user's photo library:

     ```swift
     GetAuthorizationStatus(Capability.Photos()) { available, status in
        // etc
     }
     ```
     */
    typealias Photos = _PhotosCapability<PHPhotoLibrary>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Photos())")
public typealias PhotosCondition = AuthorizedFor<Capability.Photos>

