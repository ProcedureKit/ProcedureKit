//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKOperation: Operation, CKOperationProtocol {

    typealias ServerChangeToken = String
    typealias RecordZone = String
    typealias RecordZoneID = String
    typealias Notification = String
    typealias NotificationID = String
    typealias Record = String
    typealias RecordID = String
    typealias Subscription = String
    typealias RecordSavePolicy = Int
    typealias DiscoveredUserInfo = String
    typealias Query = String
    typealias QueryCursor = String

    typealias UserIdentity = String
    typealias UserIdentityLookupInfo = String
    typealias Share = String
    typealias ShareMetadata = String
    typealias ShareParticipant = String

    var container: String? // just a test
    var allowsCellularAccess: Bool = true

    //@available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    var operationID: String = ""
    var longLived: Bool = false

    var longLivedOperationWasPersistedBlock: () -> Void = { }

    //@available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForRequest: TimeInterval = 0
    var timeoutIntervalForResource: TimeInterval = 0
}

class CKOperationTests: CKProcedureTestCase {


}
