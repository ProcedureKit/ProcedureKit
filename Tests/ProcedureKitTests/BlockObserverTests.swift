//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit
import Dispatch

class BlockObserverTests: ProcedureKitTestCase {

    func test__did_attach_is_called() {
        let didAttachCalled = Protector<Procedure?>(nil)
        procedure.add(observer: BlockObserver(didAttach: { didAttachCalled.overwrite(with: $0) }))
        wait(for: procedure)
        XCTAssertEqual(didAttachCalled.access, procedure)
    }

    func test__will_execute_is_called() {
        let willExecuteCalled = Protector<Procedure?>(nil)
        procedure.add(observer: BlockObserver(willExecute: { willExecuteCalled.overwrite(with: $0.0) }))
        wait(for: procedure)
        XCTAssertEqual(willExecuteCalled.access, procedure)
    }

    func test__did_execute_is_called() {
        let didExecuteCalled = Protector<Procedure?>(nil)
        procedure.add(observer: BlockObserver(didExecute: { didExecuteCalled.overwrite(with: $0) }))
        wait(for: procedure)
        XCTAssertEqual(didExecuteCalled.access, procedure)
    }

    func test__did_cancel_is_called() {
        let didCancelCalled = Protector<(Procedure, [Error])?>(nil)
        let error = TestError()
        procedure.add(observer: BlockObserver(didCancel: { didCancelCalled.overwrite(with: ($0, $1)) }))
        check(procedure: procedure) { procedure in
            procedure.cancel(withError: error)
        }
        XCTAssertEqual(didCancelCalled.access?.0, procedure)
        XCTAssertEqual(didCancelCalled.access?.1.first as? TestError, error)
    }

    func test__will_add_operation_is_called() {
        let willAddCalled = Protector<(Procedure, Operation)?>(nil)
        var didExecuteProducedOperation = false
        let producingProcedure = TestProcedure(produced: BlockOperation { didExecuteProducedOperation = true })
        producingProcedure.add(observer: BlockObserver(willAdd: { willAddCalled.overwrite(with: ($0, $1)) }))
        wait(for: producingProcedure)
        XCTAssertTrue(didExecuteProducedOperation)
        XCTAssertEqual(willAddCalled.access?.0, producingProcedure)
        XCTAssertNotNil(willAddCalled.access?.1)
    }

    func test__did_add_operation_is_called() {
        let didAddCalled = Protector<(Procedure, Operation)?>(nil)
        var didExecuteProducedOperation = false
        let producingProcedure = TestProcedure(produced: BlockOperation { didExecuteProducedOperation = true })
        producingProcedure.add(observer: BlockObserver(didAdd: { didAddCalled.overwrite(with: ($0, $1)) }))
        wait(for: producingProcedure)
        XCTAssertTrue(didExecuteProducedOperation)
        XCTAssertEqual(didAddCalled.access?.0, producingProcedure)
        XCTAssertNotNil(didAddCalled.access?.1)
    }

    func test__will_finish_is_called() {
        let willFinishCalled = Protector<(Procedure, [Error])?>(nil)
        procedure.add(observer: BlockObserver(willFinish: { willFinishCalled.overwrite(with: ($0.0, $0.1)) }))
        wait(for: procedure)
        XCTAssertEqual(willFinishCalled.access?.0, procedure)
    }

    func test__did_finish_is_called() {
        let didFinishCalled = Protector<(Procedure, [Error])?>(nil)
        procedure.add(observer: BlockObserver(didFinish: { didFinishCalled.overwrite(with: ($0, $1)) }))
        wait(for: procedure)
        XCTAssertEqual(didFinishCalled.access?.0, procedure)
    }

}

class BlockObserverSynchronizationTests: ProcedureKitTestCase {

    func test__will_add_observer_synchronized_with_parent_group() {
        class CustomGroup: GroupProcedure {
            let child1 = TestProcedure()
            init() {
                super.init(operations: [child1])
                child1.addWillAddOperationBlockObserver(synchronizedWith: self) { _, _ in
                    // do something on the Group's EventQueue
                    print("in observer")
                }
            }
            override func execute() {
                super.execute()
                // call child1.produce from within the Group's execute(),
                // which is on the Group's EventQueue
                //
                // the resulting willAddOperationBlockObserver is set to
                // also be synchronized with the Group's EventQueue
                //
                // this should succeed without any deadlock
                try! child1.produce(operation: TestProcedure())
            }
        }

        let group = CustomGroup()
        wait(for: group)
    }

    class QueueIdentity {
        let key: DispatchSpecificKey<UInt8>
        let value: UInt8 = 1
        init(queue: DispatchQueue) {
            key = DispatchSpecificKey()
            queue.setSpecific(key: key, value: value)
        }
        var isOnQueue: Bool {
            guard let retrieved = DispatchQueue.getSpecific(key: key) else { return false }
            return value == retrieved
        }
    }

    private func syncTest(block: (QueueProvider, @escaping () -> Bool) -> Void ) {
        // sync with other Procedure (i.e. the other Procedure's eventQueue)
        let otherProcedure = TestProcedure()
        block(otherProcedure, { return otherProcedure.eventQueue.isOnQueue })

        // sync with other EventQueue
        let otherEventQueue = EventQueue(label: "run.kit.procedure.ProcedureKit.Testing.OtherEventQueue")
        block(otherEventQueue, { return otherEventQueue.isOnQueue })

        // sync with DispatchQueue (serial)
        let otherQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Testing.SerialDispatchQueue")
        let otherQueueIdentity = QueueIdentity(queue: otherQueue)
        block(otherQueue, { return otherQueueIdentity.isOnQueue })

        // sync with DispatchQueue (concurrent)
        let otherConcurrentQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Testing.ConcurrentDispatchQueue", attributes: [.concurrent])
        let otherConcurrentQueueIdentity = QueueIdentity(queue: otherConcurrentQueue)
        block(otherConcurrentQueue, { return otherConcurrentQueueIdentity.isOnQueue })
    }

    func test__did_attach_synchronized() {
        syncTest { syncObject, isSynced in
            let didAttachCalled_BlockObserver = Protector<(Procedure, Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, didAttach: { didAttachCalled_BlockObserver.overwrite(with: ($0, isSynced())) }))
            wait(for: procedure)
            XCTAssertEqual(didAttachCalled_BlockObserver.access?.0, procedure)
            XCTAssertTrue(didAttachCalled_BlockObserver.access?.1 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__will_execute_synchronized() {
        syncTest { syncObject, isSynced in
            let willExecuteCalled_addBlock = Protector<(Procedure, Bool)?>(nil)
            let willExecuteCalled_BlockObserver = Protector<(Procedure, Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.addWillExecuteBlockObserver(synchronizedWith: syncObject) { procedure, _ in
                willExecuteCalled_addBlock.overwrite(with: (procedure, isSynced()))
            }
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, willExecute: { willExecuteCalled_BlockObserver.overwrite(with: ($0.0, isSynced())) }))
            wait(for: procedure)
            XCTAssertEqual(willExecuteCalled_addBlock.access?.0, procedure)
            XCTAssertTrue(willExecuteCalled_addBlock.access?.1 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(willExecuteCalled_BlockObserver.access?.0, procedure)
            XCTAssertTrue(willExecuteCalled_BlockObserver.access?.1 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__did_execute_synchronized() {
        syncTest { syncObject, isSynced in
            let didExecuteCalled_addBlock = Protector<(Procedure, Bool)?>(nil)
            let didExecuteCalled_BlockObserver = Protector<(Procedure, Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.addDidExecuteBlockObserver(synchronizedWith: syncObject) { procedure in
                didExecuteCalled_addBlock.overwrite(with: (procedure, isSynced()))
            }
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, didExecute: { didExecuteCalled_BlockObserver.overwrite(with: ($0, isSynced())) }))
            wait(for: procedure)
            XCTAssertEqual(didExecuteCalled_addBlock.access?.0, procedure)
            XCTAssertTrue(didExecuteCalled_addBlock.access?.1 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(didExecuteCalled_BlockObserver.access?.0, procedure)
            XCTAssertTrue(didExecuteCalled_BlockObserver.access?.1 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__did_cancel_synchronized() {
        syncTest { syncObject, isSynced in
            let error = TestError()
            let didCancelCalled_addBlock = Protector<(Procedure, [Error], Bool)?>(nil)
            let didCancelCalled_BlockObserver = Protector<(Procedure, [Error], Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.addDidCancelBlockObserver(synchronizedWith: syncObject) { procedure, errors in
                didCancelCalled_addBlock.overwrite(with: (procedure, errors, isSynced()))
            }
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, didCancel: { didCancelCalled_BlockObserver.overwrite(with: ($0, $1, isSynced())) }))
            check(procedure: procedure) { procedure in
                procedure.cancel(withError: error)
            }
            XCTAssertEqual(didCancelCalled_addBlock.access?.0, procedure)
            XCTAssertEqual(didCancelCalled_addBlock.access?.1.first as? TestError, error)
            XCTAssertTrue(didCancelCalled_addBlock.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__will_add_synchronized() {
        syncTest { syncObject, isSynced in
            var didExecuteProducedOperation = false
            let willAddOperationCalled_addBlock = Protector<(Procedure, Operation, Bool)?>(nil)
            let willAddOperationCalled_BlockObserver = Protector<(Procedure, Operation, Bool)?>(nil)
            let producedOperation = BlockOperation { didExecuteProducedOperation = true }
            let producingProcedure = TestProcedure(produced: producedOperation)
            producingProcedure.addWillAddOperationBlockObserver(synchronizedWith: syncObject) {
                willAddOperationCalled_addBlock.overwrite(with: ($0, $1, isSynced()))
            }
            producingProcedure.add(observer: BlockObserver(synchronizedWith: syncObject, willAdd: { willAddOperationCalled_BlockObserver.overwrite(with: ($0, $1, isSynced())) }))
            wait(for: producingProcedure)
            XCTAssertTrue(didExecuteProducedOperation)
            XCTAssertEqual(willAddOperationCalled_addBlock.access?.0, producingProcedure)
            XCTAssertEqual(willAddOperationCalled_addBlock.access?.1, producedOperation)
            XCTAssertTrue(willAddOperationCalled_addBlock.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(willAddOperationCalled_BlockObserver.access?.0, producingProcedure)
            XCTAssertEqual(willAddOperationCalled_BlockObserver.access?.1, producedOperation)
            XCTAssertTrue(willAddOperationCalled_BlockObserver.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__did_add_synchronized() {
        syncTest { syncObject, isSynced in
            var didExecuteProducedOperation = false
            let didAddOperationCalled_addBlock = Protector<(Procedure, Operation, Bool)?>(nil)
            let didAddOperationCalled_BlockObserver = Protector<(Procedure, Operation, Bool)?>(nil)
            let producedOperation = BlockOperation { didExecuteProducedOperation = true }
            let producingProcedure = TestProcedure(produced: producedOperation)
            producingProcedure.addDidAddOperationBlockObserver(synchronizedWith: syncObject) {
                didAddOperationCalled_addBlock.overwrite(with: ($0, $1, isSynced()))
            }
            producingProcedure.add(observer: BlockObserver(synchronizedWith: syncObject, didAdd: { didAddOperationCalled_BlockObserver.overwrite(with: ($0, $1, isSynced())) }))
            wait(for: producingProcedure)
            XCTAssertTrue(didExecuteProducedOperation)
            XCTAssertEqual(didAddOperationCalled_addBlock.access?.0, producingProcedure)
            XCTAssertEqual(didAddOperationCalled_addBlock.access?.1, producedOperation)
            XCTAssertTrue(didAddOperationCalled_addBlock.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(didAddOperationCalled_BlockObserver.access?.0, producingProcedure)
            XCTAssertEqual(didAddOperationCalled_BlockObserver.access?.1, producedOperation)
            XCTAssertTrue(didAddOperationCalled_BlockObserver.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__will_finish_synchronized() {
        syncTest { syncObject, isSynced in
            let willFinishCalled_addBlock = Protector<(Procedure, [Error], Bool)?>(nil)
            let willFinishCalled_BlockObserver = Protector<(Procedure, [Error], Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.addWillFinishBlockObserver(synchronizedWith: syncObject) { procedure, errors, _ in
                willFinishCalled_addBlock.overwrite(with: (procedure, errors, isSynced()))
            }
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, willFinish: { willFinishCalled_BlockObserver.overwrite(with: ($0.0, $0.1, isSynced())) }))
            wait(for: procedure)
            XCTAssertEqual(willFinishCalled_addBlock.access?.0, procedure)
            XCTAssertTrue(willFinishCalled_addBlock.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(willFinishCalled_BlockObserver.access?.0, procedure)
            XCTAssertTrue(willFinishCalled_BlockObserver.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }

    func test__did_finish_synchronized() {
        syncTest { syncObject, isSynced in
            let didFinishCalled_addBlock = Protector<(Procedure, [Error], Bool)?>(nil)
            let didFinishCalled_BlockObserver = Protector<(Procedure, [Error], Bool)?>(nil)
            let procedure = TestProcedure()
            procedure.addDidFinishBlockObserver(synchronizedWith: syncObject) { procedure, errors in
                didFinishCalled_addBlock.overwrite(with: (procedure, errors, isSynced()))
            }
            procedure.add(observer: BlockObserver(synchronizedWith: syncObject, didFinish: { didFinishCalled_BlockObserver.overwrite(with: ($0, $1, isSynced())) }))
            wait(for: procedure)
            XCTAssertEqual(didFinishCalled_addBlock.access?.0, procedure)
            XCTAssertTrue(didFinishCalled_addBlock.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
            XCTAssertEqual(didFinishCalled_BlockObserver.access?.0, procedure)
            XCTAssertTrue(didFinishCalled_BlockObserver.access?.2 ?? false, "Was not synchronized on \(syncObject).") // was synchronized
        }
    }
}
