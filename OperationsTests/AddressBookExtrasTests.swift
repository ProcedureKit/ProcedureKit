//
//  AddressBookExtrasTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations
import AddressBook
import AddressBookUI

class AddressBookSortOrderingTests: XCTestCase {

    var ordering: AddressBookSortOrdering!

    func test__given_by_last_name__then_value_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(Int(ordering.value), kABPersonSortByLastName)
    }

    func test__given_by_first_name__then_value_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(Int(ordering.value), kABPersonSortByFirstName)
    }

    func test__given_initialized_by_last_name__then_is_correct() {
        ordering = .ByLastName
        XCTAssertEqual(ordering, AddressBookSortOrdering(ordering: kABPersonSortByLastName))
    }

    func test__given_initialized_by_first_name__then_is_correct() {
        ordering = .ByFirstName
        XCTAssertEqual(ordering, AddressBookSortOrdering(ordering: kABPersonSortByFirstName))
    }

    func test__given_initialized_with_other_int__then_default_is_by_last_name() {
        ordering = .ByLastName
        XCTAssertEqual(ordering, AddressBookSortOrdering(ordering: 666))
    }
}



