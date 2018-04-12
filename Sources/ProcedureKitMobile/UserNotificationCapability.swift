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
extension UNNotificationSettings: AuthorizationStatus {

    public func meets(requirement _requirement: UNAuthorizationOptions?) -> Bool {
        let requirement = _requirement ?? []
        switch (authorizationStatus, requirement.contains(.alert), requirement.contains(.badge), requirement.contains(.sound)) {
        case (.authorized, true, true, true):
            return alertSetting.isEnabled && badgeSetting.isEnabled && soundSetting.isEnabled
        case (.authorized, true, true, _):
            return alertSetting.isEnabled && badgeSetting.isEnabled
        case (.authorized, true, _, true):
            return alertSetting.isEnabled && soundSetting.isEnabled
        case (.authorized, _, true, true):
            return badgeSetting.isEnabled && soundSetting.isEnabled
        case (.authorized, _, _, true):
            return soundSetting.isEnabled
        case (.authorized, _, true, _):
            return badgeSetting.isEnabled
        case (.authorized, true, _, _):
            return alertSetting.isEnabled
        case (.authorized, _, _, _):
            return true
        default:
            return false
        }
    }
}

@available(iOS 10.0, tvOS 10.0, watchOS 3.0, *)
internal extension UNNotificationSetting {

    var isEnabled: Bool {
        switch self {
        case .enabled: return true
        default: return false
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

        public func getAuthorizationStatus(_ completion: @escaping (UNNotificationSettings) -> Void) {
            registrar.pk_getNotificationSettings(completionHandler: completion)
        }

        public func requestAuthorization(withCompletion completion: @escaping () -> Void) {
            registrar.pk_requestAuthorization(options: requirement ?? []) { (_, _) in
                completion()
            }
        }
    }
}
