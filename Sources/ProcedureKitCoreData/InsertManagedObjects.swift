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

    public var input: Pending<[Item]> = .pending

    public var output: Pending<ProcedureResult<[ManagedObject]>> = .pending

    public let managedObjectContext: NSManagedObjectContext

    /**
     Initialize the Procedure with the NSManagedObjectContext to insert into, and
     a block. For example:

     ```swift
     let insert = InsertManagedObjectsProcedure<MyItem, MyManagedObject>(into: managedObjectContext) { (index, item, managedObject) in
        managedObject.identifier = item.identifier
        managedObject.name = item.name
     }.injectResult(from: downloadItems)
     ```
     In the above example, we assume that `downloadItems` has an output of `[MyItem]`.

     - parameter into: the NSManagedObjectContext to insert objects into
     - parameter andSave: a Bool, default true, which if set to false will not save the context.
     - parameter block: a `(Int, Item, ManagedObject) -> ()` block, the arguments are the index in the
             array of items, the item this index, and the inserted managed object which represents the item.
    */
    public init(into managedObjectContext: NSManagedObjectContext, andSave shouldSave: Bool = true, block: @escaping (Int, Item, ManagedObject) -> ()) {

        let insert = AsyncTransformProcedure<Input, Output> { (items, finishWithResult) in

            guard items.count > 0 else {
                finishWithResult(.success([]))
                return
            }

            managedObjectContext.perform {

                let result: Output = items.enumerated().map { (enumeratedItem) in
                    let managed = ManagedObject(context: managedObjectContext)
                    block(enumeratedItem.0, enumeratedItem.1, managed)
                    return managed
                }

                finishWithResult(.success(result))
            }
        }

        let save = SaveManagedObjectContext(managedObjectContext)

        self.managedObjectContext = managedObjectContext

        super.init(operations: [insert])
        name = "Insert \(ManagedObject.entityName)"

        if shouldSave {
            save.add(dependency: insert)
            add(child: save)
        }

        bind(to: insert)
    }
}
