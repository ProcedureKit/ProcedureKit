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
 A Procedure subclass which abstracts the details of inserting managed objects. This
 subclass is designed for the very common scenario where an array of items (such as
 might get returned as a network response) needs parsing/mapping to Entities in
 Core Data.

 Considering this, lets assume that there is another Procedure which will return
 the array of items (perhaps parsed from a JSON network response into an array of
 structs). There is deliberately no constrains on this type - so it could be Void.

 The procedure is initialized with a managed object context, and a block. The
 block receives both the Item value, and the NSManagedObject instance. This can be
 used to set the properties on the managed object.

 Lastly the managed object context is saved.
 */
@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
open class InsertManagedObjectsProcedure<Item, ManagedObject>: GroupProcedure, InputProcedure, OutputProcedure where ManagedObject: NSManagedObject {

    public typealias ProcessingBlock = (Int, Item, ManagedObject) -> ()

    private class Insert: Procedure, InputProcedure, OutputProcedure, ManagedObjectContextProcessing {

        var input: Pending<[Item]> = .pending

        var output: Pending<ProcedureResult<[NSManagedObjectID]>> = .pending

        var managedObjectContext: Pending<NSManagedObjectContext> = .pending

        let block: ProcessingBlock

        init(_ block: @escaping ProcessingBlock) {
            self.block = block
            super.init()
        }

        override func execute() {

            guard
                let managedObjectContext = managedObjectContext.value,
                let items = input.value
            else {
                finish(with: ProcedureKitError.requirementNotSatisfied())
                return
            }

            guard items.count > 0 else {
                finish(withResult: .success([]))
                return
            }

            let result: Output = managedObjectContext.performAndWait {
                return items.enumerated().map { (enumeratedItem) in
                    let managed = ManagedObject(context: managedObjectContext)
                    block(enumeratedItem.0, enumeratedItem.1, managed)
                    return managed.objectID
                }
            }

            finish(withResult: .success(result))
        }
    }

    public var input: Pending<[Item]> = .pending

    public var output: Pending<ProcedureResult<[NSManagedObjectID]>> = .pending

    /**
     Initialize the Procedure with the NSManagedObjectContext to insert into, and
     a block. For example:

     ```swift
     let insert = InsertManagedObjectsProcedure<MyItem, MyManagedObject>(into: managedObjectContext) { (index, item, managedObject) in
        managedObject.identifier = item.identifier
        managedObject.name = item.name
     }.injectResult(from: downloadItems)
     ```
     In the above example, we assume that `downloadItems` has an output
       of `[MyItem]`, and `MyItem` is a PONSO or "dumb" struct type. Certainly
       it must be a type which is safe to be used across threads (so not another
       NSManagedObject instance).

     - parameter dispatchQueue: an optional DispatchQueue to specify.
     - parameter into: a MakesBackgroundManagedObjectContext type,
         which in turn will create a new background context to insert into.
     - parameter andSave: a Bool, default true, which if set to
         false will not save the context.
     - parameter block: a `(Int, Item, ManagedObject) -> ()` block,
         the arguments are the index in the array of items, the
         item this index, and the inserted managed object which
         represents the item.
    */
    public init(dispatchQueue: DispatchQueue? = nil, into makesManagedObjectContext: MakesBackgroundManagedObjectContext, andSave shouldSave: Bool = true, block: @escaping ProcessingBlock) {

        let queue: DispatchQueue = dispatchQueue ?? .initiated

        let insert = Insert(block)

        let processing = ProcessManagedObjectContext(dispatchQueue: queue, do: insert, in: makesManagedObjectContext, save: shouldSave)
        processing.name = "Processing Inserts of \(ManagedObject.entityName)"

        super.init(dispatchQueue: queue, operations: [processing])
        name = "Insert \(ManagedObject.entityName)"

        bind(to: insert)
        bind(from: insert)
    }
}
