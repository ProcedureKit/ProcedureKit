//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKMarkNotificationsReadOperation: TestCKOperation, CKMarkNotificationsReadOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = MarkNotificationsReadError<String>

    var notificationIDs: [String] = []
    var error: Error? = nil

    var markNotificationsReadCompletionBlock: (([String]?, Error?) -> Void)? = nil

    init(markIDsToRead: [String] = [], error: Error? = nil) {
        self.notificationIDs = markIDsToRead
        self.error = error
        super.init()
    }

    override func main() {
        markNotificationsReadCompletionBlock?(notificationIDs, error)
    }
}
