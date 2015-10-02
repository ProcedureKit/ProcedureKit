//
//  PhotosCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Photos

public protocol PhotosCapabilityRegistrarType: CapabilityRegistrarType {
    func opr_authorizationStatus() -> PHAuthorizationStatus
    func opr_requestAuthorization(handler: PHAuthorizationStatus -> Void)
}

extension PHPhotoLibrary: PhotosCapabilityRegistrarType {
    public func opr_authorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    public func opr_requestAuthorization(handler: PHAuthorizationStatus -> Void) {
        PHPhotoLibrary.requestAuthorization(handler)
    }
}

extension PHAuthorizationStatus: AuthorizationStatusType {

    public func isRequirementMet(requirement: Void) -> Bool {
        if case .Authorized = self {
            return true
        }
        return false
    }
}

public class _PhotosCapability<Registrar: PhotosCapabilityRegistrarType>: NSObject, CapabilityType {

    public let name: String
    public let requirement: Void

    let registrar: Registrar

    public required init(_ requirement: Void = (), registrar: Registrar = Registrar()) {
        self.name = "Photos"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    public func isAvailable() -> Bool {
        return true
    }

    public func authorizationStatus() -> PHAuthorizationStatus {
        return registrar.opr_authorizationStatus()
    }

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

extension Capability {
    public typealias Photos = _PhotosCapability<PHPhotoLibrary>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Photos())")
public typealias PhotosCondition = AuthorizedFor<Capability.Photos>

