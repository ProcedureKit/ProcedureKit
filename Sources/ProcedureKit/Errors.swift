//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

/// A type which has an associated error type
public protocol AssociatedErrorProtocol {

    /// The type of associated error
    associatedtype AssociatedError: Error
}

public protocol ProcedureKitComponent {
    var name: String { get }
}

public struct ProcedureKitError: Error, Equatable, CustomStringConvertible {

    public static func == (lhs: ProcedureKitError, rhs: ProcedureKitError) -> Bool {
        return lhs.context == rhs.context
    }

    public enum CapabilityError: Error {
        case unavailable, unauthorized
    }

    public enum Context: Equatable {

        public static func == (lhs: Context, rhs: Context) -> Bool {
            switch (lhs, rhs) {
            case let (.capability(lhs), .capability(rhs)):
                return lhs == rhs
            case let (.component(lhs), .component(rhs)):
                return lhs.name == rhs.name
            case let (.programmingError(lhs), .programmingError(rhs)):
                return lhs == rhs
            case let (.timedOut(lhs), .timedOut(rhs)):
                return lhs == rhs
            case (.conditionFailed, .conditionFailed),
                 (.dependenciesFailed, .dependenciesFailed),
                 (.dependenciesCancelled, .dependenciesCancelled),
                 (.dependencyFinishedWithError, .dependencyFinishedWithError),
                 (.dependencyCancelledWithError, .dependencyCancelledWithError),
                 (.noQueue, .noQueue),
                 (.parentCancelledWithError, .parentCancelledWithError),
                 (.requirementNotSatisfied, .requirementNotSatisfied),
                 (.unknown, .unknown):
                return true
            default:
                return false
            }
        }

        case capability(CapabilityError)
        case component(ProcedureKitComponent)
        case conditionFailed
        case dependenciesFailed
        case dependenciesCancelled
        case dependencyFinishedWithError
        case dependencyCancelledWithError
        case noQueue
        case parentCancelledWithError
        case programmingError(String)
        case requirementNotSatisfied
        case timedOut(Delay)
        case unknown
    }

    public static func capabilityUnavailable() -> ProcedureKitError {
        return ProcedureKitError(context: .capability(.unavailable), error: nil)
    }

    public static func capabilityUnauthorized() -> ProcedureKitError {
        return ProcedureKitError(context: .capability(.unauthorized), error: nil)
    }

    public static func component(_ component: ProcedureKitComponent, error: Error?) -> ProcedureKitError {
        return ProcedureKitError(context: .component(component), error: error)
    }

    public static func conditionFailed(with error: Error? = nil) -> ProcedureKitError {
        return ProcedureKitError(context: .conditionFailed, error: error)
    }

    public static func dependenciesFailed() -> ProcedureKitError {
        return ProcedureKitError(context: .dependenciesFailed, error: nil)
    }

    public static func dependenciesCancelled() -> ProcedureKitError {
        return ProcedureKitError(context: .dependenciesCancelled, error: nil)
    }

    public static func dependency(finishedWithError error: Error?) -> ProcedureKitError {
        return ProcedureKitError(context: .dependencyFinishedWithError, error: error)
    }

    public static func dependency(cancelledWithError error: Error?) -> ProcedureKitError {
        return ProcedureKitError(context: .dependencyCancelledWithError, error: error)
    }

    public static func noQueue() -> ProcedureKitError {
        return ProcedureKitError(context: .noQueue, error: nil)
    }

    public static func parent(cancelledWithError errors: Error?) -> ProcedureKitError {
        return ProcedureKitError(context: .parentCancelledWithError, error: errors)
    }

    public static func programmingError(reason: String) -> ProcedureKitError {
        return ProcedureKitError(context: .programmingError(reason), error: nil)
    }

    public static func requirementNotSatisfied() -> ProcedureKitError {
        return ProcedureKitError(context: .requirementNotSatisfied, error: nil)
    }

    public static func timedOut(with delay: Delay) -> ProcedureKitError {
        return ProcedureKitError(context: .timedOut(delay), error: nil)
    }

    public static let unknown = ProcedureKitError(context: .unknown, error: nil)

    public let context: Context
    public let error: Error?

    // Swift 3.0 Leak Fix:
    //
    // As of Swift 3.0.1 & Xcode 8.1, ProcedureKitError leaks memory when converted to a string
    // unless it conforms to CustomStringConvertible and provides its own `description`
    // implementation.
    //
    // Symptoms: Malloc 48 byte leaks
    //
    public var description: String {
        if let error = error {
            return "ProcedureKitError(context: \(context), error: \(error))"
        }
        return "ProcedureKitError(context: \(context)"
    }
}
