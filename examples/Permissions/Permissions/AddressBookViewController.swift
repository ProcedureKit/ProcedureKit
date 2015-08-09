//
//  AddressBookViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook
import Operations

class AddressBookViewController: PermissionViewController {

    var numberOfContacts: Int = 0 {
        didSet {
<<<<<<< Updated upstream
            dispatch_async(Queue.Main.queue) { [count = numberOfContacts, label = operationResultsLabel] in
=======
            dispatch_async(Queue.Main.queue) { [count = numberOfContacts, label = operationResults.informationLabel] in
>>>>>>> Stashed changes
                if count > 1 {
                    label.text = "There are \(count) contacts in your Address Book."
                }
                else if count == 1 {
                    label.text = "There is only one contact in your Address Book."
                }
                else {
                    label.text = "You don't have any contacts yet."
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Address Book", comment: "Address Book")

<<<<<<< Updated upstream
        permissionNotDeterminedLabel.text = "We haven't yet asked permission to access your Address Book."
        permissionGrantedPerformOperationInstructionsLabel.text = "Perform an operation with the Address Book"
        permissionGrantedPerformOperationButton.setTitle("Count the number of Contacts", forState: .Normal)
        operationResultsLabel.text = "These are the results of our Address Book Operation"
        
=======
        permissionNotDetermined.informationLabel.text = "We haven't yet asked permission to access your Address Book."
        permissionGranted.instructionLabel.text = "Perform an operation with the Address Book"
        permissionGranted.button.setTitle("Count the number of Contacts", forState: .Normal)
        operationResults.informationLabel.text = "These are the results of our Address Book Operation"        
>>>>>>> Stashed changes
    }

    override func viewWillAppear(animated: Bool) {
        determineAuthorizationStatus()
    }

    override func conditionsForState(state: State, silent: Bool) -> [OperationCondition] {
        return configureConditionsForState(state, silent: silent)(AddressBookCondition())
    }

    func determineAuthorizationStatus(silently: Bool = true) {

        // Create a simple block operation to set the state.
        let authorized = BlockOperation { (continueWithError: BlockOperation.ContinuationBlockType) in
            self.state = .Authorized
            continueWithError(error: nil)
        }
        authorized.name = "Authorized Access"

        // Condition the operation so that it will only run if we have
        // permission to access the user's address book.
        let condition = AddressBookCondition()

        // Additionally, suppress the automatic request if not authorized.
        authorized.addCondition(silently ? SilentCondition(condition) : condition)

        // Attach an observer so that we can inspect any condition errors
        // From here, we can determine the authorization status if not
        // authorized.
        authorized.addObserver(BlockObserver { (_, errors) in
            if let error = errors.first as? AddressBookCondition.Error {
                switch error {

                case .AuthorizationDenied, .AuthorizationRestricted:
                    self.state = .Denied

                case .AuthorizationNotDetermined:
                    self.state = .Unknown
                }
            }
        })

        queue.addOperation(authorized)
    }

    override func requestPermission() {
        determineAuthorizationStatus(silently: false)
    }

<<<<<<< Updated upstream
    func countContacts() {

=======
    override func performOperation() {
        
>>>>>>> Stashed changes
        let countContactsOperation = AddressBookOperation { (addressBook, continueWithError) -> Void in
            let contacts: NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
            self.numberOfContacts = contacts.count
            self.state = .Completed
            continueWithError(error: nil)
        }
        countContactsOperation.addCondition(AddressBookCondition())
        queue.addOperation(countContactsOperation)
    }
}






