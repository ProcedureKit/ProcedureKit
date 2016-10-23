//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKAcceptSharesOperation: TestCKOperation, CKAcceptSharesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>

    var error: Error?

    var shareMetadatas: [ShareMetadata] = []
    var perShareCompletionBlock: ((ShareMetadata, Share?, Error?) -> Void)? = nil
    var acceptSharesCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        acceptSharesCompletionBlock?(error)
    }
}


