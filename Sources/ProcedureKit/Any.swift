//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Dispatch

struct ValueBox<Value> {

    typealias Getter = () -> Value
    typealias Setter = (Value) -> Void

    private let setter: Setter
    private let getter: Getter

    var value: Value {
        get {
            return getter()
        }
        set {
            setter(newValue)
        }
    }

    init(getter: @escaping Getter, setter: @escaping Setter) {
        self.getter = getter
        self.setter = setter
    }
}

enum ProcedureOutputBoxCreator {
    static func outputBox<P: OutputProcedure>(for procedure: P) -> ValueBox<Pending<ProcedureResult<P.Output>>> {
        let getter = { return procedure.output }
        let setter = { procedure.output = $0 }
        let valueBox = ValueBox(getter: getter, setter: setter)
        return valueBox
    }
}

enum ProcedureInputBoxCreator {
    static func inputBox<P: InputProcedure>(for procedure: P) -> ValueBox<Pending<P.Input>> {
        let getter = { return procedure.input }
        let setter = { procedure.input = $0 }
        let valueBox = ValueBox(getter: getter, setter: setter)
        return valueBox
    }
}

public class AnyInputProcedure<Input>: GroupProcedure, InputProcedure {
    private var inputBox: ValueBox<Pending<Input>>
    public var input: Pending<Input> {
        get {
            return self.inputBox.value
        }
        set {
            self.inputBox.value = newValue
        }
    }

    public init<Base: Procedure>(dispatchQueue: DispatchQueue? = nil, _ base: Base) where Base: InputProcedure, Input == Base.Input {
        self.inputBox = ProcedureInputBoxCreator.inputBox(for: base)
        super.init(dispatchQueue: dispatchQueue, operations: [base])
        self.log.enabled = false
    }
}

public class AnyOutputProcedure<Output>: GroupProcedure, OutputProcedure {
    private var outputBox: ValueBox<Pending<ProcedureResult<Output>>>
    public var output: Pending<ProcedureResult<Output>> {
        get {
            return self.outputBox.value
        }
        set {
            self.outputBox.value = newValue
        }
    }

    public init<Base: Procedure>(dispatchQueue: DispatchQueue? = nil, _ base: Base) where Base: OutputProcedure, Output == Base.Output {
        self.outputBox = ProcedureOutputBoxCreator.outputBox(for: base)
        super.init(dispatchQueue: dispatchQueue, operations: [base])
        self.log.enabled = false
    }
}

public class AnyProcedure<Input, Output>: GroupProcedure, InputProcedure, OutputProcedure {
    private var inputBox: ValueBox<Pending<Input>>
    public var input: Pending<Input> {
        get {
            return self.inputBox.value
        }
        set {
            self.inputBox.value = newValue
        }
    }

    private var outputBox: ValueBox<Pending<ProcedureResult<Output>>>
    public var output: Pending<ProcedureResult<Output>> {
        get {
            return self.outputBox.value
        }
        set {
            self.outputBox.value = newValue
        }
    }

    public init<Base: Procedure>(dispatchQueue: DispatchQueue? = nil, _ base: Base) where Base: InputProcedure & OutputProcedure, Output == Base.Output, Input == Base.Input {
        self.inputBox = ProcedureInputBoxCreator.inputBox(for: base)
        self.outputBox = ProcedureOutputBoxCreator.outputBox(for: base)
        super.init(dispatchQueue: dispatchQueue, operations: [base])
        self.log.enabled = false
    }
}
