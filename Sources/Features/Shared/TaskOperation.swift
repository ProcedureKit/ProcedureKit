//
//  TaskOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/07/2016.
//
//

import Foundation

/**
 TaskOperation is a simple OldOperation subclass which wraps NSTask

 Construct the operation with a configured NSTask instance, when
 the operation is executed, the task will be launched. When the
 task completes, the operation is finished.

 If the task exit indicates a failure, the operation will finish
 with an error of type TaskOperation.Error.TerminationReason.

 By default TaskOperation interprets any non zero exit as a failure
 however, this can be overridden by providing a TaskDidExitCleanly
 block to the initializer.

 */
public class TaskOperation: OldOperation {

    /// Error type for TaskOperation
    public enum Error: ErrorProtocol, Equatable {
        case launchPathNotSet
        case terminationReason(Task.TerminationReason)
    }

    /// Closure type for testing if the task did exit cleanly
    public typealias TaskDidExitCleanly = (Int) -> Bool

    /// The default closure for checking the exit status
    public static let defaultTaskDidExitCleanly: TaskDidExitCleanly = { status in
        switch status {
        case 0: return true
        default: return false
        }
    }

    /// - returns task: the Task
    public let task: Task

    /// - returns taskDidExitCleanly: the closure for exiting cleanly.
    public let taskDidExitCleanly: TaskDidExitCleanly

    /**
     Initializes TaskOperation with an NSTask.

     - parameter task: the NSTask
     - parameter taskDidExitCleanly: a TaskDidExitCleanly closure with a default.
    */
    public init(task: Task, taskDidExitCleanly: TaskDidExitCleanly = TaskOperation.defaultTaskDidExitCleanly) {
        self.task = task
        self.taskDidExitCleanly = taskDidExitCleanly
        super.init()
        addObserver(WillCancelObserver { [unowned self] (operation, errors) in
            guard let op = operation as? TaskOperation, operation === self && op.task.isRunning else { return }
            op.task.terminate()
        })
    }

    public override func execute() {
        guard let _ = task.launchPath else {
            finish(Error.launchPathNotSet)
            return
        }

        let previousTerminationHandler = task.terminationHandler

        task.terminationHandler = { [unowned self] task in
            previousTerminationHandler?(task)
            if self.taskDidExitCleanly(Int(task.terminationStatus)) {
                self.finish()
            }
            else {
                self.finish(Error.terminationReason(task.terminationReason))
            }
        }

        task.launch()
    }
}

public func == (lhs: TaskOperation.Error, rhs: TaskOperation.Error) -> Bool {
    switch (lhs, rhs) {
    case (.launchPathNotSet, .launchPathNotSet):
        return true
    case let (.terminationReason(lhsReason), .terminationReason(rhsReason)):
        return lhsReason == rhsReason
    default:
        return false
    }
}
