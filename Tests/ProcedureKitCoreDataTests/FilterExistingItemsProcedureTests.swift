//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

fileprivate final class FilterExistingItemsProcedureTestHarness: GroupProcedure, InputProcedure, OutputProcedure {
    typealias Item = (String, String)

    var input: Pending<NSPersistentContainer> = .pending
    var output: Pending<ProcedureResult<[TestEntity]>> = .pending

    let shouldSave: Bool
    let download: ResultProcedure<[Item]>

    var managedObjectContext: NSManagedObjectContext!

    init(items: [Item], andSave shouldSave: Bool = true) {

        self.shouldSave = shouldSave
        self.download = ResultProcedure { items }

        super.init(operations: [download])

        log.severity = .verbose
    }

    override func execute() {

        guard let container = input.value else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }

        managedObjectContext = container.newBackgroundContext()

        let insert = InsertManagedObjectsProcedure<Item, TestEntity>(into: managedObjectContext, andSave: shouldSave) { (_, item, testEntity) in
            testEntity.identifier = item.0
            testEntity.name = item.1
            }.injectResult(from: download)

        insert.addWillFinishBlockObserver { [unowned self] (procedure, errors, _) in
            self.output = procedure.output
        }

        add(child: insert)

        super.execute()
    }
}


final class FilterExistingItemsProcedureTests: ProcedureKitCoreDataTestCase {

    func test__filter_existing_items() {

        let insert = TestInsert(items: items)
            .injectResult(from: coreDataStack)

        let filter = TestFilter(items: items)
            .injectResult(from: coreDataStack)

        filter.add(dependency: insert)

        fetchTestEntities.addDependency(insert)

        LogManager.severity = .info

        wait(for: coreDataStack, insert, filter, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(filter)

        // Check that we actually have items inserted
        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.sorted(), ["Bar", "Bat", "Foo"])

        // Check that the output of the filter is an empty array
        guard let items = filter.output.success else {
            XCTFail("Filter did not finish successfully")
            return
        }

        XCTAssertTrue(items.isEmpty)
    }

    func test__filter_existing_items_with_additional_items() {

        var moreItems: [TestEntityItem] = items; moreItems.append(contentsOf: [
            TestEntityItem(identity: "d-4", name: "Baz")
        ])

        let insert = TestInsert(items: items)
            .injectResult(from: coreDataStack)

        let filter = TestFilter(items: moreItems)
            .injectResult(from: coreDataStack)

        filter.add(dependency: insert)

        fetchTestEntities.addDependency(insert)

        LogManager.severity = .info

        wait(for: coreDataStack, insert, filter, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(filter)

        // Check that we actually have items inserted
        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.sorted(), ["Bar", "Bat", "Foo"])

        // Check that the output of the filter is an empty array
        guard let items = filter.output.success else {
            XCTFail("Filter did not finish successfully")
            return
        }

        XCTAssertEqual(items.count, 1)
    }


    func test__filter_existing_items_with_fewer_items() {

        var moreItems: [TestEntityItem] = items; moreItems.append(contentsOf: [
            TestEntityItem(identity: "d-4", name: "Baz")
            ])

        let insert = TestInsert(items: moreItems)
            .injectResult(from: coreDataStack)

        let filter = TestFilter(items: items)
            .injectResult(from: coreDataStack)

        filter.add(dependency: insert)

        fetchTestEntities.addDependency(insert)

        LogManager.severity = .info

        wait(for: coreDataStack, insert, filter, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(filter)

        // Check that we actually have items inserted
        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.sorted(), ["Bar", "Bat", "Baz", "Foo"])

        // Check that the output of the filter is an empty array
        guard let items = filter.output.success else {
            XCTFail("Filter did not finish successfully")
            return
        }

        XCTAssertEqual(items.count, 0)
    }
}


