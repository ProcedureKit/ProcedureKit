//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifySubscriptionsOperation.
public protocol CKModifySubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscriptions to save
    var subscriptionsToSave: [Subscription]? { get set }

    /// - returns: the subscriptions IDs to delete
    var subscriptionIDsToDelete: [String]? { get set }

    /// - returns: the modify subscription completion block
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, Error?) -> Void)? { get set }
}
