//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class NetworkUploadProcedureTests: ProcedureKitTestCase {
    
    var url: URL!
    var request: URLRequest!
    var sendingData: Data!
    var session: TestableURLSessionTaskFactory!
    var upload: NetworkUploadProcedure<TestableURLSessionTaskFactory>!

    override func setUp() {
        super.setUp()
        url = "http://procedure.kit.run"
        sendingData = "hello world".data(using: .utf8)

        request = URLRequest(url: url)
        session = TestableURLSessionTaskFactory()
        upload = NetworkUploadProcedure(session: session, request: request, data: sendingData)
    }

    override func tearDown() {
        url = nil
        request = nil
        session = nil
        upload = nil
        super.tearDown()
    }

    func test__session_receives_request() {
        wait(for: upload)
        XCTAssertProcedureFinishedWithoutErrors(upload)
        XCTAssertEqual(session.didReceiveUploadRequest?.url, url)
    }

    func test__session_creates_upload_task() {
        wait(for: upload)
        XCTAssertProcedureFinishedWithoutErrors(upload)
        XCTAssertNotNil(session.didReturnUploadTask)
        XCTAssertEqual(session.didReturnUploadTask, upload.task)
    }

    func test__upload_resumes_data_task() {
        wait(for: upload)
        XCTAssertProcedureFinishedWithoutErrors(upload)
        XCTAssertTrue(session.didReturnUploadTask?.didResume ?? false)
    }


    func test__upload_cancels_data_task_is_cancelled() {
        session.delay = 2.0
        let delay = DelayProcedure(by: 0.1)
        delay.addDidFinishBlockObserver { _ in
            self.upload.cancel()
        }
        wait(for: upload, delay)
        XCTAssertProcedureCancelledWithoutErrors(upload)
        XCTAssertTrue(session.didReturnUploadTask?.didCancel ?? false)
    }

    func test__no_requirement__finishes_with_error() {
        upload = NetworkUploadProcedure(session: session) { _ in }
        wait(for: upload)
        XCTAssertProcedureFinishedWithErrors(upload, count: 1)
        XCTAssertEqual(upload.errors.first as? ProcedureKitError, ProcedureKitError.requirementNotSatisfied())
    }

    func test__no_data__finishes_with_error() {
        session.returnedData = nil
        wait(for: upload)
        XCTAssertProcedureFinishedWithErrors(upload, count: 1)
    }

    func test__session_error__finishes_with_error() {
        session.returnedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        wait(for: upload)
        XCTAssertProcedureFinishedWithErrors(upload, count: 1)
        XCTAssertNotNil(upload.networkError)
    }

    func test__completion_handler_receives_data_and_response() {
        var completionHandlerDidExecute = false
        upload = NetworkUploadProcedure(session: session, request: request, data: sendingData) { result in
            XCTAssertEqual(result.payload, self.session.returnedData)
            XCTAssertEqual(result.response, self.session.returnedResponse)
            completionHandlerDidExecute = true
        }
        wait(for: upload)
        XCTAssertProcedureFinishedWithoutErrors(upload)
        XCTAssertTrue(completionHandlerDidExecute)
    }

}
