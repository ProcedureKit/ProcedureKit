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

final class MakeFetchedResultsControllerProcedureTests: ProcedureKitCoreDataTestCase {

    func test__make_frc() {

        let makeFRC = MakeFetchedResultControllerProcedure<TestEntity>().injectResult(from: coreDataStack)

        wait(for: coreDataStack, makeFRC)

        PKAssertProcedureFinished(makeFRC)

        guard let _ = makeFRC.output.success else {
            XCTFail("Did not make FRC")
            return
        }
    }
}
