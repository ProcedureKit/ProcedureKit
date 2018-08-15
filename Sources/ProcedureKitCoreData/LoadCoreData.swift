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
`LoadCoreDataProcedure` is a procedure which does the bare minimum to
 instantiate a `NSPersistentContainer` and load the stores.

 ## Usage
 In a production application, we would expect this class to
 be subclassed. Something like this, note the name of the model
 has been set.

 ```swift
final class MakeCoreDataStack: LoadCoreDataProcedure {
    init() {

        // Call the super, with the name of the model file
        super.init(filename: "Earthquakes")

        // Add a will finish observer, to configure the view context
        addWillFinishBlockObserver { (procedure, errors, _) in
            guard errors.isEmpty, let container = procedure.output.success else { return }

            // Sets the merge policy
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            // In this case, we don't want an undo manager on the view context
            container.viewContext.undoManager = nil

            // Keeps the context with loaded objects
            container.viewContext.shouldDeleteInaccessibleFaults = true
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
}
 ```

 In the example above, we add a WillFinishObserver which can be used to configure the
 the container, in this case, the viewContext property, before the MOCs can be used
 throughout the application.

 This container would then be injected as the input into subsequent procedures.
 */
@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
open class LoadCoreDataProcedure: Procedure, OutputProcedure {

    /// - returns: the output Pending<ProcedureResult<<NSPersistentContainer>>
    public var output: Pending<ProcedureResult<NSPersistentContainer>> = .pending

    /// - returns: String the initialized filename, representing the model file
    public let filename: String

    /// - returns: an optional managed object model which will be used if provided.
    public let managedObjectModel: NSManagedObjectModel?

    /// - returns: [NSPersistentStoreDescription] the initialized store descriptions
    public let persistentStoreDescriptions: [NSPersistentStoreDescription]

    public init(name: String, managedObjectModel: NSManagedObjectModel? = nil, persistentStoreDescriptions: [NSPersistentStoreDescription] = []) {
        self.filename = name
        self.managedObjectModel = managedObjectModel
        self.persistentStoreDescriptions = persistentStoreDescriptions
        super.init()
        self.name = "Load Core Data"
        addCondition(MutuallyExclusive<LoadCoreDataProcedure>())
    }

    open override func execute() {

        // Create a persistent container
        let container: NSPersistentContainer

        if let model = managedObjectModel {
            container = NSPersistentContainer(name: filename, managedObjectModel: model)
        }
        else {
            container = NSPersistentContainer(name: filename)
        }

        // Override the persistent store descriptions
        if persistentStoreDescriptions.count > 0 {
            container.persistentStoreDescriptions = persistentStoreDescriptions
        }

        // Load the stores
        container.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                self.finish(withResult: .failure(error))
            }
            self.finish(withResult: .success(container))
        }
    }
}

