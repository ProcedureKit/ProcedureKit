//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

open class ProcedureKitCoreDataTestCase: ProcedureKitTestCase {

    var managedObjectModel: NSManagedObjectModel {
        let bundle = Bundle(for: type(of: self))
        guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            fatalError("Unable to load TestDataModel.xcdatamodeld from test bundle.")
        }
        return model
    }

    var persistentStoreDescriptions: [NSPersistentStoreDescription] {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        return [description]
    }

    var coreDataStack: LoadCoreDataProcedure!

    var fetchTestEntities: TransformProcedure<NSPersistentContainer, [TestEntity]>!

    open override func setUp() {
        super.setUp()

        coreDataStack = LoadCoreDataProcedure(
            name: "TestDataModel",
            managedObjectModel: managedObjectModel,
            persistentStoreDescriptions: persistentStoreDescriptions
        )

        coreDataStack.addWillFinishBlockObserver  { (procedure, errors, _) in
            guard errors.isEmpty, let container = procedure.output.success else { return }
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.undoManager = nil
            container.viewContext.shouldDeleteInaccessibleFaults = true
            container.viewContext.automaticallyMergesChangesFromParent = true
        }

        fetchTestEntities = TransformProcedure<NSPersistentContainer, [TestEntity]> { (container) in
            return try container.viewContext.fetch(TestEntity.fetchRequest())
        }.injectResult(from: coreDataStack)

    }

    open override func tearDown() {
        coreDataStack = nil
        fetchTestEntities = nil
        super.tearDown()
    }
}

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}
