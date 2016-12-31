//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class BlockObserverTests: ProcedureKitTestCase {

    func test__did_attach_is_called() {
        var didAttachCalled: Procedure? = nil
        procedure.add(observer: BlockObserver(didAttach: { didAttachCalled = $0 }))
        XCTAssertEqual(didAttachCalled, procedure)
    }

    func test__will_execute_is_called() {
        var willExecuteCalled: Procedure? = nil
        procedure.add(observer: BlockObserver(willExecute: { willExecuteCalled = $0 }))
        wait(for: procedure)
        XCTAssertEqual(willExecuteCalled, procedure)
    }

    func test__did_execute_is_called() {
        var didExecuteCalled: Procedure? = nil
        procedure.add(observer: BlockObserver(didExecute: { didExecuteCalled = $0 }))
        wait(for: procedure)
        XCTAssertEqual(didExecuteCalled, procedure)
    }

    func test__will_cancel_is_called() {
        var willCancelCalled: (Procedure, [Error])? = nil
        let error = TestError()
        procedure.add(observer: BlockObserver(willCancel: { willCancelCalled = ($0, $1) }))
        check(procedure: procedure) { procedure in
            procedure.cancel(withError: error)
        }
        XCTAssertEqual(willCancelCalled?.0, procedure)
        XCTAssertEqual(willCancelCalled?.1.first as? TestError, error)
    }

    func test__did_cancel_is_called() {
        var didCancelCalled: (Procedure, [Error])? = nil
        let error = TestError()
        procedure.add(observer: BlockObserver(didCancel: { didCancelCalled = ($0, $1) }))
        check(procedure: procedure) { procedure in
            procedure.cancel(withError: error)
        }
        XCTAssertEqual(didCancelCalled?.0, procedure)
        XCTAssertEqual(didCancelCalled?.1.first as? TestError, error)
    }

    func test__will_add_operation_is_called() {
        var willAddCalled: (Procedure, Operation)? = nil
        var didExecuteProducedOperation = false
        let producingProcedure = TestProcedure(produced: BlockOperation { didExecuteProducedOperation = true })
        producingProcedure.add(observer: BlockObserver(willAdd: { willAddCalled = ($0, $1) }))
        wait(for: producingProcedure)
        XCTAssertTrue(didExecuteProducedOperation)
        XCTAssertEqual(willAddCalled?.0, producingProcedure)
        XCTAssertNotNil(willAddCalled?.1)
    }

    func test__did_add_operation_is_called() {
        var didAddCalled: (Procedure, Operation)? = nil
        var didExecuteProducedOperation = false
        let producingProcedure = TestProcedure(produced: BlockOperation { didExecuteProducedOperation = true })
        producingProcedure.add(observer: BlockObserver(didAdd: { didAddCalled = ($0, $1) }))
        wait(for: producingProcedure)
        XCTAssertTrue(didExecuteProducedOperation)
        XCTAssertEqual(didAddCalled?.0, producingProcedure)
        XCTAssertNotNil(didAddCalled?.1)
    }

    func test__will_finish_is_called() {
        var willFinishCalled: (Procedure, [Error])? = nil
        procedure.add(observer: BlockObserver(willFinish: { willFinishCalled = ($0, $1) }))
        wait(for: procedure)
        XCTAssertEqual(willFinishCalled?.0, procedure)
    }

    func test__did_finish_is_called() {
        var didFinishCalled: (Procedure, [Error])? = nil
        procedure.add(observer: BlockObserver(didFinish: { didFinishCalled = ($0, $1) }))
        wait(for: procedure)
        XCTAssertEqual(didFinishCalled?.0, procedure)
    }

}
