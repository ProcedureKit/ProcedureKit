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

class TestCKDiscoverAllUserIdentitiesOperation: TestCKOperation, CKDiscoverAllUserIdentitiesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?

    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? = nil
    var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllUserIdentitiesCompletionBlock?(error)
    }
}

#endif
