//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

final class LoadCoreDataProcedureTests: ProcedureKitCoreDataTestCase {

    func test__load_core_data_stack_with_custom_model() {

        wait(for: coreDataStack)

        PKAssertProcedureFinished(coreDataStack)

        guard let _ = coreDataStack.output.success else {
            XCTFail("Did not load container")
            return
        }
    }
}
