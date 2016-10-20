//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

class AnyProcedureBox_<Requirement, Result>: GroupProcedure, ResultInjectionProtocol {
    var requirement: Requirement!
    var result: Result! { return nil }
}

class AnyProcedureBox<Base: Procedure>: AnyProcedureBox_<Base.Requirement, Base.Result> where Base: ResultInjectionProtocol {

    private var base: Base

    public override var requirement: Base.Requirement! {
        get { return base.requirement }
        set { base.requirement = newValue }
    }

    public override var result: Base.Result! {
        return base.result
    }

    public init(underlyingQueue: DispatchQueue? = nil, base: Base) {
        self.base = base
        super.init(underlyingQueue: underlyingQueue, operations: [base])
        log.enabled = false
    }
}

public class AnyProcedure<Requirement, Result>: GroupProcedure, ResultInjectionProtocol {
    private typealias Erased = AnyProcedureBox_<Requirement, Result>

    private var erased: Erased

    public var requirement: Erased.Requirement {
        get { return erased.requirement }
        set { erased.requirement = newValue }
    }

    public var result: Erased.Result {
        return erased.result
    }

    public init<Base>(underlyingQueue: DispatchQueue? = nil, _ base: Base) where Base: Procedure, Base: ResultInjectionProtocol, Result == Base.Result, Requirement == Base.Requirement {
        erased = AnyProcedureBox(underlyingQueue: underlyingQueue, base: base)
        super.init(underlyingQueue: erased.underlyingQueue, operations: [erased])
        log.enabled = false
    }
}
