//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKDiscoverUserIdentitiesOperation: CKDiscoverUserIdentitiesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}
