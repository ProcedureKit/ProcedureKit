//
//  AuthorizationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 02/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import XCTest
@testable import Operations

class TestableCapability: NSObject, CapabilityType {

    struct Registrar: CapabilityRegistrarType { }

    enum Status: AuthorizationStatusType {
        enum Requirement {
            case minimum, maximum
        }

        case notDetermined, restricted, denied, minimumAuthorized, maximumAuthorized

        func isRequirementMet(_ requirement: Requirement) -> Bool {
            switch (requirement, self) {
            case (.minimum, .minimumAuthorized), (_, maximumAuthorized):
                return true
            default:
                return false
            }
        }
    }

    let name = "Testable Capability"
    var requirement: Status.Requirement

    var registrar: CapabilityRegistrarType = Registrar()

    var isAsynchronous = false

    var serviceIsAvailable = true
    var didCheckIsAvailable = false

    var serviceAuthorizationStatus: Status = .notDetermined
    var didCheckAuthorizationStatus = false

    var responseAuthorizationStatus: Status = .maximumAuthorized
    var didRequestAuthorization = false

    required init(_ requirement: Status.Requirement = .minimum) {
        self.requirement = requirement
    }

    func isAvailable() -> Bool {
        didCheckIsAvailable = true
        return serviceIsAvailable
    }

    func authorizationStatus(_ completion: (Status) -> Void) {
        didCheckAuthorizationStatus = true
        if isAsynchronous {
            (Queue.initiated.queue).async {
                completion(self.serviceAuthorizationStatus)
            }
        }
        else {
            completion(serviceAuthorizationStatus)
        }
    }

    func requestAuthorizationWithCompletion(_ completion: ()->()) {
        didRequestAuthorization = true
        serviceAuthorizationStatus = responseAuthorizationStatus
        if isAsynchronous {
            (Queue.initiated.queue).async(execute: completion)
        }
        else {
            completion()
        }
    }
}

class AuthorizationTests: OperationTests {

    var capability: TestableCapability!

    override func setUp() {
        super.setUp()
        capability = TestableCapability()
    }

    override func tearDown() {
        capability = nil
        super.tearDown()
    }

    func test__get_status_operation_name() {
        let operation = GetAuthorizationStatus(capability)
        XCTAssertEqual(operation.name!, "Get Authorization Status for Testable Capability")
    }

    func test__get_status_sets_state() {

        let operation = GetAuthorizationStatus(capability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        guard let enabled = operation.isAvailable, let status = operation.status else {
            XCTFail("OldOperation state was not set.")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.notDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
    }

    func test__get_status_runs_completionBlock() {

        var completedWithEnabled: Bool? = .none
        var completedWithStatus: TestableCapability.Status? = .none

        let operation = GetAuthorizationStatus(capability) { enabled, status in
            completedWithEnabled = enabled
            completedWithStatus = status
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        guard let enabled = completedWithEnabled, let status = completedWithStatus else {
            XCTFail("Completion block was not executed")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.notDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
    }

    func test__authorize_operation_name() {
        let operation = Authorize(capability)
        XCTAssertEqual(operation.name!, "Authorize Testable Capability.Minimum")
    }

    func test__authorize() {

        let operation = Authorize(capability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(capability.didRequestAuthorization)
    }

    func test__authorized_condition_name() {
        let condition = AuthorizedFor(capability)
        XCTAssertEqual(condition.name, capability.name)
    }

    func test__authorized_condition_exclusivity() {
        let condition = AuthorizedFor(capability)
        XCTAssertFalse(condition.mutuallyExclusive)
    }

    func test__authorized_condition_returns_correct_dependency() {

        let condition = AuthorizedFor(capability)

        guard let dependency = condition.dependencies.first else {
            XCTFail("Condition did not return a dependency")
            return
        }

        guard let authorize = dependency as? Authorize<TestableCapability> else {
            XCTFail("Dependency is not the correct type")
            return
        }

        XCTAssertEqual(authorize.capability, condition.capability)
    }

    func test__authorized_condition_fails_if_capability_is_not_available() {
        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        capability.serviceIsAvailable = false
        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .none

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .failed(let error):
            if let error = error as? CapabilityError<TestableCapability> {
                switch error {
                case .notAvailable:
                    break
                default:
                    XCTFail("Incorrect failure error.")
                }
            }
        default:
            XCTFail("Incorrect condition result.")
        }
    }

    func test__authorized_condition_fails_if_requirement_is_not_met() {
        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        capability.requirement = .maximum
        capability.serviceAuthorizationStatus = .minimumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .none

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .failed(let error):
            if let error = error as? CapabilityError<TestableCapability> {
                switch error {
                case let .authorizationNotGranted(status, requirement):
                    XCTAssertEqual(status, TestableCapability.Status.minimumAuthorized)
                    XCTAssertEqual(requirement!, TestableCapability.Status.Requirement.maximum)
                default:
                    XCTFail("Incorrect failure error.")
                }
            }
        default:
            XCTFail("Incorrect condition result.")
        }
    }

    func test__authorized_condition_succeeds_when_requirements_are_met() {
        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        capability.serviceAuthorizationStatus = .minimumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .none

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .satisfied:
            break
        default:
            XCTFail("Incorrect condition result.")
        }
    }

    func test__authorized_condition_succeeds_when_requirements_are_exceeded() {
        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        capability.serviceAuthorizationStatus = .maximumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .none

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .satisfied:
            break
        default:
            XCTFail("Incorrect condition result.")
        }
    }
}

class AsyncCapabilityAuthorizationTests: AuthorizationTests {

    override func setUp() {
        super.setUp()
        capability = TestableCapability()
        capability.isAsynchronous = true
    }

    func test__async_get_status_sets_state() {

        let operation = GetAuthorizationStatus(capability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        guard let enabled = operation.isAvailable, let status = operation.status else {
            XCTFail("OldOperation state was not set.")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.notDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
        XCTAssertTrue(operation.isFinished)
    }

    func test__async_get_status_runs_completionBlock() {

        var completedWithEnabled: Bool? = .none
        var completedWithStatus: TestableCapability.Status? = .none

        let operation = GetAuthorizationStatus(capability) { enabled, status in
            completedWithEnabled = enabled
            completedWithStatus = status
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        guard let enabled = completedWithEnabled, let status = completedWithStatus else {
            XCTFail("Completion block was not executed")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.notDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
        XCTAssertTrue(operation.isFinished)
    }


}
