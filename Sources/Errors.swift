//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public struct ProcedureKitError: Error {

    public enum Context {
        case unknown
        case programmingError(String)
        case dependencyFinishedWithErrors
        case parentCancelledWithErrors
        case requirementNotSatisfied
    }

    public static func programmingError(reason: String) -> ProcedureKitError {
        return ProcedureKitError(context: .programmingError(reason), errors: [])
    }

    public static func dependency(finishedWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .dependencyFinishedWithErrors, errors: errors)
    }

    public static func parent(cancelledWithErrors errors: [Error]) -> ProcedureKitError {
        return ProcedureKitError(context: .parentCancelledWithErrors, errors: errors)
    }

    public static func requirementNotSatisfied() -> ProcedureKitError {
        return ProcedureKitError(context: .requirementNotSatisfied, errors: [])
    }

    let context: Context
    let errors: [Error]
}
