//
//  UserConfirmationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

enum UserConfirmationResult {
    case Unknown
    case Confirmed
    case Cancelled
}

enum UserConfirmationError: ErrorType {
    case ConfirmationUnknown
    case ConfirmationCancelled
}

/**
    Attach this condition to an operation to present an alert
    to the user requesting their confirmation before proceeding.
*/
public class UserConfirmationCondition<From: PresentingViewController>: Condition {

    private let action: String
    private let isDestructive: Bool
    private let cancelAction: String
    private var alert: AlertOperation<From>
    private var confirmation: UserConfirmationResult = .Unknown
    private var alertOperationErrors = [ErrorType]()

    public init(title: String, message: String? = .None, action: String, isDestructive: Bool = true, cancelAction: String = NSLocalizedString("Cancel", comment: "Cancel"), presentConfirmationFrom from: From) {
        self.action = action
        self.isDestructive = isDestructive
        self.cancelAction = cancelAction
        self.alert = AlertOperation(presentAlertFrom: from)
        super.init()
        name = "UserConfirmationCondition(\(title))"

        alert.title = title
        alert.message = message
        alert.addActionWithTitle(action, style: isDestructive ? .Destructive : .Default) { [weak self] _ in
            self?.confirmation = .Confirmed
        }
        alert.addActionWithTitle(cancelAction, style: .Cancel) { [weak self] _ in
            self?.confirmation = .Cancelled
        }
        alert.addObserver(WillFinishObserver { [weak self] _, errors in
            self?.alertOperationErrors = errors
        })
        addDependency(alert)
    }

    public override func evaluate(operation: Operation, completion: OperationConditionResult -> Void) {
        switch confirmation {
        case .Unknown:
            // This should never happen, but you never know.
            completion(.Failed(UserConfirmationError.ConfirmationUnknown))
        case .Cancelled:
            completion(.Failed(UserConfirmationError.ConfirmationCancelled))
        case .Confirmed:
            completion(.Satisfied)
        }
    }
}
