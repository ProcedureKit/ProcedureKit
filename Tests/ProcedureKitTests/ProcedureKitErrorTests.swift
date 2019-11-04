//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class ProcedureKitErrorTests: XCTestCase {

    struct TestComponent: ProcedureKitComponent {
        let name = "Test Component"
    }

    var context: ProcedureKitError.Context!

    func test__context_equality_capability() {
        context = .capability(.unavailable)
        XCTAssertEqual(context, ProcedureKitError.capabilityUnavailable().context)
        XCTAssertNotEqual(context, ProcedureKitError.capabilityUnauthorized().context)
        context = .capability(.unauthorized)
        XCTAssertEqual(context, ProcedureKitError.capabilityUnauthorized().context)
        XCTAssertNotEqual(context, ProcedureKitError.capabilityUnavailable().context)
    }

    func test__context_equality_component() {
        context = .component(TestComponent())
        XCTAssertEqual(context, ProcedureKitError.component(TestComponent(), error: TestError()).context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_conditionFailed() {
        context = .conditionFailed
        XCTAssertEqual(context, ProcedureKitError.conditionFailed().context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_dependenciesFailed() {
        context = .dependenciesFailed
        XCTAssertEqual(context, ProcedureKitError.dependenciesFailed().context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_dependenciesCancelled() {
        context = .dependenciesCancelled
        XCTAssertEqual(context, ProcedureKitError.dependenciesCancelled().context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_dependencyFinishedWithErrors() {
        context = .dependencyFinishedWithError
        XCTAssertEqual(context, ProcedureKitError.dependency(finishedWithError: TestError()).context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_dependencyCancelledWithErrors() {
        context = .dependencyCancelledWithError
        XCTAssertEqual(context, ProcedureKitError.dependency(cancelledWithError: TestError()).context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_noQueue() {
        context = .noQueue
        XCTAssertEqual(context, ProcedureKitError.noQueue().context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_parentCancelledWithErrors() {
        context = .parentCancelledWithError
        XCTAssertEqual(context, ProcedureKitError.parent(cancelledWithError: TestError()).context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_programmingError() {
        context = .programmingError("Houston, we have a problem.")
        XCTAssertEqual(context, ProcedureKitError.programmingError(reason: "Houston, we have a problem.").context)
        XCTAssertNotEqual(context, ProcedureKitError.programmingError(reason: "Houston, we have a different problem.").context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_requirementNotSatisfied() {
        context = .requirementNotSatisfied
        XCTAssertEqual(context, ProcedureKitError.requirementNotSatisfied().context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_timedOut() {
        context = .timedOut(.by(10))
        XCTAssertEqual(context, ProcedureKitError.timedOut(with: .by(10)).context)
        XCTAssertNotEqual(context, ProcedureKitError.timedOut(with: .by(5)).context)
        XCTAssertNotEqual(context, ProcedureKitError.Context.unknown)
    }

    func test__context_equality_unknown() {
        context = .unknown
        XCTAssertEqual(context, ProcedureKitError.unknown.context)
    }

}
