//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

/// `Identifiable` is a generic protocol for defining property based identity.
public protocol Identifiable {
    associatedtype Identity: Hashable

    /// An identifier
    var identity: Identity { get }
}

public func ==<T: Identifiable> (lhs: T, rhs: T) -> Bool {
    return lhs.identity == rhs.identity
}

public func ==<T, V> (lhs: T, rhs: V) -> Bool where T: Identifiable, V: Identifiable, T.Identity == V.Identity {
    return lhs.identity == rhs.identity
}

extension Procedure: Identifiable {

    public struct Identity: Identifiable, Hashable {

        public let identity: ObjectIdentifier
        public let name: String?

        public var description: String {
            return name.map { "\($0) #\(identity)" } ?? "Unnamed Procedure #\(identity)"
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identity)
        }
    }

    /// A Procedure's identity (often used for debugging purposes) provides a unique identifier
    /// for a `Procedure` instance, comprised of the Procedure's `name` and a `UUID`.
    public var identity: Identity {
        return Identity(identity: ObjectIdentifier(self), name: name)
    }
}
