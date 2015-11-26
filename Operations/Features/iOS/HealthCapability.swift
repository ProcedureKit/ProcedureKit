//
//  HealthCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import HealthKit

/**
 HealthRequirement composes sets of HKSampleType and
 HKObjectType to share and read. These are the
 HealthKit types which we require from the capability.
*/
public struct HealthRequirement {

    /// - returns: the Set<HKSampleType> we want share access for
    public let share: Set<HKSampleType>

    /// - returns: the Set<HKObjectType> we want read access for
    public let read: Set<HKObjectType>

    internal var shareIdentifiers: Set<String> {
        return Set(share.map { $0.identifier })
    }

    /**
     Initialize HealthRequirement with the sample types we wish to share
     i.e. write to, and object types we wish to read.
    */
    public init(toShare: Set<HKSampleType> = Set(), toRead: Set<HKObjectType> = Set()) {
        share = toShare
        read = toRead
    }
}

/**
 The authorization status for HealthKit. Because permission is requested
 for sets of samples, the authorization status is a mixture.  Therefore
 this type provides key based access to check authorization status.
*/
public class HealthCapabilityStatus: NSObject, AuthorizationStatusType {
    typealias DictionaryType = Dictionary<String, HKAuthorizationStatus>

    var _dictionary = DictionaryType()

    /// Access the HKAuthorizationStatus by the share identifier.
    public subscript(key: DictionaryType.Key) -> DictionaryType.Value? {
        get {
            return _dictionary[key]
        }
        set(newStatus) {
            _dictionary[key] = newStatus
        }
    }


    /// Determine whether the application permissions have been met.
    public func isRequirementMet(requirement: HealthRequirement) -> Bool {
        if requirement.shareIdentifiers.isSubsetOf(_dictionary.keys) {
            let statuses = Set(_dictionary.values)
            if statuses.count == 1 && statuses.first! == .SharingAuthorized {
                return true
            }
        }
        return false
    }
}

/**
 A refined CapabilityRegistrarType for Capability.Health. This
 protocol defines functions which the registrar uses to get
 the current authorization status and request access.
*/
public protocol HealthCapabilityRegistrarType: CapabilityRegistrarType {

    /// - returns: a Bool, whether of not health data is available
    func opr_isHealthDataAvailable() -> Bool

    /**
     Get the current HKAuthorizationStatus.

     - parameter requirement: the HKObjectType
     - returns: the HKAuthorizationStatus
     */
    func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus

    /**
     Request access given a HealthRequirement

     - parameter requirement: the HealthRequirement
     - parameter completion: a (Bool, NSError?) -> Void closure
     */
    func opr_requestAuthorizationForRequirement(requirement: HealthRequirement, completion: (Bool, NSError?) -> Void)
}

extension HKHealthStore: HealthCapabilityRegistrarType {

    /**
     Determines if health data is available.
     - returns: a true Bool if health data is available
    */
    public func opr_isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    /**
     Get the HKAuthorizationStatus for HKObjectType

     - parameter requirement: the HKObjectType
     - returns: the HKAuthorizationStatus
     */
    public func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatusForType(type)
    }

    /**
     Request access for the given HealthRequirement.

     - parameter requirement: the HealthRequirement
     - parameter completion: a closure which receives a Bool and optional NSError.
     */
    public func opr_requestAuthorizationForRequirement(requirement: HealthRequirement, completion: (Bool, NSError?) -> Void) {
        requestAuthorizationToShareTypes(requirement.share, readTypes: requirement.read, completion: completion)
    }
}

/**
 The Health capability, which is generic over a HealthCapabilityRegistrarType.
 
 Framework consumers should not use this directly, but instead
 use Capability.Health. So that its usage is like this:

 ```swift

 let requirements: HealthRequirements() // etc etc
 GetAuthorizationStatus(Capability.Health(requirements)) { status in
    // check the status etc.
 }
 ```

 - see: Capability.Health
*/
public class _HealthCapability<Registrar: HealthCapabilityRegistrarType>: NSObject, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: the HealthRequirement, the required type of the capability
    public let requirement: HealthRequirement

    let registrar: Registrar

    /**
     Initialize the capability. Has no default HealthRequirement

     - parameter requirement: the required HealthRequirement
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: HealthRequirement, registrar: Registrar = Registrar()) {
        self.name = "Health"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    /// - returns: true if health data is available on this device
    public func isAvailable() -> Bool {
        return registrar.opr_isHealthDataAvailable()
    }

    /**
     Get the current authorization status of HealthKit from the Registrar.
     - see: HeathCapabilityStatus
     - parameter completion: a HeathCapabilityStatus -> Void closure.
     */
    public func authorizationStatus(completion: HealthCapabilityStatus -> Void) {
        let status = HealthCapabilityStatus()

        for type in requirement.share {
            status[type.identifier] = registrar.opr_authorizationStatusForType(type)
        }

        completion(status)
    }

    /**
     Request authorization to HealthKit from the Registrar.
     - parameter completion: a dispatch_block_t
     */
    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        if !registrar.opr_isHealthDataAvailable() {
            completion()
        }
        else if !requirement.share.isEmpty || !requirement.read.isEmpty {
            registrar.opr_requestAuthorizationForRequirement(requirement) { (success, error) in
                completion()
            }
        }
        else {
            completion()
        }
    }
}

extension Capability {

    /**
     # Capability.Heath
     
     This type represents the app's permission to access HealthKit.

     For framework consumers - use with GetAuthorizationStatus, Authorize and
     AuthorizedFor. For example

     ```swift
     let sampleTypes: Set<HKSampleType> // etc etc
     let requirements = HealthRequirement(toShare: sampleTypes)
     GetAuthorizationStatus(Capability.Health(requirements)) { available, status in
        // etc
     }
     ```
    */
    public typealias Health = _HealthCapability<HKHealthStore>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Health())")
public typealias HealthCondition = AuthorizedFor<Capability.Health>

extension HealthRequirement: Equatable { }

/**
 HealthRequirement is Equatable
*/
public func ==(a: HealthRequirement, b: HealthRequirement) -> Bool {
    return (a.share == b.share) && (a.read == b.read)
}

/**
 HealthRequirement conforms to CollectionType
*/
extension HealthCapabilityStatus: CollectionType {

    /// - returns: the DictionaryType.Index start
    public var startIndex: DictionaryType.Index {
        return _dictionary.startIndex
    }

    /// - returns: the DictionaryType.Index end
    public var endIndex: DictionaryType.Index {
        return _dictionary.endIndex
    }

    /// - returns: the HKAuthorizationStatus by identifier
    public subscript(position: DictionaryType.Index) -> DictionaryType.Generator.Element {
        return _dictionary[position]
    }

    /// - returns: a sub sequence for the bounds
    public subscript(bounds: Range<DictionaryType.Index>) -> DictionaryType.SubSequence {
        return _dictionary[bounds]
    }

    /// - returns: a generator
    public func generate() -> DictionaryType.Generator {
        return _dictionary.generate()
    }
}


