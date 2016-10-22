//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest

public class TestableURLSessionTask: Equatable {

    public static func == (lhs: TestableURLSessionTask, rhs: TestableURLSessionTask) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public let uuid = UUID()
    public let completion: () -> Void

    public var didResume = false
    public var didCancel = false

    public init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    public func resume() {
        didResume = true
        completion()
    }

    public func cancel() {
        didCancel = true
    }
}

public class TestableURLSessionTaskFactory {

    public var delay: TimeInterval = 0
    public var returnedResponse: URLResponse? = URLResponse()
    public var returnedError: Error? = nil

    // Data
    public var didReceiveDataRequest: URLRequest? = nil
    public var didReturnDataTask: TestableURLSessionTask? = nil
    public var returnedData: Data? = "hello world".data(using: String.Encoding.utf8)

    // Download
    public var didReceiveDownloadRequest: URLRequest? = nil
    public var didReturnDownloadTask: TestableURLSessionTask? = nil
    public var returnedURL: URL? = URL(fileURLWithPath: "/var/tmp/hello/this/is/a/test/url")

    public init() { }

    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
        didReceiveDataRequest = request
        let task = TestableURLSessionTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                completionHandler(self.returnedData, self.returnedResponse, self.returnedError)
            }
        }
        didReturnDataTask = task
        return task
    }

    public func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
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
