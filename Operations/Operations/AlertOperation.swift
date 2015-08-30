//
//  AlertOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

public class AlertOperation<From: PresentingViewController>: Operation {

    private var ui: UIOperation<UIAlertController, From>

    public var title: String? {
        get {
            return ui.controller.title
        }
        set {
            ui.controller.title = newValue
            name = newValue
        }
    }

    public var message: String? {
        get {
            return ui.controller.message
        }
        set {
            ui.controller.message = newValue
        }
    }

    public init(presentAlertFrom from: From) {
        ui = UIOperation(controller: UIAlertController(title: .None, message: .None, preferredStyle: .Alert), displayControllerFrom: .Present(from))
        super.init()
        addCondition(AlertPresentation())
        addCondition(MutuallyExclusive<UIViewController>())
    }

    public func addActionWithTitle(title: String, style: UIAlertActionStyle = .Default, handler: AlertOperation -> Void = { _ in }) {
        let action = UIAlertAction(title: title, style: style) { [weak self] _ in
            if let weakSelf = self {
                handler(weakSelf)
            }
            self?.finish()
        }
        ui.controller.addAction(action)
    }

    public override func execute() {
        if ui.controller.actions.isEmpty {
            addActionWithTitle(NSLocalizedString("Okay", comment: "Okay"))
        }
        produceOperation(ui)
    }
}

