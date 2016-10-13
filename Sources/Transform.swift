//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class TransformProcedure<Requirement, Result>: Procedure, ResultInjectionProtocol {

    public typealias Transform = (Requirement) throws -> Result

    private let transform: Transform

    public var requirement: Requirement! = nil
    public var result: Result? = nil

    public init(transform: @escaping Transform) {
        self.transform = transform
        super.init()
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            guard let requirement = requirement else {
                throw ProcedureKitError.requirementNotSatisfied()
            }
            result = try transform(requirement)
        }
        catch { finishingError = error }
    }
}
