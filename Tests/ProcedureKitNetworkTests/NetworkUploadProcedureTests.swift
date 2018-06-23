//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
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
    var upload: NetworkUploadProcedure!

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
        PKAssertProcedureFinished(upload)
        XCTAssertEqual(session.didReceiveUploadRequest?.url, url)
    }

    func test__session_creates_upload_task() {
        wait(for: upload)
        PKAssertProcedureFinished(upload)
        XCTAssertNotNil(session.didReturnUploadTask)
        XCTAssertEqual(session.didReturnUploadTask, upload.task as? TestableURLSessionTask)
    }

    func test__upload_resumes_data_task() {
        wait(for: upload)
        PKAssertProcedureFinished(upload)
        XCTAssertTrue(session.didReturnUploadTask?.didResume ?? false)
    }

    // MARK: Cancellation

    func test__upload_cancels_data_task_is_cancelled() {
        session.delay = 2.0
        let delay = DelayProcedure(by: 0.1)
        delay.addDidFinishBlockObserver { _, _ in
            self.upload.cancel()
        }
        wait(for: upload, delay)
        PKAssertProcedureCancelled(upload)
        XCTAssertTrue(session.didReturnUploadTask?.didCancel ?? false)
    }

    func test__upload_cancelled_while_executing() {
        session.delay = 2.0
        upload.addDidExecuteBlockObserver { (procedure) in
            procedure.cancel()
        }
        wait(for: upload)
        PKAssertProcedureCancelled(upload)
    }

    func test__upload_cancelled_does_not_call_completion_handler() {
        session.delay = 2.0
        var calledCompletionHandler = false
        upload = NetworkUploadProcedure(session: session, request: request, data: sendingData) { _ in
            DispatchQueue.onMain {
                calledCompletionHandler = true
            }
        }
        upload.addDidExecuteBlockObserver { (procedure) in
            procedure.cancel()
        }
        wait(for: upload)
        PKAssertProcedureCancelled(upload)
        XCTAssertFalse(calledCompletionHandler)
    }

    // MARK: Finishing

    func test__no_requirement__finishes_with_error() {
        upload = NetworkUploadProcedure(session: session) { _ in }
        wait(for: upload)
        PKAssertProcedureFinishedWithError(upload, ProcedureKitError.requirementNotSatisfied())
    }

    func test__no_data__finishes_with_error() {
        session.returnedData = nil
        wait(for: upload)
        PKAssertProcedureFinishedWithError(upload, ProcedureKitError.unknown)
    }

    func test__session_error__finishes_with_error() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        session.returnedError = error
        wait(for: upload)
        PKAssertProcedureFinishedWithError(upload, error)
    }

    func test__completion_handler_receives_data_and_response() {
        var completionHandlerDidExecute = false
        upload = NetworkUploadProcedure(session: session, request: request, data: sendingData) { result in
            XCTAssertEqual(result.value?.payload, self.session.returnedData)
            XCTAssertEqual(result.value?.response, self.session.returnedResponse)
            completionHandlerDidExecute = true
        }
        wait(for: upload)
        PKAssertProcedureFinished(upload)
        XCTAssertTrue(completionHandlerDidExecute)
    }

}
