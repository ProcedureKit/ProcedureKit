//
//  AddressBookConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import XCTest
import AddressBook

@testable import Operations

class TestableAddressBookRegistrar: AddressBookPermissionRegistrar {

    var didAccessStatus = false
    var didCreateAddressBook = false
    var didRequestAccess = false
    var requestShouldSucceed = true

    var status: ABAuthorizationStatus

    var addressBook: CFTypeRef! = nil

    var creationError: CFErrorRef! = nil
    var accessError: CFErrorRef! = nil

    init(status: ABAuthorizationStatus) {
        self.status = status
    }

    func createAddressBook() -> (ABAddressBookRef?, AddressBookPermissionRegistrarError?) {
        didCreateAddressBook = true

        if let _ = creationError {
            return (.None, AddressBookPermissionRegistrarError.AddressBookAccessDenied)
        }
        else if let addressBook: CFTypeRef = addressBook {
            return (addressBook as ABAddressBookRef, .None)
        }
        return (.None, AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
    }

    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: (AddressBookPermissionRegistrarError?) -> Void) {
        didRequestAccess = true
        if requestShouldSucceed {
            status = .Authorized
            completion(nil)
        }
        else {
            status = .Denied
            if let _ = accessError {
                completion(AddressBookPermissionRegistrarError.AddressBookAccessDenied)
            }
            else {
                completion(AddressBookPermissionRegistrarError.AddressBookUnknownErrorOccured)
            }
        }
    }
}

class AddressBookOperationTests: OperationTests {

    var registrar: TestableAddressBookRegistrar!

    override func setUp() {
        super.setUp()
        registrar = TestableAddressBookRegistrar(status: .Authorized)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        registrar.addressBook = posedAddressBook as CFTypeRef
    }

    func test__given_authorization_granted__access_succeeds() {

        var didStart = false
        var didSucceed = false
        let operation = AddressBookOperation(registrar: registrar)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                didStart = true
            },
            finishHandler: { (_, errors) in
                didSucceed = errors.isEmpty
            }
        ))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(didStart)
        XCTAssertTrue(registrar.didRequestAccess)
        XCTAssertTrue(didSucceed)
    }

    func test__given_authorization_denied__access_fails() {
        var didStart = false
        var didSucceed = false
        var receivedErrors = [ErrorType]()

        registrar.status = .NotDetermined
        registrar.requestShouldSucceed = false

        let operation = AddressBookOperation(registrar: registrar)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                didStart = true
            },
            finishHandler: { (_, errors) in
                didSucceed = errors.isEmpty
                receivedErrors = errors
            }
        ))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(didStart)
        XCTAssertTrue(registrar.didRequestAccess)
        XCTAssertFalse(didSucceed)

        if let error = receivedErrors.first as? AddressBookPermissionRegistrarError {
            switch error {
            case .AddressBookUnknownErrorOccured:
                break
            default:
                XCTFail("Incorrect AddressBookPermissionRegistrarError type received")
            }
        }
        else {
            XCTFail("Incorrect error type received")
        }
    }
}

class AddressBookConditionTests: OperationTests {

    var registrar: TestableAddressBookRegistrar!

    override func setUp() {
        super.setUp()
        registrar = TestableAddressBookRegistrar(status: .NotDetermined)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        registrar.addressBook = posedAddressBook as CFTypeRef
        registrar.requestShouldSucceed = true
    }

    func test__given_authorization_granted__condition_succeeds() {

        let operation = TestOperation()
        operation.addCondition(AddressBookCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(registrar.didRequestAccess)
        XCTAssertTrue(operation.didExecute)
    }

    func test__given_authorization_denied__condition_fails() {
        registrar.requestShouldSucceed = false

        var receivedErrors = [ErrorType]()

        let operation = TestOperation()
        operation.addCondition(AddressBookCondition(registrar: registrar))

        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(registrar.didRequestAccess)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? AddressBookCondition.Error {
            switch error {
            case .AuthorizationDenied:
                break
            default:
                XCTFail("Incorrect AddressBookCondition.Error type received")
            }
        }
        else {
            XCTFail("Incorrect error type received")
        }
    }

}















/**




class TestableAddressBookManager: AddressBookAuthenticationManager {

    var didAccessStatus = false
    var didCreateAddressBook = false
    var didRequestAccess = false

    var status: ABAuthorizationStatus

    var requestShouldSucceed = true
    var addressBook: CFTypeRef! = nil
    var error: CFErrorRef! = nil

    init(_ s: ABAuthorizationStatus) {
        status = s
    }

    func createAddressBook() -> (ABAddressBookRef!, CFErrorRef!) {
        didCreateAddressBook = true

        if let error = error {
            return (nil, error)
        }
        else if let addressBook: CFTypeRef = addressBook {
            return (addressBook as ABAddressBookRef, nil)
        }
            return (nil, nil)
    }

    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler) {
        didRequestAccess = true
        if requestShouldSucceed {
            status = .Authorized
        }
        else {
            status = .Denied
        }
        completion(requestShouldSucceed, error)
    }
}

class AddressBookOperationTests: OperationTests {

    func test__when_authorized__handler_receives_addressbook() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let manager = TestableAddressBookManager(.Authorized)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        manager.addressBook = posedAddressBook as CFTypeRef

        var didReceiveAddressBook = false
        let operation = AddressBookOperation(manager: manager, suppressPermissionRequest: false) { (addressBook, continueWithError) in
            if let addressBook = addressBook as? String {
                didReceiveAddressBook = addressBook == posedAddressBook
            }
            continueWithError(error: nil)
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(didReceiveAddressBook)
    }


    func test__when_not_determined__manager_requests_permission() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let manager = TestableAddressBookManager(.NotDetermined)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        manager.addressBook = posedAddressBook as CFTypeRef

        var didReceiveAddressBook = false
        let operation = AddressBookOperation(manager: manager, suppressPermissionRequest: false) { (addressBook, continueWithError) in
            if let addressBook = addressBook as? String {
                didReceiveAddressBook = addressBook == posedAddressBook
            }
            continueWithError(error: nil)
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(manager.didRequestAccess)
        XCTAssertTrue(didReceiveAddressBook)
    }

    func test__when_not_determined_but_suppresed__manager_does_not_request_permission() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let manager = TestableAddressBookManager(.NotDetermined)
        manager.requestShouldSucceed = false
        
        var didExecuteHandler = false
        let operation = AddressBookOperation(manager: manager, suppressPermissionRequest: true) { (addressBook, continueWithError) in
            didExecuteHandler = true
            continueWithError(error: nil)
        }

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(manager.didRequestAccess)
        XCTAssertFalse(didExecuteHandler)
        if let error = receivedErrors.first as? AddressBookCondition.Error {
            XCTAssertTrue(error == AddressBookCondition.Error.AuthorizationNotDetermined)
        }
        else {
            XCTFail("No error message was observed")
        }
    }
}





*/

#endif
