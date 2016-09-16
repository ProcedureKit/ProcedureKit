//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

final class TimeoutObserverTests: ProcedureKitTestCase {

    func test__timeout_observer() {
        procedure = TestProcedure(delay: 0.5)
        procedure.add(observer: TimeoutObserver(by: 0.1))
        wait(for: procedure)
        XCTAssertProcedureFinishedWithErrors(count: 1)
    }
}
