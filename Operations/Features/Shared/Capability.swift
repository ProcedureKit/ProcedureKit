//
//  Capability.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation

/**

 # CapabilityType
 
 This is the high level definition for device/user/system
 capabilities which typically would require the user's
 permission to access. For example, location, calendars,
 photos, health kit etc.
*/
public protocol CapabilityType {

    /// A type which performs the registration of capability permissions.
    typealias Registrar: CapabilityRegistrarType

    /// A type which indicates the current status of the capability
    typealias Status: AuthorizationStatusType

    /// - returns: a String, the name of the capability
    var name: String { get }

    /**
     A requirement of the capability. This is generic, and it
     allows for granuality in the capabilities permissions.
     For example, with Location, we either request a "when in use"
     or "always" permission.
     
     - returns: the necessary Status.Requirement
    */
    var requirement: Status.Requirement { get }

    /**
     Initialize a new capability with the requirement and a registrar.
     
     Implementations should provide a default registrar - it is here
     to support injection & unit testing.

     - parameter requirement: the needed Status.Requirement
     - parameter registrar: the registrar item.
    */
    init(_ requirement: Status.Requirement, registrar: Registrar)

    /**
     Query the capability to see if it's available on the device.
     
     - returns: true Bool value if the capability is available.
    */
    func isAvailable() -> Bool

    /**
     Get the current authorization status of the capability. This
     can be performed asynchronously. The status is returns as the
     argument to a completion block.
     
     - parameter completion: a Status -> Void closure.
    */
    func authorizationStatus(completion: Status -> Void)

    /**
     Request authorization with the requirement of the capability.
     
     Again, this is designed to be performed asynchronously. More than
     likely the registrar will present a dialog and wait for the user.
     When control is returned, the completion block should be called.
     
     - parameter completion: a dispatch_block_t closure.
    */
    func requestAuthorizationWithCompletion(completion: dispatch_block_t)
}

/**
 A protocol to define the authorization status of a device
 capability. Typically this will be an enum, like 
 CLAuthorizationStatus. Note that it is itself generic over
 the Requirement. This allows for another (or existing) enum 
 to be used to define granular levels of permissions. Use Void
 if not needed.
*/
public protocol AuthorizationStatusType {

    /// A generic type for the requirement
    typealias Requirement

    /**
     Given the current authorization status (i.e. self)
     this function should determine whether or not the
     provided Requirement has been met or not. Therefore
     this function should consider the overall authorization
     state, and if *authorized* - whether the authorization 
     is enough for the Requirement.
     
     - see: CLAuthorizationStatus extension for example.
     
     - parameter requirement: the necessary Requirement
     - returns: a Bool indicating whether or not the requirements are met.
    */
    func isRequirementMet(requirement: Requirement) -> Bool
}

/**
 Protocol for the underlying capabiltiy registrar.
*/
public protocol CapabilityRegistrarType {

    /// The only requirement is that it can be initialized with
    /// no parameters.
    init()
}

/**
 Capability is a namespace to nest as aliases the
 various device capability types.
 */
public struct Capability { }


extension Capability {

    /**
     Some device capabilities might not have the need for
     an authorization level, but still might not be available. For example
     PassKit. In which case, use VoidStatus as the nested Status type.
    */
    public struct VoidStatus: AuthorizationStatusType {

        /// - returns: true, VoidStatus cannot fail to meet requirements.
        public func isRequirementMet(requirement: Void) -> Bool {
            return true
        }
    }
}

/**

 # Get Authorization Status Operation

 This is a generic operation which will get the current authorization
 status for any CapabilityType.

*/
public class GetAuthorizationStatus<Capability: CapabilityType>: Operation {

    /// the StatusResponse is a tuple for the capabilities availability and status
    public typealias StatusResponse = (Bool, Capability.Status)

    /// the Completion is a closure which receives a StatusResponse
    public typealias Completion = StatusResponse -> Void

    /**
     After the operation has executed, this property will be set
     either true or false.
     
     - returns: a Bool indicating whether or not the capability is available.
    */
    public var isAvailable: Bool? = .None

    /**
     After the operation has executed, this property will be set
     to the current status of the capability.

     - returns: a StatusResponse of the current status.
     */
    public var status: Capability.Status? = .None

    let capability: Capability
    let completion: Completion

    /**
     Initialize the operation with a CapabilityType and completion. A default
     completion is set which does nothing. The status is also available using
     properties.
     
     - parameter capability: the Capability.
     - parameter completion: the Completion closure.
    */
    public init(_ capability: Capability, completion: Completion = { _ in }) {
        self.capability = capability
        self.completion = completion
        super.init()
        name = "Get Authorization Status for \(capability.name)"
    }

    func determineState(completion: StatusResponse -> Void) {
        isAvailable = capability.isAvailable()
        capability.authorizationStatus { status in
            self.status = status
            completion((self.isAvailable!, self.status!))
        }
    }

    /// The execute function required by Operation
    public override func execute() {
        determineState { response in
            self.completion(response)
            self.finish()
        }
    }
}

/**

 # Authorize Operation

 This is a generic operation which will request authorization 
 for any CapabilityType.
 */
public class Authorize<Capability: CapabilityType>: GetAuthorizationStatus<Capability> {

    /**
     Initialize the operation with a CapabilityType and completion. A default
     completion is set which does nothing. The status is also available using
     properties.

     - parameter capability: the Capability.
     - parameter completion: the Completion closure.
     */
    public override init(_ capability: Capability, completion: Completion = { _ in }) {
        super.init(capability, completion: completion)
        name = "Authorize \(capability.name).\(capability.requirement)"
        addCondition(MutuallyExclusive<Capability>())
    }

    /// The execute function required by Operation
    public override func execute() {
        capability.requestAuthorizationWithCompletion {
            super.execute()
        }
    }
}

/**
 An generic ErrorType used by the AuthorizedFor condition.
*/
public enum CapabilityError<Capability: CapabilityType>: ErrorType {

    /// If the capability is not available
    case NotAvailable

    /// If authorization for the capability was not granted.
    case AuthorizationNotGranted((Capability.Status, Capability.Status.Requirement?))
}

/**
 This is a generic OperationCondition which can be used to allow or
 deny operations to execute depending on the authorization status of a
 capability. 
 
 By default, the condition will add an Authorize operation as a dependency
 which means that potentially the user will be prompted to grant
 authorization. Suppress this from happening with SilentCondition.
*/
public struct AuthorizedFor<Capability: CapabilityType>: OperationCondition {

    /// - returns: a String, the name of the condition
    public let name: String

    /// - returns: false, is not mutually exclusive
    public let isMutuallyExclusive = false

    let capability: Capability

    /**
     Initialize the condition using a capability. For example
     
     ```swift
     let myOperation = MyOperation() // etc etc

     // Present the user with a permission dialog only if the authorization
     // status has not yet been determined.
     // If previously granted - operation will be executed with no dialog.
     // If previously denied - operation will fail with 
     // CapabilityError<Capability.Location>.AuthorizationNotGranted
     
     myOperation.addCondition(AuthorizedFor(Capability.Location(.WhenInUse)))
     ```
     
     - parameter capability: the Capability.
    */
    public init(_ capability: Capability) {
        self.capability = capability
        self.name = capability.name
    }

    /// Returns an Authorize operation as a dependency
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return Authorize(capability)
    }

    /// Evaluated the condition
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {

        if !capability.isAvailable() {
            completion(.Failed(CapabilityError<Capability>.NotAvailable))
        }
        else {
            capability.authorizationStatus { [requirement = self.capability.requirement] status in
                if status.isRequirementMet(requirement) {
                    completion(.Satisfied)
                }
                else {
                    completion(.Failed(CapabilityError<Capability>.AuthorizationNotGranted((status, requirement))))
                }
            }
        }
    }
}

extension Capability.VoidStatus: Equatable { }

/// Equality check for Capability.VoidStatus
public func ==(a: Capability.VoidStatus, b: Capability.VoidStatus) -> Bool {
    return true
}

