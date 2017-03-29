//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

public class QueueTestDelegate: ProcedureQueueDelegate {

    public typealias OperationCheckType = (ProcedureQueue, Operation, Any?)
    public typealias OperationFinishType = (ProcedureQueue, Operation)
    public typealias ProcedureCheckType = (ProcedureQueue, Procedure, Any?)
    public typealias ProcedureFinishType = (ProcedureQueue, Procedure, [Error])

    public var procedureQueueWillAddOperation: [OperationCheckType] {
        get { return _procedureQueueWillAddOperation.read { $0 } }
    }
    public var procedureQueueDidAddOperation: [OperationCheckType] {
        get { return _procedureQueueDidAddOperation.read { $0 } }
    }
    public var procedureQueueDidFinishOperation: [OperationFinishType] {
        get { return _procedureQueueDidFinishOperation.read { $0 } }
    }

    public var procedureQueueWillAddProcedure: [ProcedureCheckType] {
        get { return _procedureQueueWillAddProcedure.read { $0 } }
    }
    public var procedureQueueDidAddProcedure: [ProcedureCheckType] {
        get { return _procedureQueueDidAddProcedure.read { $0 } }
    }

    public var procedureQueueWillFinishProcedure: [ProcedureFinishType] {
        get { return _procedureQueueWillFinishProcedure.read { $0 } }
    }
    public var procedureQueueDidFinishProcedure: [ProcedureFinishType] {
        get { return _procedureQueueDidFinishProcedure.read { $0 } }
    }

    private var _procedureQueueWillAddOperation = Protector([OperationCheckType]())
    private var _procedureQueueDidAddOperation = Protector([OperationCheckType]())
    private var _procedureQueueDidFinishOperation = Protector([OperationFinishType]())

    private var _procedureQueueWillAddProcedure = Protector([ProcedureCheckType]())
    private var _procedureQueueDidAddProcedure = Protector([ProcedureCheckType]())
    private var _procedureQueueWillFinishProcedure = Protector([ProcedureFinishType]())
    private var _procedureQueueDidFinishProcedure = Protector([ProcedureFinishType]())

    // MARK: - Init

    public init() { }

    // MARK: - ProcedureQueueDelegate Methods

    // Operations

    public func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation, context: Any?) -> ProcedureFuture? {
        _procedureQueueWillAddOperation.append((queue, operation, context))
        return nil
    }

    public func procedureQueue(_ queue: ProcedureQueue, didAddOperation operation: Operation, context: Any?) {
        _procedureQueueDidAddOperation.append((queue, operation, context))
    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation) {
        _procedureQueueDidFinishOperation.append((queue, operation))
    }

    // Procedures

    public func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        _procedureQueueWillAddProcedure.append((queue, procedure, context))
        return nil
    }

    public func procedureQueue(_ queue: ProcedureQueue, didAddProcedure procedure: Procedure, context: Any?) {
        _procedureQueueDidAddProcedure.append((queue, procedure, context))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, withErrors errors: [Error]) -> ProcedureFuture? {
        _procedureQueueWillFinishProcedure.append((queue, procedure, errors))
        return nil
    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        _procedureQueueDidFinishProcedure.append((queue, procedure, errors))
    }
}
