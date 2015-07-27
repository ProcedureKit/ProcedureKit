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
        return (addressBook as ABAddressBookRef, nil)
    }

    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler) {
        didRequestAccess = true
        completion(requestShouldSucceed, error)
    }
}

class AddressBookOperationTests: OperationTests {

    func test__when_authorized_handler_receives_addressbook() {

        var didReceiveAddressBook = false
        let manager = TestableAddressBookManager(.Authorized)
        let posedAddressBook = "I'm posing as an Address Book Ref!"
        manager.addressBook = posedAddressBook as CFTypeRef

        let operation = AddressBookOperation(manager: manager, silent: false) { (addressBook, continuation) in
            if let addressBook = addressBook as? String {
                didReceiveAddressBook = addressBook == posedAddressBook
            }
            continuation()
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))

        runOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssertTrue(didReceiveAddressBook)
    }

}
