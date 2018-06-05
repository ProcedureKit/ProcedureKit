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
 Core Data has no concept of unique-ness (partly because it is an object store, not a
 database). As a result, if Core Data is being used to store managed object representation
 of data which are not user generated, then typically, some sort of 'de-duping' is
 needed.

 This procedure can be used to filter out items which have identifiers on managed objects
 already in Core Data. This way, it can be used to de-dupe an array of items before
 they are inserted.

 - note: This does not remove duplicate managed objects from Core Data. It looks up
 managed objects which are already in Core Data, and then removes from the a source array.

 You should use it like this (probably inside a custom GroupProcedure):

 ```swift
 typealias Filter = FilteredExistingItemsProcedure<Item, ManagedItem>
 typealias Insert = InsertManagedObjectsProcedure<Item, ManagedItem>
 
 let filter = Filter(from: managedObjectContext)
     .injectResult(from: downloadItems)

 let insert = Insert(into: managedObjectContext)
      .injectResult(from: filter)

 add(children: filter, insert)
 ```
 */
open class FilteredExistingItemsProcedure<Item, ManagedObject>: Procedure, InputProcedure, OutputProcedure where Item: Identifiable, ManagedObject: NSManagedObject, ManagedObject: Identifiable, Item.Identity == ManagedObject.Identity {

    public var input: Pending<[Item]> = .pending
    public var output: Pending<ProcedureResult<[Item]>> = .pending

    public let managedObjectContext: NSManagedObjectContext

    public init(from makesManagedObjectContext: MakesBackgroundManagedObjectContext) {
        self.managedObjectContext = makesManagedObjectContext.newBackgroundContext()
        super.init()
        name = "Filter Existing \(ManagedObject.entityName)"
    }

    open override func execute() {

        guard let source = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        var items: [Item] = source

        defer {
            log.info(message: "Filtered \(source.count - items.count) items.")

            finish(withResult: .success(items))
        }

        do {

            let existing = try fetchExistingIdentities(from: source)

            guard existing.count > 0 else { return }

            items = items.filter { false == existing.contains($0.identity) }
        }
        catch { return }
    }

    private func makeRequest(using source: [Item]) -> NSFetchRequest<NSDictionary> {
        let request = NSFetchRequest<NSDictionary>(entityName: ManagedObject.entityName)
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = ["identifier"]
        request.predicate = NSPredicate(format: "identifier in %@", source.map { $0.identity })
        return request
    }

    private func fetchExistingIdentities(from source: [Item]) throws -> Set<Item.Identity> {

        let request = makeRequest(using: source)

        return try managedObjectContext.performAndWait {

            let result = try managedObjectContext.fetch(request)

            let existing: Set<Item.Identity> = Set(result.compactMap { (dictionary) in
                guard let keyValuePair = dictionary as? [String: Any] else { return nil }
                return keyValuePair["identifier"] as? Item.Identity
            })

            log.notice(message: "Found \(existing.count) \(ManagedObject.entityName) entries in Core Data with identifiers matching source items.")

            return existing
        }
    }
}
