//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class TransformProcedure<Requirement, Result>: Procedure, ResultInjection {

    public typealias Transform = (Requirement) throws -> Result

    private let transform: Transform

    public var requirement: PendingValue<Requirement> = .pending
    public var result: PendingValue<Result> = .pending

    public init(transform: @escaping Transform) {
        self.transform = transform
        super.init()
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            guard let requirement = requirement.value else {
                throw ProcedureKitError.requirementNotSatisfied()
            }
            result = .ready(try transform(requirement))
        }
        catch { finishingError = error }
    }
}
