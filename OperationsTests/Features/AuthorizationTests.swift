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
            case Minimum, Maximum
        }

        case NotDetermined, Restricted, Denied, MinimumAuthorized, MaximumAuthorized

        func isRequirementMet(requirement: Requirement) -> Bool {
            switch (requirement, self) {
            case (.Minimum, .MinimumAuthorized), (_, MaximumAuthorized):
                return true
            default:
                return false
            }
        }
    }

    let name = "Testable Capability"
    var requirement: Status.Requirement

    var serviceIsAvailable = true
    var didCheckIsAvailable = false

    var serviceAuthorizationStatus: Status = .NotDetermined
    var didCheckAuthorizationStatus = false

    var responseAuthorizationStatus: Status = .MaximumAuthorized
    var didRequestAuthorization = false

    required init(_ requirement: Status.Requirement = .Minimum, registrar: Registrar = Registrar()) {
        self.requirement = requirement
    }

    func isAvailable() -> Bool {
        didCheckIsAvailable = true
        return serviceIsAvailable
    }

    func authorizationStatus() -> Status {
        didCheckAuthorizationStatus = true
        return serviceAuthorizationStatus
    }

    func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        didRequestAuthorization = true
        serviceAuthorizationStatus = responseAuthorizationStatus
        completion()
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
        XCTAssertEqual(operation.name!, "Get Authorization Status for: Testable Capability")
    }

    func test__get_status_sets_state() {

        let operation = GetAuthorizationStatus(capability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let enabled = operation.isAvailable, status = operation.status else {
            XCTFail("Operation state was not set.")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.NotDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
    }

    func test__get_status_runs_completionBlock() {

        var completedWithEnabled: Bool? = .None
        var completedWithStatus: TestableCapability.Status? = .None

        let operation = GetAuthorizationStatus(capability) { enabled, status in
            completedWithEnabled = enabled
            completedWithStatus = status
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let enabled = completedWithEnabled, status = completedWithStatus else {
            XCTFail("Completion block was not executed")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, TestableCapability.Status.NotDetermined)
        XCTAssertTrue(capability.didCheckIsAvailable)
        XCTAssertTrue(capability.didCheckAuthorizationStatus)
        XCTAssertFalse(capability.didRequestAuthorization)
    }

    func test__authorize_operation_name() {
        let operation = Authorize(capability)
        XCTAssertEqual(operation.name!, "Authorize Minimum for: Testable Capability")
    }

    func test__authorize() {

        let operation = Authorize(capability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(capability.didRequestAuthorization)
    }

    func test__authorized_condition_name() {
        let condition = AuthorizedFor(capability)
        XCTAssertEqual(condition.name, capability.name)
    }

    func test__authorized_condition_exclusivity() {
        let condition = AuthorizedFor(capability)
        XCTAssertFalse(condition.isMutuallyExclusive)
    }

    func test__authorized_condition_returns_correct_dependency() {
        let operation = TestOperation()
        let condition = AuthorizedFor(capability)

        guard let dependency = condition.dependencyForOperation(operation) else {
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

        let operation = TestOperation()
        capability.serviceIsAvailable = false
        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .None

        condition.evaluateForOperation(operation) { result in
            conditionResult = result
        }

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .Failed(let error):
            if let error = error as? CapabilityError<TestableCapability> {
                switch error {
                case .NotAvailable:
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
        let operation = TestOperation()
        capability.requirement = .Maximum
        capability.serviceAuthorizationStatus = .MinimumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .None

        condition.evaluateForOperation(operation) { result in
            conditionResult = result
        }

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .Failed(let error):
            if let error = error as? CapabilityError<TestableCapability> {
                switch error {
                case let .AuthorizationNotGranted(status, requirement):
                    XCTAssertEqual(status, TestableCapability.Status.MinimumAuthorized)
                    XCTAssertEqual(requirement!, TestableCapability.Status.Requirement.Maximum)
                default:
                    XCTFail("Incorrect failure error.")
                }
            }
        default:
            XCTFail("Incorrect condition result.")
        }
    }

    func test__authorized_condition_succeeds_when_requirements_are_met() {
        let operation = TestOperation()
        capability.serviceAuthorizationStatus = .MinimumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .None

        condition.evaluateForOperation(operation) { result in
            conditionResult = result
        }

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .Satisfied:
            break
        default:
            XCTFail("Incorrect condition result.")
        }
    }

    func test__authorized_condition_succeeds_when_requirements_are_exceeded() {
        let operation = TestOperation()
        capability.serviceAuthorizationStatus = .MaximumAuthorized

        let condition = AuthorizedFor(capability)
        var conditionResult: OperationConditionResult? = .None

        condition.evaluateForOperation(operation) { result in
            conditionResult = result
        }

        XCTAssertNotNil(conditionResult)
        switch conditionResult! {
        case .Satisfied:
            break
        default:
            XCTFail("Incorrect condition result.")
        }
    }
}



