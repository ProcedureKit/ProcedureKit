//
//  UserConfirmationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

enum UserConfirmationResult {
    case unknown
    case confirmed
    case cancelled
}

enum UserConfirmationError: ErrorProtocol {
    case confirmationUnknown
    case confirmationCancelled
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
    private var confirmation: UserConfirmationResult = .unknown
    private var alertOperationErrors = [ErrorProtocol]()

    public init(title: String, message: String? = .none, action: String, isDestructive: Bool = true, cancelAction: String = NSLocalizedString("Cancel", comment: "Cancel"), presentConfirmationFrom from: From) {
        self.action = action
        self.isDestructive = isDestructive
        self.cancelAction = cancelAction
        self.alert = AlertOperation(presentAlertFrom: from)
        super.init()
        name = "UserConfirmationCondition(\(title))"

        alert.title = title
        alert.message = message
        alert.addActionWithTitle(action, style: isDestructive ? .destructive : .default) { [weak self] _ in
            self?.confirmation = .confirmed
        }
        alert.addActionWithTitle(cancelAction, style: .cancel) { [weak self] _ in
            self?.confirmation = .cancelled
        }
        alert.addObserver(WillFinishObserver { [weak self] _, errors in
            self?.alertOperationErrors = errors
        })
        addDependency(alert)
    }

    public override func evaluate(_ operation: Procedure, completion: (OperationConditionResult) -> Void) {
        switch confirmation {
        case .unknown:
            // This should never happen, but you never know.
            completion(.failed(UserConfirmationError.confirmationUnknown))
        case .cancelled:
            completion(.failed(UserConfirmationError.confirmationCancelled))
        case .confirmed:
            completion(.satisfied)
        }
    }
}
