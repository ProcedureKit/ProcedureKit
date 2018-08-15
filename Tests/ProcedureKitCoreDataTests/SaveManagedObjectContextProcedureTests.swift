//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import CoreData
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

final class SaveManagedObjectContextProcedureTests: ProcedureKitCoreDataTestCase {

    func test__inserting_and_saving() {

        let insert = TransformProcedure<NSPersistentContainer, NSManagedObjectContext> { (container) in
            let managedObjectContext = container.newBackgroundContext()

            let managedObject = TestEntity(context: managedObjectContext)
            managedObject.name = "Hello World"
            managedObject.identifier = "abc-123"

            return managedObjectContext
        }.injectResult(from: coreDataStack)

        let save = SaveManagedObjectContext().injectResult(from: insert)

        fetchTestEntities.addDependency(save)

        wait(for: coreDataStack, insert, save, fetchTestEntities)

        PKAssertProcedureFinished(save)

        guard let testEntity = fetchTestEntities.output.success?.first else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(testEntity.name, "Hello World")
    }
}

