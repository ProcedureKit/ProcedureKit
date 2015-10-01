//
//  Authorization.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation

// MARK: CapabilityType

public protocol AuthorizationStatusType {
    typealias Requirement

    func isRequirementMet(requirement: Requirement) -> Bool
}

public protocol CapabilityRegistrarType {
    init()
}

public protocol CapabilityType {
    typealias Registrar: CapabilityRegistrarType
    typealias Status: AuthorizationStatusType

    var name: String { get }
    var requirement: Status.Requirement { get }

    init(_ requirement: Status.Requirement, registrar: Registrar)
    func isAvailable() -> Bool
    func authorizationStatus() -> Status
    func requestAuthorizationWithCompletion(completion: dispatch_block_t)
}

// MARK: - Operations

public class GetAuthorizationStatus<Capability: CapabilityType>: Operation {

    public typealias Completion = (Bool, Capability.Status) -> Void

    public var isAvailable: Bool? = .None
    public var status: Capability.Status? = .None

    let capability: Capability
    let completion: Completion?

    public init(_ capability: Capability, completion: Completion? = .None) {
        self.capability = capability
        self.completion = completion
        super.init()
        name = "Get Authorization Status for: \(capability.name)"
    }

    public override func execute() {
        let available = capability.isAvailable()
        let status = capability.authorizationStatus()
        self.isAvailable = available
        self.status = status
        completion?(available, status)
        finish()
    }
}

public class Authorize<Capability: CapabilityType>: Operation {

    let capability: Capability

    public init(capability: Capability) {
        self.capability = capability
        super.init()
        name = "Authorize \(capability.requirement) for: \(capability.name)"
        addCondition(AlertPresentation())
    }

    public override func execute() {
        capability.requestAuthorizationWithCompletion {
            self.finish()
        }
    }
}

// MARK: - Condition

public enum CapabilityError<Capability: CapabilityType>: ErrorType {
    case NotAvailable
    case AuthorizationNotGranted((Capability.Status, Capability.Status.Requirement?))
}

public struct AuthorizedFor<Capability: CapabilityType>: OperationCondition {

    public let name: String
    public let isMutuallyExclusive = false

    let capability: Capability

    public init(_ capability: Capability) {
        self.capability = capability
        self.name = capability.name
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return Authorize(capability: capability)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {

        let status = capability.authorizationStatus()

        if !capability.isAvailable() {
            completion(.Failed(CapabilityError<Capability>.NotAvailable))
        }
        else if status.isRequirementMet(capability.requirement) {
            completion(.Satisfied)
        }
        else {
            completion(.Failed(CapabilityError<Capability>.AuthorizationNotGranted((status, capability.requirement))))
        }
    }
}








