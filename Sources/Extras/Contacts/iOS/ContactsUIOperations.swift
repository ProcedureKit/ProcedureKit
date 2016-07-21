//
//  ContactsUIOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Contacts
import ContactsUI

@available(iOS 9.0, *)
public typealias ContactViewControllerConfigurationBlock = (CNContactViewController) -> Void

@available(iOS 9.0, *)
final public class DisplayContactViewController<F: PresentingViewController>: GroupOperation {

    let from: ViewControllerDisplayStyle<F>
    let sender: AnyObject?
    let get: GetContacts
    let configuration: ContactViewControllerConfigurationBlock?

    var operation: UIOperation<CNContactViewController, F>? = .none

    public var contactViewController: CNContactViewController? {
        return operation?.controller
    }

    public init(identifier: String, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: CNContactViewControllerDelegate, sender: AnyObject? = .none, configuration: ContactViewControllerConfigurationBlock? = .none) {
        self.from = from
        self.sender = sender
        self.get = GetContacts(identifier: identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        self.configuration = configuration
        super.init(operations: [ get ])
        name = "Display Contact View Controller"
    }

    public func createViewControllerForContact(_ contact: CNContact) -> CNContactViewController {
        let vc = CNContactViewController(for: contact)
        configuration?(vc)
        return vc
    }

    public override func willFinishOperation(_ finished: Operation) {
        if finished == get, let contact = get.contact {
            operation = UIOperation(controller: createViewControllerForContact(contact), displayControllerFrom: from, sender: sender)
            addOperation(operation!)
        }
    }
}

@available(iOS 9.0, *)
final public class DisplayCreateContactViewController<F: PresentingViewController>: OldOperation {

    let configuration: ContactViewControllerConfigurationBlock?
    let operation: UIOperation<CNContactViewController, F>

    public var contactViewController: CNContactViewController {
        return operation.controller
    }

    public init(displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: CNContactViewControllerDelegate, sender: AnyObject? = .none, configuration: ContactViewControllerConfigurationBlock? = .none) {

        let controller = CNContactViewController(forNewContact: .none)
        controller.contactStore = CNContactStore()
        controller.delegate = delegate
        self.operation = UIOperation(controller: controller, displayControllerFrom: from, sender: sender)
        self.configuration = configuration
        super.init()
        name = "Display Create Contact View Controller"
    }

    public override func execute() {
        configuration?(contactViewController)
        produceOperation(operation)
    }
}
