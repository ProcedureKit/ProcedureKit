//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

protocol CloudKitContainerRegistrar {

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void)

    func pk_status(forApplicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock)

    func pk_requestApplicationPermission(_ applicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock)
}

extension CKContainer: CloudKitContainerRegistrar {

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
        accountStatus(completionHandler: completionHandler)
    }

    func pk_status(forApplicationPermission applicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock) {
        status(forApplicationPermission: applicationPermission, completionHandler: completionHandler)
    }

    func pk_requestApplicationPermission(_ applicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock) {
        requestApplicationPermission(applicationPermission, completionHandler: completionHandler)
    }
}
