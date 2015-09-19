//
//  MutualExclusiveTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class MutualExclusiveTests: XCTestCase {

    func test__alert_presentation_name() {
        let condition = AlertPresentation()
        XCTAssertEqual(condition.name, "MutuallyExclusive<Alert>")
    }

    func test__alert_presentation_is_mutually_exclusive() {
        let condition = AlertPresentation()
        XCTAssertTrue(condition.isMutuallyExclusive)
    }

    func test__alert_presentation_evaluation_satisfied() {
        let condition = AlertPresentation()
        condition.evaluateForOperation(TestOperation()) { result in
            switch result {
            case .Satisfied:
                return XCTAssertTrue(true)
            default:
                return XCTFail("Alert presentation condition should evaluate true.")
            }
        }
    }

    func test__mutually_exclusive() {
        let queue = OperationQueue()
        let op1 = TestOperation(delay: 1.0)
        op1.addCondition(MutuallyExclusive<TestOperation>())
        XCTAssertTrue(op1.dependencies.isEmpty)

        let op2 = TestOperation(delay: 1.0)
        op2.addCondition(MutuallyExclusive<TestOperation>())
        XCTAssertTrue(op2.dependencies.isEmpty)

        queue.addOperation(op1)
        queue.addOperation(op2)
        XCTAssertTrue(op1.dependencies.isEmpty)
        XCTAssertEqual(op2.dependencies.first, op1)
    }
}

