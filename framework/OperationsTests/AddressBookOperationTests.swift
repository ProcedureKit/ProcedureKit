//
//  BlockConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import AddressBook
import Operations

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

        let manager = TestableAddressBookManager(.Authorized)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        manager.addressBook = posedAddressBook as CFTypeRef

        var didReceiveAddressBook = false
        let operation = AddressBookOperation(manager: manager, silent: false) { (addressBook, continueWithError) in
            if let addressBook = addressBook as? String {
                didReceiveAddressBook = addressBook == posedAddressBook
            }
            continueWithError(error: nil)
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(didReceiveAddressBook)
    }

    func test__when_not_determined__manager_requests_permission() {

        let manager = TestableAddressBookManager(.NotDetermined)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        manager.addressBook = posedAddressBook as CFTypeRef

        var didReceiveAddressBook = false
        let operation = AddressBookOperation(manager: manager, silent: false) { (addressBook, continueWithError) in
            if let addressBook = addressBook as? String {
                didReceiveAddressBook = addressBook == posedAddressBook
            }
            continueWithError(error: nil)
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
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
        let operation = AddressBookOperation(manager: manager, silent: true) { (addressBook, continueWithError) in
            didExecuteHandler = true
            continueWithError(error: nil)
        }

        operation.addObserver(LoggingObserver())

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
