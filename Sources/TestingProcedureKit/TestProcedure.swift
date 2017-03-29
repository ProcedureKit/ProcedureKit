//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

public struct TestError: Error, Equatable, CustomDebugStringConvertible {
    public static func == (lhs: TestError, rhs: TestError) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public static func verify(errors: [Error], count: Int = 1, contains error: TestError) -> Bool {
        return (errors.count == count) && errors.contains { ($0 as? TestError) ?? TestError() == error }
    }

    let uuid = UUID()
    public init() { }

    public var debugDescription: String {
        return "TestError (\(uuid.uuidString))"
    }
}

open class TestProcedure: Procedure, InputProcedure, OutputProcedure {

    public let delay: TimeInterval
    public let error: Error?
    public let producedOperation: Operation?
    public var input: Pending<Void> = pendingVoid
    public var output: Pending<ProcedureResult<String>> = .ready(.success("Hello World"))
    public private(set) var executedAt: CFAbsoluteTime {
        get { return protected.read { $0.executedAt } }
        set { protected.write { $0.executedAt = newValue } }
    }
    public private(set) var didExecute: Bool {
        get { return protected.read { $0.didExecute } }
        set { protected.write { $0.didExecute = newValue } }
    }
    public private(set) var procedureWillFinishCalled: Bool {
        get { return protected.read { $0.procedureWillFinishCalled } }
        set { protected.write { $0.procedureWillFinishCalled = newValue } }
    }
    public private(set) var procedureDidFinishCalled: Bool {
        get { return protected.read { $0.procedureDidFinishCalled } }
        set { protected.write { $0.procedureDidFinishCalled = newValue } }
    }
    public private(set) var procedureDidCancelCalled: Bool {
        get { return protected.read { $0.procedureDidCancelCalled } }
        set { protected.write { $0.procedureDidCancelCalled = newValue } }
    }
    private class ProtectedProperties {
        var executedAt: CFAbsoluteTime = 0
        var didExecute = false
        var procedureWillFinishCalled = false
        var procedureDidFinishCalled = false
        var procedureDidCancelCalled = false
    }
    private var protected = Protector(ProtectedProperties())

    public init(name: String = "TestProcedure", delay: TimeInterval = 0.000_001, error: Error? = .none, produced: Operation? = .none) {
        self.delay = delay
        self.error = error
        self.producedOperation = produced
        super.init()
        self.name = name
    }

    open override func execute() {

        executedAt = CFAbsoluteTimeGetCurrent()

        if let operation = producedOperation {
            DispatchQueue.main.asyncAfter(deadline: .now() + (delay / 2.0)) {
                try! self.produce(operation: operation) // swiftlint:disable:this force_try
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.didExecute = true
            self.finish(withError: self.error)
        }
    }

    open override func procedureDidCancel(withErrors: [Error]) {
        procedureDidCancelCalled = true
    }

    open override func procedureWillFinish(withErrors: [Error]) {
        procedureWillFinishCalled = true
    }

    open override func procedureDidFinish(withErrors: [Error]) {
        procedureDidFinishCalled = true
    }
}
