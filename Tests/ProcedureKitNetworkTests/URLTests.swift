//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class URLTests: XCTestCase {

    func test__url_is_expressible_by_string_literal() {
        let url: URL = "http://procedure.kit.run"
        XCTAssertEqual(url.host, "procedure.kit.run")
    }

    func test__url_is_expressible_by_extended_grapheme_cluster_literal() {
        let url = URL(extendedGraphemeClusterLiteral: "http://procedure.kit.run")
        XCTAssertEqual(url.host, "procedure.kit.run")
    }

    func test__url_is_expressible_by_unicode_scalar_literal() {
        let url = URL(unicodeScalarLiteral: "http://procedure.kit.run")
        XCTAssertEqual(url.host, "procedure.kit.run")
    }
}

