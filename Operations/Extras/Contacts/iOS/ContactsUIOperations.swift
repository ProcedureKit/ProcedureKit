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
final public class DisplayContactViewController<F: PresentingViewController>: GroupOperation {

    public typealias ContactViewControllerConfigurationBlock = CNContactViewController -> Void

    let from: ViewControllerDisplayStyle<F>
    let sender: AnyObject?
    let get: ContactsGetContacts
    let configuration: ContactViewControllerConfigurationBlock?

    var ui: UIOperation<CNContactViewController, F>? = .None

    public var contactViewController: CNContactViewController? {
        return ui?.controller
    }

    public init(identifier: String, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: CNContactViewControllerDelegate, sender: AnyObject? = .None, configuration: ContactViewControllerConfigurationBlock? = .None) {
        self.from = from
        self.sender = sender
        self.get = ContactsGetContacts(identifier: identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        self.configuration = configuration
        super.init(operations: [ get ])
        name = "Display Contact View Controller"
    }

    public func createViewControllerForContact(contact: CNContact) -> CNContactViewController {
        let vc = CNContactViewController(forContact: contact)
        configuration?(vc)
        return vc
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get, let contact = get.contact {
            ui = UIOperation(controller: createViewControllerForContact(contact), displayControllerFrom: from, sender: sender)
            addOperation(ui!)
        }
    }
}

@available(iOS 9.0, *)
final public class DisplayCreateContactViewController<F: PresentingViewController>: GroupOperation {

    let store = CNContactStore()
    let delegate: CNContactViewControllerDelegate
    let ui: UIOperation<CNContactViewController, F>

    public var contactViewController: CNContactViewController {
        return ui.controller
    }

    public init(displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: CNContactViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {
        self.delegate = delegate
        self.ui = UIOperation(controller: CNContactViewController(forNewContact: .None), displayControllerFrom: from, sender: sender)
        let op = groupName.map { ContactsGetGroup(groupName: $0) } ?? ContactsOperation()
        super.init(operations: [op])
        name = "Display Create Contact View Controller"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty {
            contactViewController.delegate = delegate
            if let getGroupOperation = operation as? ContactsGetGroup {
                contactViewController.parentGroup = getGroupOperation.group
            }
            addOperation(ui)
        }
    }
}

