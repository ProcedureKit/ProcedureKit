//
//  ActivityIndicatorViewObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 16/04/2016.
//
//

import Foundation
import XCTest
@testable import Operations

// TODO 🙂

class ActivityIndicatorViewObserverTests: XCTestCase {

    var operation: TestOperation!
    var indicator: ActivityIndicatorViewObserver!

    override func setUp() {
        super.setUp()
        operation = TestOperation()
    }

    override func tearDown() {
        operation = nil
        indicator = nil
        super.tearDown()
    }

    func test__activity_indicator_starts_animating__when_operation_starts() {

    }

    func test__activity_indicator_stops_animating__when_operation_stops() {

    }
}
