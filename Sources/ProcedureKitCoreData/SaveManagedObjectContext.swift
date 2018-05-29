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

/**
 This procedure will save a NSManagedObjectContext. It can be used directly, if the
 context is available at initializaton, via:

 ```swift
 queue.add(operation: SaveManagedObjectContext(managedObjectContext))
 ```

 Alternatively, if the managedObjectContext is not available like this, it can be
 injected with it before execution.

 ```swift
 let coreDataStack = LoadCoreDataProcedure(name: "MyModels")

 let processManagedObjects = ProcessManagedObjects()
     .injectResult(from: coreDataStack)

 let save = SaveManagedObjectContext()
     .injectResult(from: processManagedObjects)

 queue.add(operations:
    coreDataStack,
    processManagedObjects,
    save)
 ```
 */
open class SaveManagedObjectContext: AsyncTransformProcedure<NSManagedObjectContext, Void> {

    public init(_ managedObjectContext: NSManagedObjectContext? = nil) {

        super.init { (managedObjectContext, finishWithResult) in

            guard managedObjectContext.hasChanges else {
                finishWithResult(success)
                return
            }

            managedObjectContext.perform {
                do {
                    try managedObjectContext.save()
                    finishWithResult(success)
                }
                catch {
                    finishWithResult(.failure(error))
                }
            }
        }

        if let moc = managedObjectContext {
            input = .ready(moc)
        }
    }
}
