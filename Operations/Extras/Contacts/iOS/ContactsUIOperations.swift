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
public enum DisplayContactWithIntent {

    case Contact(CNContact)
    case Unknown(CNContact)
    case New(CNContact?)

    var contactViewController: CNContactViewController {
        switch self {
        case .Contact(let contact):
            return CNContactViewController(forContact: contact)
        case .Unknown(let contact):
            return CNContactViewController(forUnknownContact: contact)
        case .New(let contact):
            return CNContactViewController(forNewContact: contact)
        }
    }
}

@available(iOS 9.0, *)
final public class ContactsDisplayContactViewController<F: PresentingViewController>: ContactsOperation {

    let contact: DisplayContactWithIntent
    let ui: UIOperation<CNContactViewController, F>

    public var contactViewController: CNContactViewController {
        return ui.controller
    }

    public init(contact: DisplayContactWithIntent, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: CNContactViewControllerDelegate, sender: AnyObject? = .None) {
        self.contact = contact
        self.ui = UIOperation(controller: contact.contactViewController, displayControllerFrom: from, sender: sender)
        super.init()
        name = "Display Contact View Controller"
        contactViewController.delegate = delegate
    }

    public override func executeContactsTask() throws {
        contactViewController.contactStore = store
        produceOperation(ui)
    }
}

@available(iOS 9.0, *)
final public class ContactsDisplayCreateContactViewController<F: PresentingViewController>: GroupOperation {

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

