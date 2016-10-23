//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchShareMetadataOperation.
public protocol CKFetchShareMetadataOperationProtocol: CKOperationProtocol {

    /// - returns: the share URLs
    var shareURLs: [NSURL] { get set }

    /// - returns: whether to fetch the share root record
    var shouldFetchRootRecord: Bool { get set }

    /// - returns: the share root record desired keys
    var rootRecordDesiredKeys: [String]? { get set }

    /// - returns: the per share metadata block
    var perShareMetadataBlock: ((NSURL, ShareMetadata?, Error?) -> Void)? { get set }

    /// - returns: the fetch share metadata completion block
    var fetchShareMetadataCompletionBlock: ((Error?) -> Void)? { get set }
}
