//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchSubscriptionsOperation.
public protocol CKFetchSubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscription IDs
    var subscriptionIDs: [String]? { get set }

    /// - returns: the fetch subscription completion block
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, Error?) -> Void)? { get set }
}
