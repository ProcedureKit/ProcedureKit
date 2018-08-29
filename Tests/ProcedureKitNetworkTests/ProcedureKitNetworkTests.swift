//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

extension TestableURLSessionTask: URLSessionTaskProtocol, NetworkDataTask, NetworkDownloadTask, NetworkUploadTask { }
extension TestableURLSessionTaskFactory: NetworkSession {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkDataTask {
        let task: TestableURLSessionTask = dataTask(with: request, completionHandler: completionHandler)
        return task
    }
    
    public func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> NetworkDownloadTask {
        let task: TestableURLSessionTask = downloadTask(with: request, completionHandler: completionHandler)
        return task
    }
    
    public func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkUploadTask {
        let task: TestableURLSessionTask = uploadTask(with: request, from: bodyData, completionHandler: completionHandler)
        return task
    }
}

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}

