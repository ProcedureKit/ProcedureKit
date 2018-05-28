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

    open override func setUp() {
        super.setUp()

        coreDataStack = LoadCoreDataProcedure(
            name: "TestDataModel",
            managedObjectModel: managedObjectModel,
            persistentStoreDescriptions: persistentStoreDescriptions
        )
    }
}

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}
