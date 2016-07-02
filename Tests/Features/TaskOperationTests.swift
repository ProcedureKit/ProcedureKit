//
//  TaskOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/07/2016.
//
//

import XCTest
@testable import Operations

class TaskOperationTests: OperationTests {

    var operation: TaskOperation!

    func create(path: String = "/bin/pwd") -> NSTask {
        let task = NSTask()
        task.launchPath = path
        return task
    }

    func test__task_runs() {
        operation = TaskOperation(task: create())
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.failed)
    }

    func test__task_cancels() {
        operation = TaskOperation(task: create("/bin/ls"))
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__task_finishes_with_error_if_launch_path_not_set() {
        operation = TaskOperation(task: NSTask())
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.failed)
        guard let error = operation.errors.first as? TaskOperation.Error else { XCTFail(); return }
        XCTAssertEqual(error, TaskOperation.Error.LaunchPathNotSet)
    }

    func test__error_equality() {
        XCTAssertEqual(TaskOperation.Error.TerminationReason(.Exit), TaskOperation.Error.TerminationReason(.Exit))
        XCTAssertEqual(TaskOperation.Error.TerminationReason(.UncaughtSignal), TaskOperation.Error.TerminationReason(.UncaughtSignal))
        XCTAssertNotEqual(TaskOperation.Error.TerminationReason(.Exit), TaskOperation.Error.TerminationReason(.UncaughtSignal))
        XCTAssertNotEqual(TaskOperation.Error.TerminationReason(.UncaughtSignal), TaskOperation.Error.TerminationReason(.Exit))
        XCTAssertNotEqual(TaskOperation.Error.LaunchPathNotSet, TaskOperation.Error.TerminationReason(.Exit))
    }
}


