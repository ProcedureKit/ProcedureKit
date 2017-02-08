//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
                 (.dependencyFinishedWithErrors, .dependencyFinishedWithErrors),
                 (.dependencyCancelledWithErrors, .dependencyCancelledWithErrors),
                 (.noQueue, .noQueue),
                 (.parentCancelledWithErrors, .parentCancelledWithErrors),
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
        case dependencyFinishedWithErrors
        case dependencyCancelledWithErrors
        case noQueue
        case parentCancelledWithErrors
        case programmingError(String)
        case requirementNotSatisfied
        case timedOut(Delay)
        case unknown
    }

    public static func capabilityUnavailable() -> ProcedureKitError {
        return ProcedureKitError(context: .capability(.unavailable), errors: [])
    }

    public static func capabilityUnauthorized() -> ProcedureKitError {
        return ProcedureKitError(context: .capability(.unauthorized), errors: [])
    }

    public static func component(_ component: ProcedureKitComponent, error: Error?) -> ProcedureKitError {
        return ProcedureKitError(context: .component(component), errors: error.map { [$0] } ?? [])
    }

    public static func conditionFailed(withErrors errors: [Error] = []) -> ProcedureKitError {
        return ProcedureKitError(context: .conditionFailed, errors: errors)
    }

    public static func dependenciesFailed() -> ProcedureKitError {
        return ProcedureKitError(context: .dependenciesFailed, errors: [])
    }

    public static func dependenciesCancelled() -> ProcedureKitError {
        return ProcedureKitError(context: .dependenciesCancelled, errors: [])
    }

    public static func dependency(finishedWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .dependencyFinishedWithErrors, errors: errors)
    }

    public static func dependency(cancelledWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .dependencyCancelledWithErrors, errors: errors)
    }

    public static func noQueue() -> ProcedureKitError {
        return ProcedureKitError(context: .noQueue, errors: [])
    }

    public static func parent(cancelledWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .parentCancelledWithErrors, errors: errors)
    }

    public static func programmingError(reason: String) -> ProcedureKitError {
        return ProcedureKitError(context: .programmingError(reason), errors: [])
    }

    public static func requirementNotSatisfied() -> ProcedureKitError {
        return ProcedureKitError(context: .requirementNotSatisfied, errors: [])
    }

    public static func timedOut(with delay: Delay) -> ProcedureKitError {
        return ProcedureKitError(context: .timedOut(delay), errors: [])
    }

    public static let unknown = ProcedureKitError(context: .unknown, errors: [])

    public let context: Context
    public let errors: [Error]

    // Swift 3.0 Leak Fix:
    //
    // As of Swift 3.0.1 & Xcode 8.1, ProcedureKitError leaks memory when converted to a string
    // unless it conforms to CustomStringConvertible and provides its own `description`
    // implementation.
    //
    // Symptoms: Malloc 48 byte leaks
    //
    public var description: String {
        return "ProcedureKitError(context: \(context), errors: \(errors))"
    }
}
