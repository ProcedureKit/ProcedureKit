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
extension UNAuthorizationStatus: AuthorizationStatus {

    public func meets(requirement: UNAuthorizationOptions?) -> Bool {
        switch self {
        case .authorized:
            return true
        default:
            return false
        }
    }
}

public extension Capability {

    @available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    class UserNotifications: CapabilityProtocol {

        public private(set) var requirement: UNAuthorizationOptions?

        internal lazy var registrar: UserNotificationsRegistrarProtocol = UNUserNotificationCenter.current()

        public init(_ requirement: UNAuthorizationOptions = [.badge, .sound, .alert]) {
            self.requirement = requirement
        }

        public func isAvailable() -> Bool {
            return true
        }

        public func getAuthorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
            registrar.pk_getAuthorizationStatus(completion)
        }

        public func requestAuthorization(withCompletion completion: @escaping () -> Void) {
            registrar.pk_requestAuthorization(options: requirement ?? []) { (_, _) in
                completion()
            }
        }
    }
}
