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

        let read = TransformProcedure<NSPersistentContainer, [TestEntity]> { (container) in
            return try container.viewContext.fetch(TestEntity.fetchRequest())
        }.injectResult(from: coreDataStack)

        read.add(dependency: save)

        wait(for: coreDataStack, insert, save, read)

        XCTAssertProcedureFinishedWithoutErrors(save)

        guard let testEntity = read.output.success?.first else {
            XCTFail("Did not fetch any test entities.")
            return
        }

        XCTAssertEqual(testEntity.name, "Hello World")
    }
}

