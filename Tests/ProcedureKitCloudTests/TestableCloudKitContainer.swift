//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestableCloudKitContainerRegistrar: CloudKitContainerRegistrar {

    var accountStatus: CKAccountStatus = .couldNotDetermine
    var accountStatusError: Error? = nil

    var verifyApplicationPermissionStatus: CKContainer.Application.PermissionStatus = .initialState
    var verifyApplicationPermissionsError: Error? = nil
    var verifyApplicationPermissions: CKContainer.Application.Permissions? = nil

    var requestApplicationPermissionStatus: CKContainer.Application.PermissionStatus = .granted
    var requestApplicationPermissionsError: Error? = nil
    var requestApplicationPermissions: CKContainer.Application.Permissions? = nil

    var didGetAccountStatus = false
    var didVerifyApplicationStatus = false
    var didRequestApplicationStatus = false

    func pk_accountStatus(withCompletionHandler completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
        didGetAccountStatus = true
        completionHandler(accountStatus, accountStatusError)
    }

    func pk_status(forApplicationPermission applicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock) {
        didVerifyApplicationStatus = true
        verifyApplicationPermissions = applicationPermission
        completionHandler(verifyApplicationPermissionStatus, verifyApplicationPermissionsError)
    }

    func pk_requestApplicationPermission(_ applicationPermission: CKContainer.Application.Permissions, completionHandler: @escaping CKContainer.Application.PermissionBlock) {
        didRequestApplicationStatus = true
        requestApplicationPermissions = applicationPermission
        completionHandler(requestApplicationPermissionStatus, requestApplicationPermissionsError)
    }
}


