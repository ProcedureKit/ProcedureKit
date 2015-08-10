//
//  HealthCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 10/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import HealthKit

public protocol HealthManagerType {

    func opr_isHealthDataAvailable() -> Bool

    func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus

    func opr_requestAuthorizationToShareTypes(typesToShare: Set<HKSampleType>?, readTypes typesToRead: Set<HKObjectType>?, completion: (Bool, NSError?) -> Void)
}

extension HKHealthStore: HealthManagerType {

    public func opr_isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    public func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatusForType(type)
    }

    public func opr_requestAuthorizationToShareTypes(typesToShare: Set<HKSampleType>?, readTypes typesToRead: Set<HKObjectType>?, completion: (Bool,   NSError?) -> Void) {
        requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead, completion: completion)
    }
}

public struct HealthCondition: OperationCondition {

    public enum Error: ErrorType {
        case HealthDataNotAvailable
        case UnauthorizedShareTypes(Set<HKSampleType>)
    }

    public let name = "Health Condition"
    public let isMutuallyExclusive = false

    let readTypes: Set<HKSampleType>
    let shareTypes: Set<HKSampleType>
    let manager: HealthManagerType

    public init(typesToRead: Set<HKSampleType> = Set(), typesToWrite: Set<HKSampleType> = Set()) {
        self.init(manager: HKHealthStore(), typesToRead: typesToRead, typesToWrite: typesToWrite)
    }

    public init(manager: HealthManagerType, typesToRead: Set<HKSampleType> = Set(), typesToWrite: Set<HKSampleType> = Set()) {
        self.manager = manager
        self.readTypes = typesToRead
        self.shareTypes = typesToWrite
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        if manager.opr_isHealthDataAvailable() && (!readTypes.isEmpty || !shareTypes.isEmpty) {
            return HealthPermissionOperation(manager: manager, typesToRead: readTypes, typesToShare: shareTypes)
        }
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if !manager.opr_isHealthDataAvailable() {
            completion(.Failed(Error.HealthDataNotAvailable))
            return
        }

        /**
            We don't actually test for unauthorized read access, as this
            reveals sensetive information.
        */

        let unauthorizedShareTypes = filter(shareTypes) { type in
            return self.manager.opr_authorizationStatusForType(type) != .SharingAuthorized
        }

        if !unauthorizedShareTypes.isEmpty {
            completion(.Failed(Error.UnauthorizedShareTypes(Set(unauthorizedShareTypes))))
        }
        else {
            completion(.Satisfied)
        }
    }
}

extension HealthCondition.Error: Equatable { }

public func ==(a: HealthCondition.Error, b: HealthCondition.Error) -> Bool {
    switch (a, b) {
    case (.HealthDataNotAvailable, .HealthDataNotAvailable):
        return true
    case let (.UnauthorizedShareTypes(aTypes), .UnauthorizedShareTypes(bTypes)):
        return aTypes == bTypes
    default: return false
    }
}

class HealthPermissionOperation: Operation {

    let typesToRead: Set<HKSampleType>
    let typesToShare: Set<HKSampleType>
    let manager: HealthManagerType

    init(manager: HealthManagerType, typesToRead: Set<HKSampleType>, typesToShare: Set<HKSampleType>) {
        self.manager = manager
        self.typesToRead = typesToRead
        self.typesToShare = typesToShare
        super.init()
        addCondition(MutuallyExclusive<HealthPermissionOperation>())
        addCondition(MutuallyExclusive<UIViewController>())
        addCondition(AlertPresentation())
    }

    override func execute() {
        dispatch_async(Queue.Main.queue, request)
    }

    func request() {
        manager.opr_requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { (completed, error) in
            self.finish()
        }
    }
}

#endif

