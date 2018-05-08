//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UserNotifications
import ProcedureKit
@testable import ProcedureKitMobile

class TestableUserNotificationsRegistrar {

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var authorization: (Bool, Error?, UNAuthorizationStatus)? = nil

    var didCheckAuthorizationStatus = false
    var didRequestAuthorization = false
    var didRequestAuthorizationForOptions: UNAuthorizationOptions = []
}

extension TestableUserNotificationsRegistrar: UserNotificationsRegistrarProtocol {

    func pk_getAuthorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        didCheckAuthorizationStatus = true
        completion(authorizationStatus)
    }

    func pk_requestAuthorization(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void) {

        didRequestAuthorization = true
        didRequestAuthorizationForOptions = options

        // Set the new authorization
        guard let (success, error, status) = authorization else {
            fatalError("Must set the fake authorization before requesting authorization")
        }

        // Set the new authorization status
        authorizationStatus = status

        // Run the completion handler
        completion(success, error)
    }
}
