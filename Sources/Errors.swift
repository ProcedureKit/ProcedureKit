//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public struct ProcedureKitError: Error {

    public enum Context: Equatable {

        public static func == (lhs: Context, rhs: Context) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown), (.dependencyFinishedWithErrors, .dependencyFinishedWithErrors), (.parentCancelledWithErrors, .parentCancelledWithErrors), (.requirementNotSatisfied, .requirementNotSatisfied):
                return true
            case let (.programmingError(lhsReason), .programmingError(rhsReason)):
                return lhsReason == rhsReason
            default: return false
            }
        }

        case unknown
        case programmingError(String)
        case timedOut(Delay)
        case conditionFailed
        case dependenciesFailed
        case dependenciesCancelled
        case dependencyFinishedWithErrors
        case dependencyCancelledWithErrors
        case parentCancelledWithErrors
        case requirementNotSatisfied
    }

    public static func programmingError(reason: String) -> ProcedureKitError {
        return ProcedureKitError(context: .programmingError(reason), errors: [])
    }

    public static func timedOut(with delay: Delay) -> ProcedureKitError {
        return ProcedureKitError(context: .timedOut(delay), errors: [])
    }

    public static func dependenciesFailed() -> ProcedureKitError {
        return ProcedureKitError(context: .dependenciesFailed, errors: [])
    }

    public static func conditionFailed(withErrors errors: [Error] = []) -> ProcedureKitError {
        return ProcedureKitError(context: .conditionFailed, errors: errors)
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

    public static func parent(cancelledWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .parentCancelledWithErrors, errors: errors)
    }

    public static func requirementNotSatisfied() -> ProcedureKitError {
        return ProcedureKitError(context: .requirementNotSatisfied, errors: [])
    }

    public let context: Context
    public let errors: [Error]
}
