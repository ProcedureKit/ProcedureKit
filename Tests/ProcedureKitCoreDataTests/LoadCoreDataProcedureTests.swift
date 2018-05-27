//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

final class LoadCoreDataProcedureTests: ProcedureKitTestCase {

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


    func test__load_core_data_stack_with_custom_model() {

        let load = LoadCoreDataProcedure(
            filename: "TestDataModel",
            managedObjectModel: managedObjectModel,
            persistentStoreDescriptions: persistentStoreDescriptions
        )

        wait(for: load)

        XCTAssertProcedureFinishedWithoutErrors(load)

        guard let _ = load.output.success else {
            XCTFail("Did not load container")
            return
        }
    }
}
