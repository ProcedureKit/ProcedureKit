//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchShareParticipantsOperation.
public protocol CKFetchShareParticipantsOperationProtocol: CKOperationProtocol {

    /// - returns: the user identity lookup infos
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the share participant fetched block
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? { get set }

    /// - returns: the fetch share participants completion block
    var fetchShareParticipantsCompletionBlock: ((Error?) -> Void)? { get set }
}
