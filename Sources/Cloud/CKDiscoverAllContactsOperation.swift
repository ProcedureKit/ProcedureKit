//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

#if !os(tvOS)
/// Extension to have CKDiscoverAllContactsOperation conform to CKDiscoverAllContactsOperationType
@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
@available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
//  public typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>
}
#endif
