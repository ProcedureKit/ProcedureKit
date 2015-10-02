//
//  PassbookCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import PassKit

public protocol PassbookCapabilityRegistrarType: CapabilityRegistrarType {
    func opr_isPassKitLibraryAvailable() -> Bool
}

extension PKPassLibrary: PassbookCapabilityRegistrarType {

    public func opr_isPassKitLibraryAvailable() -> Bool {
        return PKPassLibrary.isPassLibraryAvailable()
    }
}

public class _PassbookCapability<Registrar: PassbookCapabilityRegistrarType>: NSObject, CapabilityType {

    public let name: String
    public let requirement: Void

    let registrar: Registrar

    public required init(_ requirement: Void = (), registrar: Registrar = Registrar()) {
        self.name = "Passbook"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    public func isAvailable() -> Bool {
        return registrar.opr_isPassKitLibraryAvailable()
    }

    public func authorizationStatus() -> Capability.VoidStatus {
        return Capability.VoidStatus()
    }

    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        completion()
    }
}

extension Capability {
    public typealias Passbook = _PassbookCapability<PKPassLibrary>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Passbook())")
public typealias PassbookCondition = AuthorizedFor<Capability.Passbook>
