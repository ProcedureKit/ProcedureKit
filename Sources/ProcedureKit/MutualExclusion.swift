//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/**
 A generic condition for describing operations that
 cannot be allowed to execute concurrently.
 */
public final class MutuallyExclusive<T>: Condition {

    /// Public constructor
    public init(category: String = "MutuallyExclusive<\(T.self)>") {
        super.init()
        name = "MutuallyExclusive<\(T.self)>"
        mutuallyExclusiveCategory = category
    }

    /// Required public override, but there is no evaluation, so it just completes with `.Satisfied`.
    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.success(true))
    }
}

final public class ExclusivityManager {

    static let sharedInstance = ExclusivityManager()

    fileprivate let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Exclusivity", qos: DispatchQoS.userInitiated) // serial dispatch queue
    fileprivate var procedures: [String: [Procedure]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func add(procedure: Procedure, category: String) -> Operation? {
        return queue.sync { _add(procedure: procedure, category: category) }
    }

    func remove(procedure: Procedure, category: String) {
        queue.async { self._remove(procedure: procedure, category: category) }
    }

    fileprivate func _add(procedure: Procedure, category: String) -> Operation? {
        procedure.log.verbose(message: ">>> \(category)")

        procedure.addDidFinishBlockObserver { [unowned self] (procedure, errors) in
            self.remove(procedure: procedure, category: category)
        }

        var proceduresWithThisCategory = procedures[category] ?? []

        let previous = proceduresWithThisCategory.last

        if let previous = previous {
            procedure.add(dependencyOnPreviousMutuallyExclusiveProcedure: previous)
        }

        proceduresWithThisCategory.append(procedure)

        procedures[category] = proceduresWithThisCategory

        return previous
    }

    fileprivate func _remove(procedure: Procedure, category: String) {
        procedure.log.verbose(message: "<<< \(category)")

        if let proceduresWithThisCategory = procedures[category], let index = proceduresWithThisCategory.index(of: procedure) {
            var mutableProceduresWithThisCategory = proceduresWithThisCategory
            mutableProceduresWithThisCategory.remove(at: index)
            procedures[category] = mutableProceduresWithThisCategory
        }
    }
}

public extension ExclusivityManager {

    static func __tearDownForUnitTesting() {
        sharedInstance.__tearDownForUnitTesting()
    }

    /// This should only be used as part of the unit testing
    fileprivate func __tearDownForUnitTesting() {
        queue.sync {
            for (category, procedures) in procedures {
                for procedure in procedures {
                    procedure.cancel()
                    _remove(procedure: procedure, category: category)
                }
            }
        }
    }
}
