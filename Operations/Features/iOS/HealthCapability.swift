//
//  HealthCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import HealthKit

public struct HealthRequirement {
    public let share: Set<HKSampleType>
    public let read: Set<HKObjectType>

    internal var shareIdentifiers: Set<String> {
        return Set(share.map { $0.identifier })
    }

    public init(toShare: Set<HKSampleType> = Set(), toRead: Set<HKObjectType> = Set()) {
        share = toShare
        read = toRead
    }
}

public class HeathCapabilityStatus: NSObject, AuthorizationStatusType {
    typealias DictionaryType = Dictionary<String, HKAuthorizationStatus>

    var _dictionary = DictionaryType()

    public subscript(key: DictionaryType.Key) -> DictionaryType.Value? {
        get {
            return _dictionary[key]
        }
        set(newStatus) {
            _dictionary[key] = newStatus
        }
    }

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

public protocol HealthCapabilityRegistrarType: CapabilityRegistrarType {
    func opr_isHealthDataAvailable() -> Bool
    func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus
    func opr_requestAuthorizationForRequirement(requirement: HealthRequirement, completion: (Bool, NSError?) -> Void)
}

extension HKHealthStore: HealthCapabilityRegistrarType {

    public func opr_isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    public func opr_authorizationStatusForType(type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatusForType(type)
    }

    public func opr_requestAuthorizationForRequirement(requirement: HealthRequirement, completion: (Bool, NSError?) -> Void) {
        requestAuthorizationToShareTypes(requirement.share, readTypes: requirement.read, completion: completion)
    }
}

public class _HealthCapability<Registrar: HealthCapabilityRegistrarType>: NSObject, CapabilityType {

    public let name: String
    public let requirement: HealthRequirement

    let registrar: Registrar

    public required init(_ requirement: HealthRequirement, registrar: Registrar = Registrar()) {
        self.name = "Health"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    public func isAvailable() -> Bool {
        return registrar.opr_isHealthDataAvailable()
    }

    public func authorizationStatus(completion: HeathCapabilityStatus -> Void) {
        let status = HeathCapabilityStatus()

        for type in requirement.share {
            status[type.identifier] = registrar.opr_authorizationStatusForType(type)
        }

        completion(status)
    }

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
    public typealias Health = _HealthCapability<HKHealthStore>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Health())")
public typealias HealthCondition = AuthorizedFor<Capability.Health>


// MARK: - Boring Stuff

extension HealthRequirement: Equatable { }

public func ==(a: HealthRequirement, b: HealthRequirement) -> Bool {
    return (a.share == b.share) && (a.read == b.read)
}

extension HeathCapabilityStatus: CollectionType {

    public var startIndex: DictionaryType.Index {
        return _dictionary.startIndex
    }

    public var endIndex: DictionaryType.Index {
        return _dictionary.endIndex
    }

    public subscript(position: DictionaryType.Index) -> DictionaryType.Generator.Element {
        return _dictionary[position]
    }

    public subscript(bounds: Range<DictionaryType.Index>) -> DictionaryType.SubSequence {
        return _dictionary[bounds]
    }

    public func generate() -> DictionaryType.Generator {
        return _dictionary.generate()
    }
}


