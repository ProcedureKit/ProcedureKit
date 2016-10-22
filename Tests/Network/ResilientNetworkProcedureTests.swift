//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

struct Behavior: ResilientNetworkBehavior {
    var maximumNumberOfAttempts: Int = 3
    var timeoutBackoffStrategy: WaitStrategy = .constant(1)
    var errorDelay: Delay? = nil
    var subsequentAttemptDelay: Delay = .by(0.1)

    var retryRequestForResponseWithStatusCode: (Int) -> Bool = { _ in true }

    func retryRequest(forResponseWithStatusCode statusCode: Int) -> Bool {
        return retryRequestForResponseWithStatusCode(statusCode)
    }
}

class ResilientNetworkProcedureTests: ProcedureKitTestCase {

    var session: TestableURLSessionTaskFactory!
    var behavior: Behavior!
    var download: ResilientNetworkProcedure<NetworkDataProcedure<TestableURLSessionTaskFactory>>!

    override func setUp() {
        super.setUp()
        session = TestableURLSessionTaskFactory()
        behavior = Behavior()
        download = ResilientNetworkProcedure(behavior: behavior) { NetworkDataProcedure(session: self.session, request: URLRequest(url: "http://procedure.kit.run")) }
    }

    func test__for_reals() {
        download = ResilientNetworkProcedure(behavior: behavior) { NetworkDataProcedure(session: URLSession.shared, request: URLRequest(url: "http://procedure.kit.run")) }
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
    }

    func test__given__valid_response__then_one_request_made() {
        wait(for: download)
        XCTAssertProcedureFinishedWithoutErrors(download)
        XCTAssertEqual(download.count, 1)
        XCTAssertEqual(download.data, session.returnedData)
    }

    func test__given__error_response__then_one_request_made() {
        session.returnedResponse = HTTPURLResponse(url: "http://procedure.kit.run", statusCode: 500, httpVersion: nil, headerFields: nil)
        wait(for: download)
        XCTAssertProcedureFinishedWithErrors(download, count: 1)
        XCTAssertEqual(download.count, 1)
    }

}

