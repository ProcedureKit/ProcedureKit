//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

class AnyProcedureBox_<Input, Output>: GroupProcedure, InputProcedure, OutputProcedure {
    var input: Pending<Input> = .pending
    var output: Pending<Result<Output>> { return .pending }
}

class AnyProcedureBox<Base: Procedure>: AnyProcedureBox_<Base.Input, Base.Output> where Base: InputProcedure & OutputProcedure {

    private var base: Base

    public override var input: Pending<Base.Input> {
        get { return base.input }
        set { base.input = newValue }
    }

    public override var output: Pending<Result<Base.Output>> {
        return base.output
    }

    public init(dispatchQueue: DispatchQueue? = nil, base: Base) {
        self.base = base
        super.init(dispatchQueue: dispatchQueue, operations: [base])
        log.enabled = false
    }
}

public class AnyProcedure<Input, Output>: GroupProcedure, InputProcedure, OutputProcedure {
    private typealias Erased = AnyProcedureBox_<Input, Output>

    private var erased: Erased

    public var input: Pending<Erased.Input> {
        get { return erased.input }
        set { erased.input = newValue }
    }

    public var output: Pending<Result<Erased.Output>> {
        return erased.output
    }

    public init<Base: Procedure>(dispatchQueue: DispatchQueue? = nil, _ base: Base) where Base: InputProcedure & OutputProcedure, Output == Base.Output, Input == Base.Input {
        erased = AnyProcedureBox(dispatchQueue: dispatchQueue, base: base)
        super.init(dispatchQueue: erased.dispatchQueue, operations: [erased])
        log.enabled = false
    }
}
