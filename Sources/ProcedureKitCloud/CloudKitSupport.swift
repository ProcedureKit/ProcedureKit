//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

protocol CloudKitContainerRegistrar {

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void)

    func pk_status(forApplicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock)

    func pk_requestApplicationPermission(_ applicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock)
}

extension CKContainer: CloudKitContainerRegistrar {

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
        accountStatus(completionHandler: completionHandler)
    }

    func pk_status(forApplicationPermission applicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock) {
        status(forApplicationPermission: applicationPermission, completionHandler: completionHandler)
    }

    func pk_requestApplicationPermission(_ applicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock) {
        requestApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }
}
