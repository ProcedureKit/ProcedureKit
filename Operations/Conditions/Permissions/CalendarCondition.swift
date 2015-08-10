//
//  CalendarCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import EventKit

public protocol EventKitAuthorizationManagerType {
    func authorizationStatusForEntityType(entityType: EKEntityType) -> EKAuthorizationStatus
    func requestAccessToEntityType(entityType: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler)
}

private struct EventKitAuthorizationManager: EventKitAuthorizationManagerType {

    var store = EKEventStore()

    func authorizationStatusForEntityType(entityType: EKEntityType) -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatusForEntityType(entityType)
    }

    func requestAccessToEntityType(entityType: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler) {
        store.requestAccessToEntityType(entityType, completion: completion)
    }
}

public struct CalendarCondition: OperationCondition {

    public enum Error: ErrorType {
        case AuthorizationFailed(status: EKAuthorizationStatus)
    }

    public let name = "Calendar"
    public let isMutuallyExclusive = false

    let entityType: EKEntityType
    let manager: EventKitAuthorizationManagerType

    public init(type: EKEntityType) {
        self.init(type: type, authorizationManager: EventKitAuthorizationManager())
    }

    /** 
        Testing Interface
        Instead use
            init(type: EKEntityType)
    */
    public init(type: EKEntityType, authorizationManager: EventKitAuthorizationManagerType) {
        entityType = type
        manager = authorizationManager
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return CalendarPermissionOperation(type: entityType, authorizationManager: manager)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let status = manager.authorizationStatusForEntityType(entityType)
        switch status {
        case .Authorized:
            completion(.Satisfied)
        default:
            completion(.Failed(Error.AuthorizationFailed(status: status)))
        }
    }
}

public func ==(a: CalendarCondition.Error, b: CalendarCondition.Error) -> Bool {
    switch (a, b) {
    case let (.AuthorizationFailed(aStatus), .AuthorizationFailed(bStatus)):
        return aStatus == bStatus
    default:
        return false
    }
}

class CalendarPermissionOperation: Operation {

    let entityType: EKEntityType
    let manager: EventKitAuthorizationManagerType

    init(type: EKEntityType, authorizationManager: EventKitAuthorizationManagerType = EventKitAuthorizationManager()) {
        entityType = type
        manager = authorizationManager
    }

    override func execute() {
        switch manager.authorizationStatusForEntityType(entityType) {
        case .NotDetermined:
            dispatch_async(Queue.Main.queue, request)
        default:
            finish()
        }
    }

    func request() {
        manager.requestAccessToEntityType(entityType) { (granted, error) in
            self.finish()
        }
    }

}


