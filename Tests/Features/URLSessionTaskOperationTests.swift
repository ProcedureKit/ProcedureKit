//
//  URLSessionTaskOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 08/04/2016.
//
//

import XCTest
@testable import Operations

class URLSessionTaskOperationTests: OperationTests {

    // TODO: The question is, how to test URLSessionTask
    // stuff without introducing a dependency like DVR?

    typealias FinalSessionTaskDelegateCallback = (NSURLSession, NSURLSessionTask, NSError?) -> Void

    class TestSessionDelegate: NSObject, NSURLSessionTaskDelegate {
        private var finalTaskDelegateMethodObservers = [FinalTaskDelegateMethodObserver]()
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            // should be the last delegate method called for a sessionTask
            for observer in finalTaskDelegateMethodObservers {
                observer.finalDelegateCallbackHandler(session, task, error)
            }
        }

        func addFinalTaskDelegateMethodObserver(observer: FinalTaskDelegateMethodObserver) {
            finalTaskDelegateMethodObservers.append(observer)
        }
    }

    struct FinalTaskDelegateMethodObserver {
        private let finalDelegateCallbackHandler: FinalSessionTaskDelegateCallback

        init(finalDelegateCallbackHandler: FinalSessionTaskDelegateCallback) {
            self.finalDelegateCallbackHandler = finalDelegateCallbackHandler
        }
    }

    var session: NSURLSession!
    var sessionDelegate: TestSessionDelegate!

    override func setUp() {
        super.setUp()
        sessionDelegate = TestSessionDelegate()
        session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: sessionDelegate, delegateQueue: nil)
    }
    
    override func tearDown() {
        session = nil
        super.tearDown()
    }
    
    func test__simple_data_task_with_url_completion_handler() {
        var r_data: NSData?
        var r_response: NSURLResponse?
        var r_error: NSError?
        
        let url = NSURL(string: "https://www.google.com/robots.txt")!
        let expectation = expectationWithDescription("Test: \(#function), completed task")
        
        let operation = URLSessionTaskOperation.dataTask(fromSession: session, withURL: url) { (data, response, error) in
            r_data = data
            r_response = response
            r_error = error
            expectation.fulfill()
        }
        waitForOperation(operation)
        XCTAssertNotNil(r_data)
        XCTAssertNotNil(r_response)
        XCTAssertNil(r_error)
    }
    
    func test__simple_data_task_with_url_delegate() {
        let url = NSURL(string: "https://www.google.com/robots.txt")!
        let actions = Protector<Array<String>>([])
        
        let expectation = expectationWithDescription("Test: \(#function), called final delegate method")
        sessionDelegate.addFinalTaskDelegateMethodObserver( FinalTaskDelegateMethodObserver { (session, task, error) in
            // called final NSURLSessionTaskDelegate method
            actions.append("NSURLSessionTaskDelegate - final task delegate method")
            expectation.fulfill()
        })
        let operation = URLSessionTaskOperation.dataTask(fromSession: session, withURL: url)
        operation.addObserver(DidFinishObserver { (operation, errors) in
            actions.append("URLSessionTaskOperation.DidFinishObserver")
        })
        waitForOperation(operation, withTimeout: 50)
        
        let resultingActions = actions.read { $0 }
        XCTAssertEqual(resultingActions.count, 2)
        XCTAssertEqual(resultingActions[0], "NSURLSessionTaskDelegate - final task delegate method")
        XCTAssertEqual(resultingActions[1], "URLSessionTaskOperation.DidFinishObserver")
    }

}
