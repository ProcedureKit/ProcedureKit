//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCoreData

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
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
