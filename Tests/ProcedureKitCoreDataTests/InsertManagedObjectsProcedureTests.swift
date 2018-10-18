//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

final class InsertManagedObjectsProcedureTests: ProcedureKitCoreDataTestCase {

    func test__insert_multiple_items_and_save() {

        let insert = TestInsert(items: items)
            .injectResult(from: coreDataStack)

        fetchTestEntities.addDependency(insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        PKAssertProcedureFinished(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.sorted(), ["Bar", "Bat", "Foo"])
    }

    func test__insert_empty_items() {

        let insert = TestInsert(items: [])
            .injectResult(from: coreDataStack)

        fetchTestEntities.addDependency(insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        PKAssertProcedureFinished(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.count, 0)
    }

    func test__insert_multiple_items_dont_save() {

        let insert = TestInsert(items: items, andSave: false)
            .injectResult(from: coreDataStack)

        fetchTestEntities.addDependency(insert)

        wait(for: coreDataStack, insert, fetchTestEntities)

        PKAssertProcedureFinished(insert)

        guard let names = fetchTestEntities.output.success?.map({ $0.name! }) else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(names.count, 0)
    }
}
