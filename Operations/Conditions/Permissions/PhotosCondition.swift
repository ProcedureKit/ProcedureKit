//
//  PhotosCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 10/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import Photos

public protocol PhotosManagerType {

    func authorizationStatus() -> PHAuthorizationStatus
    func requestAuthorization(handler: PHAuthorizationStatus -> Void)
}

struct SystemPhotoLibraryAuthenticationManager: PhotosManagerType {

    func authorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    func requestAuthorization(handler: PHAuthorizationStatus -> Void) {
        return PHPhotoLibrary.requestAuthorization(handler)
    }
}

public struct PhotosCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthorizationNotAuthorized(PHAuthorizationStatus)
    }

    public let name = "Photos Library"
    public let isMutuallyExclusive = false

    let manager: PhotosManagerType

    public init() {
        self.init(manager: SystemPhotoLibraryAuthenticationManager())
    }

    public init(manager: PhotosManagerType) {
        self.manager = manager
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return PhotosPermissionOperation(manager: manager)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let status = manager.authorizationStatus()
        switch status {
        case .Authorized:
            completion(.Satisfied)
        default:
            completion(.Failed(Error.AuthorizationNotAuthorized(status)))
        }
    }
}

extension PhotosCondition.Error: Equatable { }

public func ==(a: PhotosCondition.Error, b: PhotosCondition.Error) -> Bool {
    switch (a, b) {
    case let (.AuthorizationNotAuthorized(aStatus), .AuthorizationNotAuthorized(bStatus)):
        return aStatus == bStatus
    default:
        return false
    }
}

class PhotosPermissionOperation: Operation {

    let manager: PhotosManagerType

    init(manager: PhotosManagerType) {
        self.manager = manager
        super.init()
        addCondition(AlertPresentation())
    }

    override func execute() {
        switch manager.authorizationStatus() {
        case .NotDetermined:
            dispatch_async(Queue.Main.queue, request)
        default:
            finish()
        }
    }

    func request() {
        manager.requestAuthorization { status in
            self.finish()
        }
    }
}

#endif
