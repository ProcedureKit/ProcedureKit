//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//


import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMac

class ProcessProcedureTests: ProcedureKitTestCase {

    var process: Process!
    var processProcedure: ProcessProcedure!

    override func setUp() {
        super.setUp()

        process = Process()
        process.launchPath = "/bin/echo"
        process.arguments = [ "Hello World" ]
        processProcedure = ProcessProcedure(process: process)
    }

    func test__start_process() {
        wait(for: processProcedure)
        XCTAssertProcedureFinishedWithoutErrors(processProcedure)
    }
}
