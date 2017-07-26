//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/// `Identifiable` provides a unique identifier.
public protocol Identifiable {

    /// A unique identifier
    var identifier: UUID { get }
}

public func ==<T: Identifiable> (lhs: T, rhs: T) -> Bool {
    return lhs.identifier == rhs.identifier
}

public extension Procedure {

    struct Identity: Identifiable, Equatable {

        public static func == (lhs: Identity, rhs: Identity) -> Bool {
            return lhs.identifier == rhs.identifier
        }

        public let identifier: UUID
        public let name: String?

        public var description: String {
            return name.map { "\($0) #\(identifier)" } ?? "Unnamed Procedure #\(identifier)"
        }
    }

    /// A Procedure's identity (often used for debugging purposes) provides a unique identifier
    /// for a `Procedure` instance, comprised of the Procedure's `name` and a `UUID`.
    var identity: Identity {
        return Identity(identifier: identifier, name: name)
    }
}
