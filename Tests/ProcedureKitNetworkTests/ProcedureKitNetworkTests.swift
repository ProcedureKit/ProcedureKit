//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

extension TestableURLSessionTask: URLSessionTaskProtocol, URLSessionDataTaskProtocol, URLSessionDownloadTaskProtocol, URLSessionUploadTaskProtocol { }
extension TestableURLSessionTaskFactory: URLSessionTaskFactory { }

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}

