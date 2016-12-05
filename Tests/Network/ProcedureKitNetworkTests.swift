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
extension TestableURLSessionTask {
    public func addObserver(_ observer: NSObject, forKeyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutableRawPointer?) { }
    public func removeObserver(_ observer: NSObject, forKeyPath: String) { }
    
    public var countOfBytesExpectedToReceive: Int64 {
        return 100
    }
    
    public var countOfBytesReceived: Int64 {
        return 100
    }
    
    public var countOfBytesSent: Int64 {
        return 100
    }
    
    public var countOfBytesExpectedToSend: Int64 {
        return 100
    }
}

extension TestableURLSessionTaskFactory: URLSessionTaskFactory { }

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}

