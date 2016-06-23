//
//  AddressBookUIOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI



/**
Displays an `ABPersonViewController`. To enable actions or editing, create
an `ABPersonViewController` instance and configure these settings. Pass it
to this operation as the first argument.

The operation will locate the `ABRecordRef` for the person and set this
on the controller in addition to the `ABAddressBookRef`.

Select and appropriate `DisplayStyle` to configure how the controller should
be displayed, either presented, show, show detail. For each style, associate
the sending view controller. Therefore, to push a person controller:

    let show = AddressBookDisplayPersonViewController(
      personWithId: addressBookID,
      displayFromControllerWithStyle: .Show(self),
      delegate: self,
      sender: self
    )
    queue.addOperation(show)

To configure the controller, you can do this:

    let controller = ABPersonViewController()
    controller.allowEditing = true
    let show = AddressBookDisplayPersonViewController(
      personViewController: controller,
      personWithId: addressBookID,
      displayFromControllerWithStyle: .Show(self),
      delegate: self,
      sender: self
    )
    queue.addOperation(show)
*/
@available(iOS, deprecated=9.0)
public class AddressBookDisplayPersonViewController<F: PresentingViewController>: GroupOperation {

    let delegate: ABPersonViewControllerDelegate
    let operation: UIOperation<ABPersonViewController, F>
    let get: AddressBookGetResource

    public convenience init(personViewController: ABPersonViewController? = .None, personWithID personID: ABRecordID, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {
        self.init(registrar: SystemAddressBookRegistrar(), personViewController: personViewController, personWithID: personID, displayControllerFrom: from, delegate: delegate, sender: sender)
    }

    init(registrar: AddressBookPermissionRegistrar, personViewController: ABPersonViewController? = .None, personWithID personID: ABRecordID, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {

        self.operation = UIOperation(controller: personViewController ?? ABPersonViewController(), displayControllerFrom: from, sender: sender)
        self.delegate = delegate
        self.get = AddressBookGetResource(registrar: registrar)
        self.get.personQuery = .ID(personID)
        super.init(operations: [ get ])
    }

    public override func willFinishOperation(finished: NSOperation) {
        if get == finished, let person = get.addressBookPerson {
            operation.controller.personViewDelegate = delegate
            operation.controller.displayedPerson = person.storage
            operation.controller.addressBook = get.addressBook.addressBook
            addOperation(operation)
        }
    }
}

@available(iOS, deprecated=9.0)
public class AddressBookDisplayNewPersonViewController<F: PresentingViewController>: GroupOperation {

    let delegate: ABNewPersonViewControllerDelegate
    let operation: UIOperation<ABNewPersonViewController, F>
    let get: AddressBookGetResource

    public convenience init(displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {
        self.init(registrar: SystemAddressBookRegistrar(), displayControllerFrom: from, delegate: delegate, sender: sender, addToGroupWithName: groupName)
    }

    init(registrar: AddressBookPermissionRegistrar, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {

        self.operation = UIOperation(controller: ABNewPersonViewController(), displayControllerFrom: from, sender: sender)
        self.delegate = delegate
        self.get = AddressBookGetResource(registrar: registrar)
        if let groupName = groupName {
            get.groupQuery = .Name(groupName)
        }
        super.init(operations: [ get ])
    }

    public override func willFinishOperation(finished: NSOperation) {
        if get == finished {

            operation.controller.newPersonViewDelegate = delegate
            operation.controller.addressBook = get.addressBook.addressBook

            if let group = get.addressBookGroup {
                operation.controller.parentGroup = group.storage
            }

            addOperation(operation)
        }
    }
}
