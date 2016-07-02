//
//  TaskOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/07/2016.
//
//

import Foundation

public class TaskOperation: Operation {

    public enum Error: ErrorType, Equatable {
        case LaunchPathNotSet
        case TerminationReason(NSTaskTerminationReason)
    }

    public typealias TaskDidExitCleanly = Int -> Bool

    public static let defaultTaskDidExitCleanly: TaskDidExitCleanly = { status in
        switch status {
        case 0: return true
        default: return false
        }
    }

    public let task: NSTask
    public let taskDidExitCleanly: TaskDidExitCleanly

    public init(_ task: NSTask, taskDidExitCleanly: TaskDidExitCleanly = TaskOperation.defaultTaskDidExitCleanly) {
        self.task = task
        self.taskDidExitCleanly = taskDidExitCleanly
        super.init()
        addObserver(WillCancelObserver { [unowned self] (operation, errors) in
            guard let op = operation as? TaskOperation where operation === self && op.task.running else { return }
            op.task.terminate()
        })
    }

    public override func execute() {
        guard let _ = task.launchPath else {
            finish(Error.LaunchPathNotSet)
            return
        }

        task.terminationHandler = { [unowned self] task in
            if self.taskDidExitCleanly(Int(task.terminationStatus)) {
                self.finish()
            }
            else {
                self.finish(Error.TerminationReason(task.terminationReason))
            }
        }
        task.launch()
    }
}

public func == (lhs: TaskOperation.Error, rhs: TaskOperation.Error) -> Bool {
    switch (lhs, rhs) {
    case (.LaunchPathNotSet, .LaunchPathNotSet):
        return true
    case let (.TerminationReason(lhsReason), .TerminationReason(rhsReason)):
        return lhsReason == rhsReason
    default:
        return false
    }
}
