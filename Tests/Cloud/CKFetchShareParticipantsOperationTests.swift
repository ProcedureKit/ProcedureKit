//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchShareParticipantsOperation: TestCKOperation, CKFetchShareParticipantsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var error: Error?

    var userIdentityLookupInfos: [UserIdentityLookupInfo] = []
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? = nil
    var fetchShareParticipantsCompletionBlock: ((Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        fetchShareParticipantsCompletionBlock?(error)
    }
}
