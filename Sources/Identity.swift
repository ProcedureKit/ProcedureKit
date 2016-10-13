//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public protocol Identifiable {
    var identifier: UUID { get }
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

    var identity: Identity {
        return Identity(identifier: identifier, name: name)
    }
}
