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

    func create(_ path: String = "/bin/pwd") -> Task {
        let task = Task()
        task.launchPath = path
        return task
    }

    func test__task_runs() {
        operation = TaskOperation(task: create())
        waitForOperation(operation)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.failed)
    }

    func test__task_cancels() {
        operation = TaskOperation(task: create("/bin/ls"))
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }

    func test__task_finishes_with_error_if_launch_path_not_set() {
        operation = TaskOperation(task: Task())
        waitForOperation(operation)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.failed)
        guard let error = operation.errors.first as? TaskOperation.Error else { XCTFail(); return }
        XCTAssertEqual(error, TaskOperation.Error.launchPathNotSet)
    }

    func test__error_equality() {
        XCTAssertEqual(TaskOperation.Error.terminationReason(.exit), TaskOperation.Error.terminationReason(.exit))
        XCTAssertEqual(TaskOperation.Error.terminationReason(.uncaughtSignal), TaskOperation.Error.terminationReason(.uncaughtSignal))
        XCTAssertNotEqual(TaskOperation.Error.terminationReason(.exit), TaskOperation.Error.terminationReason(.uncaughtSignal))
        XCTAssertNotEqual(TaskOperation.Error.terminationReason(.uncaughtSignal), TaskOperation.Error.terminationReason(.exit))
        XCTAssertNotEqual(TaskOperation.Error.launchPathNotSet, TaskOperation.Error.terminationReason(.exit))
    }
}


