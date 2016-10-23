//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKMarkNotificationsReadOperation.
public protocol CKMarkNotificationsReadOperationProtocol: CKOperationProtocol {

    /// - returns: the notification IDs
    var notificationIDs: [NotificationID] { get set }

    /// - returns: the completion block used when marking notifications
    var markNotificationsReadCompletionBlock: (([NotificationID]?, Error?) -> Void)? { get set }
}
