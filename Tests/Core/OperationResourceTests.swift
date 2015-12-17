//
//  OperationResourceTests.swift
//  Operations
//
//  Created by di, frank (CHE-LPR) on 12/17/15.
//
//

import XCTest
@testable import Operations

class OperationResourceTests: XCTestCase {
    
    let queue = OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test__int_resource_retrieved() {
        let expectIntResource = expectationWithDescription("Test: \(__FUNCTION__)")
        let testOp = TestNeedResourceOperation {
            op in
            XCTAssertEqual(op.resourceForType(Int), 1)
            expectIntResource.fulfill()
        }
        testOp.addResourceProvider(TestResourceProvider(resource: 1))
        queue.addOperation(testOp)
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func test__string_resource_retrieved() {
        let expectStringResource = expectationWithDescription("Test: \(__FUNCTION__)")
        let testOp = TestNeedResourceOperation {
            op in
            XCTAssertEqual(op.resourceForType(String), "String resource")
            expectStringResource.fulfill()
        }
        testOp.addResourceProvider(TestResourceProvider(resource: "String resource"))
        queue.addOperation(testOp)
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func test__tuple_resource_retrieved() {
        let expectTupleResource = expectationWithDescription("Test: \(__FUNCTION__)")
        let testOp = TestNeedResourceOperation {
            op in
            let resource = op.resourceForType(Int, String, Double)
            XCTAssertEqual(resource?.0, 1)
            XCTAssertEqual(resource?.1, "1")
            XCTAssertEqual(resource?.2, 2.0)
            expectTupleResource.fulfill()
        }
        testOp.addResourceProvider(TestResourceProvider(resource: (1, "1", 2.0)))
        queue.addOperation(testOp)
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func test__object_resource_retrieved() {
        let object = NSObject()
        let expectObject = expectationWithDescription("Test: \(__FUNCTION__)")
        let testOp = TestNeedResourceOperation {
            op in
            XCTAssertEqual(op.resourceForType(NSObject), object)
            expectObject.fulfill()
        }
        testOp.addResourceProvider(TestResourceProvider(resource: object))
        queue.addOperation(testOp)
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func test__multiple_resource_retrieved() {
        let object = NSObject()
        let operation = BlockOperation()
        let string = "String resource"
        let int = 2
        let expectMultiple = expectationWithDescription("Test: \(__FUNCTION__)")
        let testOp = TestNeedResourceOperation {
            op in
            XCTAssertEqual(op.resourceForType(NSObject), object)
            XCTAssertEqual(op.resourceForType(BlockOperation), operation)
            XCTAssertEqual(op.resourceForType(String), string)
            XCTAssertEqual(op.resourceForType(Int), int)
            expectMultiple.fulfill()
        }
        testOp.addResourceProvider(TestResourceProvider(resource: object))
        testOp.addResourceProvider(TestResourceProvider(resource: operation))
        testOp.addResourceProvider(TestResourceProvider(resource: string))
        testOp.addResourceProvider(TestResourceProvider(resource: int))
        queue.addOperation(testOp)
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}

class TestNeedResourceOperation: Operation {
    let checkResource: Operation -> Void
    init(checkResource: Operation -> Void) {
        self.checkResource = checkResource
        super.init()
    }
    override func execute() {
        checkResource(self)
        finish()
    }
}

class TestResourceProvider<T>: OperationResourceProvider {
    
    let provide: T
    var produce: T?
    
    init(resource: T) {
        self.provide = resource
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return BlockOperation {
            self.produce = self.provide
        }
    }
    
    func collectResourceForOperation(operation: Operation, completion: Any? -> Void) {
        completion(produce)
    }
}
