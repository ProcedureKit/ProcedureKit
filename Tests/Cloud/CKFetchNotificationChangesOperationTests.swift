//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchNotificationChangesOperation: TestCKOperation, CKFetchNotificationChangesOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = FetchNotificationChangesError<ServerChangeToken>

    var error: Error? = nil
    var finalPreviousServerChangeToken: ServerChangeToken? = nil
    var changedNotifications: [Notification]? = nil
    var previousServerChangeToken: ServerChangeToken? = nil
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var notificationChangedBlock: ((Notification) -> Void)? = nil
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, Error?) -> Void)? = nil

    init(token: ServerChangeToken? = nil, error: Error? = nil) {
        self.finalPreviousServerChangeToken = token
        self.error = error
        super.init()
    }

    override func main() {
        if let changes = changedNotifications, let block = notificationChangedBlock {
            if changes.count > 0 {
                changes.forEach(block)
            }
        }
        fetchNotificationChangesCompletionBlock?(finalPreviousServerChangeToken, error)
    }
}
