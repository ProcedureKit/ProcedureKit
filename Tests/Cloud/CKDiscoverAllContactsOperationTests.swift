//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

#if !os(tvOS)

class TestCKDiscoverAllContactsOperation: TestCKOperation, CKDiscoverAllContactsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>

    var result: [DiscoveredUserInfo]?
    var error: Error?
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, Error?) -> Void)? = nil

    init(result: [DiscoveredUserInfo]? = nil, error: Error? = nil) {
        self.result = result
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllContactsCompletionBlock?(result, error)
    }
}

#endif
