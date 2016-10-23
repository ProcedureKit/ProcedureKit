//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// An extension to make CKDatabaseOperation to conform to the CKDatabaseOperationProtocol.
extension CKDatabaseOperation: CKDatabaseOperationProtocol {

    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}
