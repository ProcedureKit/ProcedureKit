//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(tvOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}
