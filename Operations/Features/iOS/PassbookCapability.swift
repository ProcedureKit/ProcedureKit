//
//  PassbookCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import PassKit

/**
 A refined CapabilityRegistrarType for Capability.Passbook. This
 protocol only defines whether the library is available as there
 are no other permission/authorization mechaniams.
*/
public protocol PassbookCapabilityRegistrarType: CapabilityRegistrarType {

    /// - returns: a true Bool is the Passkit library is available on the device.
    func opr_isPassKitLibraryAvailable() -> Bool
}

extension PKPassLibrary: PassbookCapabilityRegistrarType {

    /// - returns: a true Bool is the Passkit library is available on the device.
    public func opr_isPassKitLibraryAvailable() -> Bool {
        return PKPassLibrary.isPassLibraryAvailable()
    }
}

/**
 The Passbook capability, which is generic over an PassbookCapabilityRegistrarType.

 Framework consumers should not use this directly, but instead
 use Capability.Passbook. So that its usage is like this:

 ```swift

 GetAuthorizationStatus(Capability.Passbook()) { status in
    // check the status etc.
 }
 ```

 - see: Capability.Passbook
*/
public class _PassbookCapability<Registrar: PassbookCapabilityRegistrarType>: NSObject, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - return: there is no requirement, Void.
    public let requirement: Void

    let registrar: Registrar

    /**
     Initialize the capability. There are no requirements, the type is Void

     - parameter requirement: the required Void, defaults to ()
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: Void = (), registrar: Registrar = Registrar()) {
        self.name = "Passbook"
        self.requirement = requirement
        self.registrar = registrar
        super.init()
    }

    /// - returns: a true Bool is the Passkit library is available on the device.
    public func isAvailable() -> Bool {
        return registrar.opr_isPassKitLibraryAvailable()
    }

    /// Tests the authorization status - always VoidStatus
    public func authorizationStatus(completion: Capability.VoidStatus -> Void) {
        completion(Capability.VoidStatus())
    }

    /// requests authorization - a no-op, will just execute the completion block.
    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        completion()
    }
}

extension Capability {

    /**
     # Capability.Passbook

     This type represents the app's permission to access the PassKit Library.

     For framework consumers - use with `GetAuthorizationStatus`, `Authorize` and
     `AuthorizedFor`. For example

     Get the current authorization status for accessing the user's passkit library:

     ```swift
     GetAuthorizationStatus(Capability.Passkit()) { available, _ in
        // etc
     }
     ```
     */
    public typealias Passbook = _PassbookCapability<PKPassLibrary>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Passbook())")
public typealias PassbookCondition = AuthorizedFor<Capability.Passbook>
