//
//  CalendarCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import EventKit

/**
 A refined CapabilityRegistrarType for Capability.Calendar. This
 protocol defines two functions which the registrar uses to get
 the current authorization status and request access.
*/
public protocol EventsCapabilityRegistrarType: CapabilityRegistrarType {

    /**
     Get the current EKAuthorizationStatus.
     
     - parameter requirement: the EKEntityType, e.g. .Events, or .Reminders
     - returns: the EKAuthorizationStatus
    */
    func opr_authorizationStatusForRequirement(requirement: EKEntityType) -> EKAuthorizationStatus

    /**
     Request access for the given EKEntityType (i.e. the requirement).
     
     - parameter requirement: the EKEntityType, e.g. .Events, or .Reminders
     - parameter completion: a EKEventStoreRequestAccessCompletionHandler
    */
    func opr_requestAccessForRequirement(requirement: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler)
}

extension EKEventStore: EventsCapabilityRegistrarType {

    /**
     Get the current EKAuthorizationStatus from the Event Store

     - parameter requirement: the EKEntityType, e.g. .Events, or .Reminders
     - returns: the EKAuthorizationStatus
     */
    public func opr_authorizationStatusForRequirement(requirement: EKEntityType) -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatusForEntityType(requirement)
    }

    /**
     Request access for the given EKEntityType (i.e. the requirement) from the Event Store.

     - parameter requirement: the EKEntityType, e.g. .Events, or .Reminders
     - parameter completion: a EKEventStoreRequestAccessCompletionHandler
     */
    public func opr_requestAccessForRequirement(requirement: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler) {
        requestAccessToEntityType(requirement, completion: completion)
    }
}

extension EKAuthorizationStatus: AuthorizationStatusType {

    /**
     Determine whether access has been granted given the EKAuthorizationStatus.
     
     - parameter requirement: the required EKEntityType
     - returns: a true Bool for authorized status
    */
    public func isRequirementMet(requirement: EKEntityType) -> Bool {
        if case .Authorized = self {
            return true
        }
        return false
    }
}

/**
 The Events capability, which is generic over an EventsCapabilityRegistrarType.
 
 Framework consumers should not use this directly, but instead 
 use Capability.Calendar. So that its usage is like this:
 
 ```swift
 
 GetAuthorizationStatus(Capability.Calendar()) { status in
    // check the status etc.
 }
 ```
 
 - see: Capability.Calendar
*/
public class _EventsCapability<Registrar: EventsCapabilityRegistrarType>: NSObject, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: the EKEntityType, the required type of the capability
    public let requirement: EKEntityType

    let registrar: Registrar

    /**
     Initialize the capability. By default, it requires access to .Event.

     - parameter requirement: the required EKEntityType, defaults to .Event
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
    */
    public required init(_ requirement: EKEntityType = .Event, registrar: Registrar = Registrar()) {
        self.name = "Events"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    /// - returns: true, EventKit is always available
    public func isAvailable() -> Bool {
        return true
    }

    /**
     Get the current authorization status of EventKit from the Registrar.
     - parameter completion: a EKAuthorizationStatus -> Void closure.
     */
    public func authorizationStatus(completion: EKAuthorizationStatus -> Void) {
        completion(registrar.opr_authorizationStatusForRequirement(requirement))
    }

    /**
     Request authorization to EventKit from the Registrar.
     - parameter completion: a dispatch_block_t
     */
    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        let status = registrar.opr_authorizationStatusForRequirement(requirement)
        switch status {
        case .NotDetermined:
            registrar.opr_requestAccessForRequirement(requirement) { success, error in
                completion()
            }
        default:
            completion()
        }
    }
}

public extension Capability {

    /**
     # Capability.Calendar
     
     This type represents the app's permission to access EventKit.

     For framework consumers - use with `GetAuthorizationStatus`, `Authorize` and
     `AuthorizedFor`. For example
     
     Get the current authorization status for accessing the user's calendars:

     ```swift
     GetAuthorizationStatus(Capability.Calendar()) { available, status in
         // etc
     }
     ```
     
     Lets say we have an operation which performs an action with the user's
     calendars. We need to have permission to access their calendars first.
     We can add an OperationCondition to such an operation, so that if
     the user hasn't granted permission it will fail (we can check the errors),
     or, if the permission hasn't been asked, it will ask for us automatically.
     
     ```swift
     // Define the operation
     let operation = ProcessCalendarsOperation()
     
     // Create & add condition
     let condition = AuthorizedFor(Capability.Calendar())
     operation.addCondition(condition)
     
     // Observe & look out for errors
     operation.addObserver(BlockObserver { _, errors in
        if !errors.isEmpty, 
          let error = errors.first as? CapabilityError<Capability.Calendar> {
             switch error {
               case .AuthorizationNotGranted(status, requirement):
                  print("Access to calendars was denied...")
             }
          }
     })
     
     // Add the operation to our queue
     queue.addOperation(operation)
     ```
    */
    typealias Calendar = _EventsCapability<EKEventStore>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Calendar())")
public typealias CalendarCondition = AuthorizedFor<Capability.Calendar>

