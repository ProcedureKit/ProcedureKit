//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

public class QueueTestDelegate: ProcedureQueueDelegate, OperationQueueDelegate {

    public typealias OperationQueueCheckType = (OperationQueue, Operation)
    public typealias ProcedureQueueCheckType = (ProcedureQueue, Operation)
    public typealias ProcedureQueueCheckTypeWithErrors = (ProcedureQueue, Operation, [Error])

    public var operationQueueWillAddOperation: [OperationQueueCheckType] {
        get { return _operationQueueWillAddOperation.read { $0 } }
    }
    public var operationQueueWillFinishOperation: [OperationQueueCheckType] {
        get { return _operationQueueWillFinishOperation.read { $0 } }
    }
    public var operationQueueDidFinishOperation: [OperationQueueCheckType] {
        get { return _operationQueueDidFinishOperation.read { $0 } }
    }

    public var procedureQueueWillAddOperation: [ProcedureQueueCheckType] {
        get { return _procedureQueueWillAddOperation.read { $0 } }
    }
    public var procedureQueueWillProduceOperation: [ProcedureQueueCheckType] {
        get { return _procedureQueueWillProduceOperation.read { $0 } }
    }
    public var procedureQueueWillFinishOperation: [ProcedureQueueCheckTypeWithErrors] {
        get { return _procedureQueueWillFinishOperation.read { $0 } }
    }
    public var procedureQueueDidFinishOperation: [ProcedureQueueCheckTypeWithErrors] {
        get { return _procedureQueueDidFinishOperation.read { $0 } }
    }

    private var _operationQueueWillAddOperation = Protector([OperationQueueCheckType]())
    private var _operationQueueWillFinishOperation = Protector([OperationQueueCheckType]())
    private var _operationQueueDidFinishOperation = Protector([OperationQueueCheckType]())

    private var _procedureQueueWillAddOperation = Protector([ProcedureQueueCheckType]())
    private var _procedureQueueWillProduceOperation = Protector([ProcedureQueueCheckType]())
    private var _procedureQueueWillFinishOperation = Protector([ProcedureQueueCheckTypeWithErrors]())
    private var _procedureQueueDidFinishOperation = Protector([ProcedureQueueCheckTypeWithErrors]())

    public func operationQueue(_ queue: OperationQueue, willAddOperation operation: Operation) {
        _operationQueueWillAddOperation.append((queue, operation))
    }

    public func operationQueue(_ queue: OperationQueue, willFinishOperation operation: Operation) {
        _operationQueueWillFinishOperation.append((queue, operation))
    }

    public func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Operation) {
        _operationQueueDidFinishOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation) {
        _procedureQueueWillAddOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation) {
        _procedureQueueWillProduceOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        _procedureQueueWillFinishOperation.append((queue, operation, errors))
    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [Error]) {
        _procedureQueueDidFinishOperation.append((queue, operation, errors))
    }
}
