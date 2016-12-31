//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestableCloudKitContainerRegistrar: CloudKitContainerRegistrar {

    var accountStatus: CKAccountStatus = .couldNotDetermine
    var accountStatusError: Error? = nil

    var verifyApplicationPermissionStatus: CKApplicationPermissionStatus = .initialState
    var verifyApplicationPermissionsError: Error? = nil
    var verifyApplicationPermissions: CKApplicationPermissions? = nil

    var requestApplicationPermissionStatus: CKApplicationPermissionStatus = .granted
    var requestApplicationPermissionsError: Error? = nil
    var requestApplicationPermissions: CKApplicationPermissions? = nil

    var didGetAccountStatus = false
    var didVerifyApplicationStatus = false
    var didRequestApplicationStatus = false

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
        didGetAccountStatus = true
        completionHandler(accountStatus, accountStatusError)
    }

    func pk_status(forApplicationPermission applicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock) {
        didVerifyApplicationStatus = true
        verifyApplicationPermissions = applicationPermission
        completionHandler(verifyApplicationPermissionStatus, verifyApplicationPermissionsError)
    }

    func pk_requestApplicationPermission(_ applicationPermission: CKApplicationPermissions, completionHandler: @escaping CKApplicationPermissionBlock) {
        didRequestApplicationStatus = true
        requestApplicationPermissions = applicationPermission
        completionHandler(requestApplicationPermissionStatus, requestApplicationPermissionsError)
    }
}


