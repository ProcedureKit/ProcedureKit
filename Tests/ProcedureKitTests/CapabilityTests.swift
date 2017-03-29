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

    func test__authorize_procedure_is_mutually_exclusive() {
        // AuthorizeCapabilityProcedure should have a condition that is:
        //  MutuallyExclusive<AuthorizeCapabilityProcedure<TestableCapability.Status>>
        // with a mutually exclusive category of: 
        //  "AuthorizeCapabilityProcedure(TestableCapability)"

        var foundMutuallyExclusiveCondition = false
        for condition in authorize.conditions {
            guard condition.isMutuallyExclusive else { continue }
            guard condition is MutuallyExclusive<AuthorizeCapabilityProcedure<TestableCapability.Status>> else { continue }
            guard condition.mutuallyExclusiveCategories == ["AuthorizeCapabilityProcedure(TestableCapability)"] else { continue }
            foundMutuallyExclusiveCondition = true
            break
        }

        XCTAssertTrue(foundMutuallyExclusiveCondition, "Failed to find appropriate Mutual Exclusivity condition")
    }
}

class AuthorizedForTests: TestableCapabilityTestCase {

    func test__is_not_mututally_exclusive_by_default() {
        // the AuthorizedFor condition itself does not confer mutual exclusivity by default
        XCTAssertFalse(authorizedFor.isMutuallyExclusive)
    }

    func test__default_mututally_exclusive_category() {
        XCTAssertTrue(authorizedFor.mutuallyExclusiveCategories.isEmpty)
    }

    func test__custom_mututally_exclusive_category() {
        authorizedFor = AuthorizedFor(capability, category: "testing")
        XCTAssertEqual(authorizedFor.mutuallyExclusiveCategories, ["testing"])
    }

    func test__has_authorize_dependency() {
        guard let dependency = authorizedFor.producedDependencies.first else {
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
        XCTAssertProcedureCancelledWithErrors(count: 1)
        XCTAssertProcedure(procedure, firstErrorEquals: ProcedureKitError.capabilityUnavailable())
    }

    func test__async_fails_if_capability_is_not_available() {
        capability.isAsynchronous = true
        capability.serviceIsAvailable = false
        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnavailable())
        XCTAssertProcedureCancelledWithErrors(count: 1)
        XCTAssertProcedure(procedure, firstErrorEquals: ProcedureKitError.capabilityUnavailable())
    }

    func test__fails_if_requirement_is_not_met() {
        capability.requirement = .maximum
        capability.responseAuthorizationStatus = .minimumAuthorized

        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnauthorized())
        XCTAssertProcedureCancelledWithErrors(count: 1)
        XCTAssertProcedure(procedure, firstErrorEquals: ProcedureKitError.capabilityUnauthorized())
    }

    func test__async_fails_if_requirement_is_not_met() {
        capability.isAsynchronous = true
        capability.requirement = .maximum
        capability.responseAuthorizationStatus = .minimumAuthorized

        wait(for: procedure)
        XCTAssertConditionResult(authorizedFor.output.value ?? .success(true), failedWithError: ProcedureKitError.capabilityUnauthorized())
        XCTAssertProcedureCancelledWithErrors(count: 1)
        XCTAssertProcedure(procedure, firstErrorEquals: ProcedureKitError.capabilityUnauthorized())
    }

    func test__suceeds_if_requirement_is_met() {
        wait(for: procedure)
        XCTAssertConditionResultSatisfied(authorizedFor.output.value ?? .success(false))
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__async_suceeds_if_requirement_is_met() {
        capability.isAsynchronous = true
        wait(for: procedure)
        XCTAssertConditionResultSatisfied(authorizedFor.output.value ?? .success(false))
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__negated_authorized_for_and_no_failed_dependencies_succeeds() {
        // See: Issue #515
        // https://github.com/ProcedureKit/ProcedureKit/issues/515
        //
        // This test previously failed because dependencies of Conditions
        // were incorporated into the dependencies of the parent Procedure
        // and, thus, the NoFailedDependenciesCondition picked up the
        // failing dependencies of the NegatedCondition.
        //

        // set the TestableCapability so it fails to meet the requirement
        capability.requirement = .maximum
        capability.responseAuthorizationStatus = .minimumAuthorized

        let procedure = TestProcedure()
        let authorizedCondition = AuthorizedFor(capability)

        procedure.add(condition: NegatedCondition(authorizedCondition))
        procedure.add(condition: NoFailedDependenciesCondition())

        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }
}






