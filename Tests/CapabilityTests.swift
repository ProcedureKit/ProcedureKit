//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GetAuthorizationStatusTests: TestableCapabilityTestCase {

    func test__sets_result() {
        wait(for: getAuthorizationStatus)
        XCTAssertGetAuthorizationStatus(getAuthorizationStatus.output.success, expected: (true, .unknown))
        XCTAssertTestCapabilityStatusChecked()
    }

    func test__async_sets_result() {
        capability.isAsynchronous = true
        wait(for: getAuthorizationStatus)
        XCTAssertGetAuthorizationStatus(getAuthorizationStatus.output.success, expected: (true, .unknown))
        XCTAssertTestCapabilityStatusChecked()
    }

    func test__runs_completion_block() {
        var completedWithResult: GetAuthorizationStatusProcedure<TestableCapability.Status>.Output = (false, .unknown)
        getAuthorizationStatus = GetAuthorizationStatusProcedure(capability) { completedWithResult = $0 }

        wait(for: getAuthorizationStatus)
        XCTAssertGetAuthorizationStatus(completedWithResult, expected: (true, .unknown))
        XCTAssertTestCapabilityStatusChecked()
    }

    func test__async_runs_completion_block() {
        capability.isAsynchronous = true
        var completedWithResult: GetAuthorizationStatusProcedure<TestableCapability.Status>.Output = (false, .unknown)

        getAuthorizationStatus = GetAuthorizationStatusProcedure(capability) { result in
            completedWithResult = result
        }

        wait(for: getAuthorizationStatus)
        XCTAssertGetAuthorizationStatus(completedWithResult, expected: (true, .unknown))
        XCTAssertTestCapabilityStatusChecked()
    }

    func test__void_status_equal() {
        XCTAssertEqual(Capability.VoidStatus(), Capability.VoidStatus())
    }

    func test__void_status_meets_requirements() {
        XCTAssertTrue(Capability.VoidStatus().meets(requirement: ()))
    }
}

class AuthorizeTests: TestableCapabilityTestCase {

    func test__authorize() {
        wait(for: authorize)
        XCTAssertTrue(capability.didRequestAuthorization)
    }
}

class AuthorizedForTests: TestableCapabilityTestCase {

    func test__is_mututally_exclusive() {
        XCTAssertTrue(authorizedFor.isMutuallyExclusive)
    }

    func test__default_mututally_exclusive_category() {
        XCTAssertEqual(authorizedFor.category, "TestableCapability")
    }

    func test__custom_mututally_exclusive_category() {
        authorizedFor = AuthorizedFor(capability, category: "testing")
        XCTAssertEqual(authorizedFor.category, "testing")
    }

    func test__has_authorize_dependency() {
        guard let dependency = authorizedFor.dependencies.first else {
            XCTFail("Condition did not return a dependency")
            return
        }

        guard let _ = dependency as? AuthorizeCapabilityProcedure<TestableCapability.Status> else {
            XCTFail("Dependency is not the correct type")
            return
        }
    }

    func test__fails_if_capability_is_not_available() {
        capability.serviceIsAvailable = false
        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnavailable())
    }

    func test__async_fails_if_capability_is_not_available() {
        capability.isAsynchronous = true
        capability.serviceIsAvailable = false
        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnavailable())
    }

    func test__fails_if_requirement_is_not_met() {
        capability.requirement = .maximum
        capability.responseAuthorizationStatus = .minimumAuthorized

        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnauthorized())
    }

    func test__async_fails_if_requirement_is_not_met() {
        capability.isAsynchronous = true
        capability.requirement = .maximum
        capability.responseAuthorizationStatus = .minimumAuthorized

        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnauthorized())
    }

    func test__suceeds_if_requirement_is_met() {
        wait(for: procedure)
        XCTAssertConditionResultSatisfied(authorizedFor.output.value ?? .success(false))
    }

    func test__async_suceeds_if_requirement_is_met() {
        capability.isAsynchronous = true
        wait(for: procedure)
        XCTAssertConditionResultSatisfied(authorizedFor.output.value ?? .success(false))
    }

}






