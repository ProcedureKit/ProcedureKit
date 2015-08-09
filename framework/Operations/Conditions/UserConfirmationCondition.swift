//
//  UserConfirmationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

/**
    Attach this condition to an operation to present an alert
    to the user requesting their confirmation before proceeding.
*/
public class UserConfirmationCondition: OperationCondition {

    enum Confirmation {
        case Unknown
        case Confirmed
        case Cancelled
    }

    enum Error: ErrorType {
        case ConfirmationUnknown
        case ConfirmationCancelled
    }

    public let name: String
    public let isMutuallyExclusive = false

    public let title: String
    public let message: String?
    public let action: String
    public let isDestructive: Bool
    public let cancelAction: String

    var presentingController: PresentingViewController?
    var confirmation: Confirmation = .Unknown

    public init(title: String, message: String? = .None, action: String, isDestructive: Bool = true, cancelAction: String = NSLocalizedString("Cancel", comment: "Cancel"), presentingController: PresentingViewController? = .None) {
        self.name = "UserConfirmationCondition(\(title))"
        self.title = title
        self.message = message
        self.action = action
        self.isDestructive = isDestructive
        self.cancelAction = cancelAction
        self.presentingController = presentingController
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        let alert = AlertOperation(presentFromController: presentingController)
        alert.title = title
        alert.message = message
        alert.addActionWithTitle(action, style: isDestructive ? .Destructive : .Default) { [weak self] _ in
            self?.confirmation = .Confirmed
        }
        alert.addActionWithTitle(cancelAction, style: .Cancel) { [weak self] _ in
            self?.confirmation = .Cancelled
        }
        return alert
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch confirmation {
        case .Unknown:
            // This should never happen, but you never know.
            completion(.Failed(Error.ConfirmationUnknown))
        case .Cancelled:
            completion(.Failed(Error.ConfirmationCancelled))
        case .Confirmed:
            completion(.Satisfied)
        }
    }

}
