//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

class AnyProcedureBox_<Requirement, Result>: GroupProcedure, ResultInjection {
    var requirement: PendingValue<Requirement> = .pending
    var result: PendingValue<Result> { return .pending }
}

class AnyProcedureBox<Base: Procedure>: AnyProcedureBox_<Base.Requirement, Base.Result> where Base: ResultInjection {

    private var base: Base

    public override var requirement: PendingValue<Base.Requirement> {
        get { return base.requirement }
        set { base.requirement = newValue }
    }

    public override var result: PendingValue<Base.Result> {
        return base.result
    }

    public init(dispatchQueue: DispatchQueue? = nil, base: Base) {
        self.base = base
        super.init(dispatchQueue: dispatchQueue, operations: [base])
        log.enabled = false
    }
}

public class AnyProcedure<Requirement, Result>: GroupProcedure, ResultInjection {
    private typealias Erased = AnyProcedureBox_<Requirement, Result>

    private var erased: Erased

    public var requirement: PendingValue<Erased.Requirement> {
        get { return erased.requirement }
        set { erased.requirement = newValue }
    }

    public var result: PendingValue<Erased.Result> {
        return erased.result
    }

    public init<Base>(dispatchQueue: DispatchQueue? = nil, _ base: Base) where Base: Procedure, Base: ResultInjection, Result == Base.Result, Requirement == Base.Requirement {
        erased = AnyProcedureBox(dispatchQueue: dispatchQueue, base: base)
        super.init(dispatchQueue: erased.dispatchQueue, operations: [erased])
        log.enabled = false
    }
}
