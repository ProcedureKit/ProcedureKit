//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import UserNotifications

@available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
protocol UserNotificationsRegistrarProtocol {

    func pk_getAuthorizationStatus(_: @escaping (UNAuthorizationStatus) -> Void)

    func pk_requestAuthorization(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void)
}

@available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
extension UNUserNotificationCenter: UserNotificationsRegistrarProtocol {

    func pk_getAuthorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        getNotificationSettings { completion($0.authorizationStatus) }
    }

    func pk_requestAuthorization(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(options: options, completionHandler: completion)
    }
}
