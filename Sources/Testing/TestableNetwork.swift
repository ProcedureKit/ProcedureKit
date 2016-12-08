//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public class TestableURLSessionTask: Equatable {

    public static func == (lhs: TestableURLSessionTask, rhs: TestableURLSessionTask) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public typealias CompletionBlock = (TestableURLSessionTask) -> Void

    public let delay: TimeInterval
    public let uuid = UUID()

    public var didResume: Bool {
        get { return stateLock.withCriticalScope { _didResume } }
    }
    public var didCancel: Bool {
        get { return stateLock.withCriticalScope { _didCancel } }
    }

    private let completion: CompletionBlock
    private var completionWorkItem: DispatchWorkItem!
    private var stateLock = NSLock()
    private var _didResume = false
    private var _didCancel = false
    private var _didFinish = false

    public init(delay: TimeInterval = 0.000_001, completion: @escaping CompletionBlock) {
        self.delay = delay
        self.completion = completion
        self.completionWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.completionWorkItem.isCancelled else { return }
            guard strongSelf.shouldFinish() else { return }
            completion(strongSelf)
        })
    }

    public func resume() {
        stateLock.withCriticalScope {
            _didResume = true
        }
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + delay, execute: completionWorkItem)
    }

    public func cancel() {
        // Behavior: cancel the delayed completion, and call the completion handler immediately
        stateLock.withCriticalScope {
            _didCancel = true
            completionWorkItem.cancel()
        }
        guard shouldFinish() else { return }
        completion(self)
    }

    private func shouldFinish() -> Bool {
        return stateLock.withCriticalScope { () -> Bool in
            guard !_didFinish else { return false }
            _didFinish = true
            return true
        }
    }
}

public class TestableURLSessionTaskFactory {

    public var delay: TimeInterval = 0
    public var returnedResponse: HTTPURLResponse? = HTTPURLResponse()
    public var returnedError: Error? = nil

    // Data
    public var didReceiveDataRequest: URLRequest? = nil
    public var didReturnDataTask: TestableURLSessionTask? = nil
    public var returnedData: Data? = "hello world".data(using: String.Encoding.utf8)

    // Download
    public var didReceiveDownloadRequest: URLRequest? = nil
    public var didReturnDownloadTask: TestableURLSessionTask? = nil
    public var returnedURL: URL? = URL(fileURLWithPath: "/var/tmp/hello/this/is/a/test/url")

    // Upload
    public var didReceiveUploadRequest: URLRequest? = nil
    public var didReturnUploadTask: TestableURLSessionTask? = nil

    public init() { }

    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
        didReceiveDataRequest = request
        let task = TestableURLSessionTask(delay: delay) { (task) in
            DispatchQueue.main.async {
                guard !task.didCancel else {
                    completionHandler(nil, nil, self.cancelledError(forRequest: request))
                    return
                }
                completionHandler(self.returnedData, self.returnedResponse, self.returnedError)
            }
        }
        didReturnDataTask = task
        return task
    }

    public func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {
        didReceiveDownloadRequest = request
        let task = TestableURLSessionTask(delay: delay) { (task) in
            DispatchQueue.main.async {
                guard !task.didCancel else {
                    completionHandler(nil, nil, self.cancelledError(forRequest: request))
                    return
                }
                completionHandler(self.returnedURL, self.returnedResponse, self.returnedError)
            }
        }
        didReturnDownloadTask = task
        return task
    }

    public func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> TestableURLSessionTask {

        didReceiveUploadRequest = request
        let task = TestableURLSessionTask(delay: delay) { (task) in
            DispatchQueue.main.async {
                guard !task.didCancel else {
                    completionHandler(nil, nil, self.cancelledError(forRequest: request))
                    return
                }
                completionHandler(self.returnedData, self.returnedResponse, self.returnedError)
            }
        }
        didReturnUploadTask = task
        return task
    }

    private func cancelledError(forRequest request: URLRequest) -> Error {
        var userInfo: [AnyHashable: Any] = [NSLocalizedDescriptionKey: "cancelled"]
        if let requestURL = request.url {
            userInfo[NSURLErrorFailingURLErrorKey] = requestURL
        }
        if let requestURLString = request.url?.absoluteString {
            userInfo[NSURLErrorFailingURLStringErrorKey] = requestURLString
        }
        return NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: userInfo)
    }
}
