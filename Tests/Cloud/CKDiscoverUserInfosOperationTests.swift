//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDiscoverUserInfosOperation: TestCKOperation, CKDiscoverUserInfosOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError

    var emailAddresses: [String]?
    var userRecordIDs: [RecordID]?
    var userInfosByEmailAddress: [String: DiscoveredUserInfo]? = nil
    var userInfoByRecordID: [RecordID: DiscoveredUserInfo]? = nil
    var error: Error? = nil
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, Error?) -> Void)? = nil

    init(userInfosByEmailAddress: [String: DiscoveredUserInfo]? = nil, userInfoByRecordID: [RecordID: DiscoveredUserInfo]? = nil, error: Error? = nil) {
        self.userInfosByEmailAddress = userInfosByEmailAddress
        self.userInfoByRecordID = userInfoByRecordID
        self.error = error
        super.init()
    }

    override func main() {
        discoverUserInfosCompletionBlock?(userInfosByEmailAddress, userInfoByRecordID, error)
    }
}

