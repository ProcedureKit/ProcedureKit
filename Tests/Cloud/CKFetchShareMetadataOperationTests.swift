//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchShareMetadataOperation: TestCKOperation, CKFetchShareMetadataOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?

    var shareURLs: [URL] = []
    var shouldFetchRootRecord: Bool = false
    var rootRecordDesiredKeys: [String]? = nil
    var perShareMetadataBlock: ((URL, ShareMetadata?, Error?) -> Void)? = nil
    var fetchShareMetadataCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        fetchShareMetadataCompletionBlock?(error)
    }
}
