//
//  PassbookCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestablePassbookRegistrar: NSObject {
    var servicesEnabled = true
    var didCheckServiceEnabled = false

    required override init() { }
}

extension TestablePassbookRegistrar: PassbookCapabilityRegistrarType {

    func opr_isPassKitLibraryAvailable() -> Bool {
        didCheckServiceEnabled = true
        return servicesEnabled
    }
}

class PassbookCapabilityTests: XCTestCase {

    var registrar: TestablePassbookRegistrar!
    var capability: PassbookCapability!

    override func setUp() {
        super.setUp()
        registrar = TestablePassbookRegistrar()
        capability = PassbookCapability()
        capability.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__name() {
        XCTAssertEqual(capability.name, "Passbook")
    }

    func test__is_available_queries_registrar() {
        XCTAssertTrue(capability.isAvailable())
        XCTAssertTrue(registrar.didCheckServiceEnabled)
    }

    func test__authorization_status_queries_register() {
        capability.authorizationStatus { XCTAssertEqual($0, Capability.VoidStatus()) }
    }

    func test__given_service_disabled__requesting_authorization_returns_directly() {
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertTrue(didComplete)
    }
}
