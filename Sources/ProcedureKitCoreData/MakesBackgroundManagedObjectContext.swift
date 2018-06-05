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
 Abstracts the producer of a background context into a protocol
 to allow framework consumers to provide any source of a context
 */
public protocol MakesBackgroundManagedObjectContext {

    func newBackgroundContext() -> NSManagedObjectContext
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension NSPersistentContainer: MakesBackgroundManagedObjectContext { }

extension NSManagedObjectContext: MakesBackgroundManagedObjectContext {

    public func newBackgroundContext() -> NSManagedObjectContext {

        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = self
        moc.undoManager = nil
        return moc
    }
}

extension NSPersistentStoreCoordinator: MakesBackgroundManagedObjectContext {

    public func newBackgroundContext() -> NSManagedObjectContext {

        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self
        return moc
    }
}


