//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

public class TestProcedure: Procedure {
    public struct SimulatedError: Error { }

    public let delay: TimeInterval
    public let error: Error?
    public let producedOperation: Operation?
    public private(set) var didExecute = false

    public private(set) var procedureWillFinishCalled = false
    public private(set) var procedureDidFinishCalled = false
    public private(set) var procedureWillCancelCalled = false
    public private(set) var procedureDidCancelCalled = false

    public init(delay: TimeInterval = 0.000_001, error: Error? = .none, produced: Operation? = .none) {
        self.delay = delay
        self.error = error
        self.producedOperation = produced
        super.init()
        name = "Test Procedure"
    }

    public override func execute() {

        if let operation = producedOperation {
            let deadline = DispatchTime(uptimeNanoseconds: UInt64(delay * 0.001 * Double(NSEC_PER_SEC)))
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                self.produce(operation: operation)
            }
        }

        let deadline = DispatchTime(uptimeNanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.didExecute = true
            self.finish(withError: self.error)
        }
    }

    public func procedureWillCancel(withErrors: [Error]) {
        procedureWillCancelCalled = true
    }

    public func procedureDidCancel(withErrors: [Error]) {
        procedureDidCancelCalled = true
    }

    public func procedureWillFinish(withErrors: [Error]) {
        procedureWillFinishCalled = true
    }

    public func procedureDidFinish(withErrors: [Error]) {
        procedureDidFinishCalled = true
    }
}
