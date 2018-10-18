//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
import ProcedureKit
import Foundation
#endif

import CoreData

protocol ManagedObjectContextProcessing: class {

    var managedObjectContext: Pending<NSManagedObjectContext> { get set }
}

internal final class ProcessManagedObjectContext: GroupProcedure {

    init<Processing: Procedure>(dispatchQueue underlyingQueue: DispatchQueue?, do processing: Processing, in makesManagedObjectContext: MakesBackgroundManagedObjectContext, save shouldSaveManagedObjectContext: Bool) where Processing: ManagedObjectContextProcessing {

        var operations: [Operation] = []

        // 1. Create MOC
        let create = ResultProcedure { makesManagedObjectContext.newBackgroundContext() }
        create.addWillFinishBlockObserver { (procedure, error, _) in
            if let moc = procedure.output.success {
                processing.managedObjectContext = .ready(moc)
            }
        }
        processing.addDependency(create)
        operations.append(create)

        // 2. Perform processing
        operations.append(processing)

        // 3. Save MOC
        if shouldSaveManagedObjectContext {
            let save = SaveManagedObjectContext().injectResult(from: create)
            save.addDependency(processing)
            operations.append(save)
        }

        super.init(dispatchQueue: underlyingQueue, operations: operations)
    }
}
