//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class TestableURLSessionTask: URLSessionTaskProtocol, URLSessionDataTaskProtocol, URLSessionDownloadTaskProtocol, Equatable {

    static func == (lhs: TestableURLSessionTask, rhs: TestableURLSessionTask) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    let uuid = UUID()
    let completion: () -> Void

    var didResume = false
    var didCancel = false

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func resume() {
        didResume = true
        completion()
    }

    func cancel() {
        didCancel = true
    }
}

class TestableURLSessionTaskFactory: URLSessionTaskFactory {

    var delay: TimeInterval = 0
    var returnedResponse: URLResponse? = URLResponse()
    var returnedError: Error? = nil

    // Data
    var didReceiveDataRequest: URLRequest? = nil
    var didReturnDataTask: TestableURLSessionTask? = nil
    var returnedData: Data? = "hello world".data(using: String.Encoding.utf8)

    // Download
    var didReceiveDownloadRequest: URLRequest? = nil
    var didReturnDownloadTask: TestableURLSessionTask? = nil
    var returnedURL: URL? = URL(fileURLWithPath: "/var/tmp/hello/this/is/a/test/url")

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
        didReceiveDataRequest = request
        let task = TestableURLSessionTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                completionHandler(self.returnedData, self.returnedResponse, self.returnedError)
            }
        }
        didReturnDataTask = task
        return task
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
        didReceiveDownloadRequest = request
        let task = TestableURLSessionTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                completionHandler(self.returnedURL, self.returnedResponse, self.returnedError)
            }
        }
        didReturnDownloadTask = task
        return task
    }
}

