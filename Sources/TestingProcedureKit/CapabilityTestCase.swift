//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public class TestableCapability: CapabilityProtocol {

    public enum Status: AuthorizationStatus {
        public enum Requirement { // swiftlint:disable:this nesting
            case minimum, maximum
        }

        case unknown, restricted, denied, minimumAuthorized, maximumAuthorized

        public func meets(requirement: Requirement?) -> Bool {
            switch (requirement, self) {
            case (.some(.minimum), .minimumAuthorized), (_, .maximumAuthorized):
                return true
            default: return false
            }
        }
    }

    public var requirement: Status.Requirement? = .minimum
    public var isAsynchronous = false
    public var serviceIsAvailable = true
    public var didCheckIsAvailable = false
    public var serviceAuthorizationStatus: Status = .unknown
    public var didCheckAuthorizationStatus = false
    public var responseAuthorizationStatus: Status = .maximumAuthorized
    public var didRequestAuthorization = false

    public func isAvailable() -> Bool {
        didCheckIsAvailable = true
        return serviceIsAvailable
    }

    public func getAuthorizationStatus(_ completion: @escaping (Status) -> Void) {
        didCheckAuthorizationStatus = true
        if isAsynchronous {
            DispatchQueue.initiated.async {
                completion(self.serviceAuthorizationStatus)
            }
        }
        else {
            completion(serviceAuthorizationStatus)
        }
    }

    public func requestAuthorization(withCompletion completion: @escaping () -> Void) {
        didRequestAuthorization = true
        serviceAuthorizationStatus = responseAuthorizationStatus
        if isAsynchronous {
            DispatchQueue.initiated.async(execute: completion)
        }
        else {
            completion()
        }
    }
}

open class TestableCapabilityTestCase: ProcedureKitTestCase {

    public var capability: TestableCapability!
    public var getAuthorizationStatus: GetAuthorizationStatusProcedure<TestableCapability.Status>!
    public var authorize: AuthorizeCapabilityProcedure<TestableCapability.Status>!
    public var authorizedFor: AuthorizedFor<TestableCapability.Status>!

    open override func setUp() {
        super.setUp()
        capability = TestableCapability()
        getAuthorizationStatus = GetAuthorizationStatusProcedure(capability)
        authorize = AuthorizeCapabilityProcedure(capability)
        authorizedFor = AuthorizedFor(capability)
        procedure.add(condition: authorizedFor)
    }

    open override func tearDown() {
        capability = nil
        getAuthorizationStatus.cancel()
        getAuthorizationStatus = nil
        authorize.cancel()
        authorize = nil
        authorizedFor = nil
        super.tearDown()
    }

    public func XCTAssertGetAuthorizationStatus<Status: AuthorizationStatus>(_ exp1: @autoclosure () throws -> (Bool, Status)?, expected exp2: @autoclosure () throws -> (Bool, Status), _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) where Status: Equatable {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let result = try exp1()
            let expected = try exp2()

            guard let (isAvailable, status) = result else {
                return .expectedFailure("GetAuthorizationStatus result was not set.")
            }
            guard isAvailable == expected.0 else {
                return .expectedFailure("Capability's availability was not \(expected.0).")
            }
            guard status == expected.1 else {
                return .expectedFailure("\(status) was not \(expected.1).")
            }
            return .success
        }
    }

    public func XCTAssertTestCapabilityStatusChecked(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            guard capability.didCheckIsAvailable else {
                return .expectedFailure("Capability did not check availability.")
            }
            guard capability.didCheckAuthorizationStatus else {
                return .expectedFailure("Capability did not check authorization status.")
            }
            guard !capability.didRequestAuthorization else {
                return .expectedFailure("Capability did request authorization unexpectedly.")
            }
            return .success
        }
    }
}
