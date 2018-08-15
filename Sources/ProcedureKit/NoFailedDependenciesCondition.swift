//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

public class NoFailedDependenciesCondition: Condition {

    /// Options on how to handle cancellation
    enum CancellationOptions {

        /// Indicates that cancelled dependencies
        /// would trigger a failed condition
        case fail

        /// Indicates that cancelled dependencies
        /// would trigger an ignored condition
        case ignore
    }

    let cancellationOptions: CancellationOptions

    public init(ignoreCancellations: Bool = false) {
        cancellationOptions = ignoreCancellations ? .ignore : .fail
        super.init()
        name = "No Failed Dependencies"
    }

    /**
     Evaluates the procedure with respect to the finished status of its dependencies.

     The condition first checks if any dependencies were cancelled, in which case it
     fails with an `ProcedureKitError.dependenciesCancelled`. Then
     it checks to see if any dependencies failed due to errors, in which case it
     fails with an `ProcedureKitError.dependenciesFailed`.


     - parameter procedure: the `Procedure` which the condition is attached to.
     - parameter completion: the completion block which receives a `ConditionResult`.
     */
    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        let dependencies = procedure.dependencies
        let cancelled = dependencies.filter { $0.isCancelled }
        let failures = dependencies.filter {
            guard let procedure = $0 as? Procedure else { return false }
            return procedure.failed
        }

        switch cancellationOptions {
        case _ where !failures.isEmpty:
            completion(.failure(ProcedureKitError.dependenciesFailed()))
        case .fail where !cancelled.isEmpty:
            completion(.failure(ProcedureKitError.dependenciesCancelled()))
        case .ignore where !cancelled.isEmpty:
            completion(.success(false))
        default:
            completion(.success(true))
        }
    }
}
