//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifyBadgeOperation.
public protocol CKModifyBadgeOperationProtocol: CKOperationProtocol {

    /// - returns: the badge value
    var badgeValue: Int { get set }

    /// - returns: the completion block used
    var modifyBadgeCompletionBlock: ((Error?) -> Void)? { get set }
}
