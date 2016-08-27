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

    public var operationQueueWillAddOperation = [OperationQueueCheckType]()
    public var operationQueueWillFinishOperation = [OperationQueueCheckType]()
    public var operationQueueDidFinishOperation = [OperationQueueCheckType]()

    public var procedureQueueWillAddOperation = [ProcedureQueueCheckType]()
    public var procedureQueueWillProduceOperation = [ProcedureQueueCheckType]()
    public var procedureQueueWillFinishOperation = [ProcedureQueueCheckTypeWithErrors]()
    public var procedureQueueDidFinishOperation = [ProcedureQueueCheckTypeWithErrors]()


    public func operationQueue(_ queue: OperationQueue, willAddOperation operation: Operation) {
        operationQueueWillAddOperation.append((queue, operation))
    }

    public func operationQueue(_ queue: OperationQueue, willFinishOperation operation: Operation) {
        operationQueueWillFinishOperation.append((queue, operation))
    }

    public func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Operation) {
        operationQueueDidFinishOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation) {
        procedureQueueWillAddOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation) {
        procedureQueueWillProduceOperation.append((queue, operation))
    }

    public func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error]) {
        procedureQueueWillFinishOperation.append((queue, operation, errors))
    }

    public func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [Error]) {
        procedureQueueDidFinishOperation.append((queue, operation, errors))
    }
}
