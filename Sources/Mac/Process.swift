//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

open class ProcessProcedure: Procedure {

    /// Error type for ProcessProcedure
    public enum Error: Swift.Error, Equatable {
        case launchPathNotSet
        case terminationReason(Process.TerminationReason)

        public static func == (lhs: ProcessProcedure.Error, rhs: ProcessProcedure.Error) -> Bool {
            switch (lhs, rhs) {
            case (.launchPathNotSet, .launchPathNotSet):
                return true
            case let (.terminationReason(lhsReason), .terminationReason(rhsReason)):
                return lhsReason == rhsReason
            default:
                return false
            }
        }
    }

    /// Closure type for testing if the task did exit cleanly
    public typealias ProcessDidExitCleanly = (Int) -> Bool

    /// The default closure for checking the exit status
    public static let defaultProcessDidExitCleanly: ProcessDidExitCleanly = { status in
        switch status {
        case 0: return true
        default: return false
        }
    }

    // - returns process: the Process
    public let process: Process

    /// - returns processDidExitCleanly: the closure for exiting cleanly.
    public let processDidExitCleanly: ProcessDidExitCleanly

    /**
     Initializes ProcessProcedure with a Process.
     - parameter task: the Process
     - parameter processDidExitCleanly: a ProcessDidExitCleanly closure with a default.
     */
    public init(process: Process, processDidExitCleanly: @escaping ProcessDidExitCleanly = ProcessProcedure.defaultProcessDidExitCleanly) {
        self.process = process
        self.processDidExitCleanly = processDidExitCleanly
        super.init()

        addWillCancelBlockObserver { procedure, errors in
            guard procedure.process.isRunning else { return }
            procedure.process.terminate()
        }
    }

    open override func execute() {
        guard let _ = process.launchPath else {
            finish(withError: Error.launchPathNotSet)
            return
        }

        let previousTerminationHandler = process.terminationHandler

        process.terminationHandler = { [weak self] task in
            guard let strongSelf = self else { return }

            previousTerminationHandler?(strongSelf.process)
            if strongSelf.processDidExitCleanly(Int(strongSelf.process.terminationStatus)) {
                strongSelf.finish()
            }
            else {
                strongSelf.finish(withError: Error.terminationReason(strongSelf.process.terminationReason))
            }
        }

        process.launch()
    }
}
