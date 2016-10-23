//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

#if !os(tvOS)
@available(iOS 10.0, OSX 10.12, watchOS 3.0, *)
extension CKDiscoverAllUserIdentitiesOperation: CKDiscoverAllUserIdentitiesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}
#endif
