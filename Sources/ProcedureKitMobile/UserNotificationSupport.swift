//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

@available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
protocol UserNotificationsRegistrarProtocol {

    func pk_getAuthorizationStatus(_: @escaping (UNNotificationSettings) -> Void)

    func pk_requestAuthorization(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void)
}

@available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
extension UNUserNotificationCenter: UserNotificationsRegistrarProtocol {

    func pk_getAuthorizationStatus(_ completion: @escaping (UNNotificationSettings) -> Void) {
        getNotificationSettings(completionHandler: completion)
    }

    func pk_requestAuthorization(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(options: options, completionHandler: completion)
    }
}
