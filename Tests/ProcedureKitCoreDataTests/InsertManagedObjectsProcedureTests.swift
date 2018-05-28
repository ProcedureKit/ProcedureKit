//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

fileprivate final class InsertManagedObjectsProcedureTestHarness: GroupProcedure, InputProcedure, OutputProcedure {
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

final class InsertManagedObjectsProcedureTests: ProcedureKitCoreDataTestCase {

    var items: [(String, String)] = [
        ("a-1", "Foo"),
        ("b-2", "Bar"),
        ("c-3", "Bat")
    ]

    func test__insert_multiple_items_and_save() {

        let insert = InsertManagedObjectsProcedureTestHarness(items: items)
            .injectResult(from: coreDataStack)

        fetchTestEntities.add(dependency: insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.sorted(), ["Bar", "Bat", "Foo"])
    }

    func test__insert_empty_items() {

        let insert = InsertManagedObjectsProcedureTestHarness(items: [])
            .injectResult(from: coreDataStack)

        fetchTestEntities.add(dependency: insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.count, 0)
    }

    func test__insert_multiple_items_dont_save() {

        let insert = InsertManagedObjectsProcedureTestHarness(items: items, andSave: false)
            .injectResult(from: coreDataStack)

        fetchTestEntities.add(dependency: insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        XCTAssertProcedureFinishedWithoutErrors(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.count, 0)
        XCTAssertTrue(insert.managedObjectContext.hasChanges)

    }
}
