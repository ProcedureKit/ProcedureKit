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

    // Address Book status not determined
    @IBOutlet var statusNotDeterminedContainerView: UIView!
    @IBOutlet var beginAuthorizationRequestButton: UIButton!

    // Address Book status authorized
    @IBOutlet var statusAuthorizedContainerView: UIView!
    @IBOutlet var countContactsButton: UIButton!

    // Address Book status denied
    @IBOutlet var statusDeniedContainerView: UIView!

    // Address Book contacts results
    @IBOutlet var addressBookResultsContainerView: UIView!
    @IBOutlet var addressBookResultsLabel: UILabel!

    // Reset instructions
    @IBOutlet var resetPermissionsView: UIView!


    var numberOfContacts: Int = 0 {
        didSet {
            dispatch_async(Queue.Main.queue) { [count = numberOfContacts, label = addressBookResultsLabel] in
                if count > 1 {
                    label.text = "There are \(count) in your Address Book."
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
    }

    override func viewWillAppear(animated: Bool) {
        determineAuthorizationStatus()
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

    func requestAccess() {
        determineAuthorizationStatus(silently: false)
    }

    // MARK: Update UI

    override func conditionsForState(state: State, silent: Bool = true) -> [OperationCondition] {

        switch state {
        case .Unknown:
            return silent ? [ SilentCondition(NegatedCondition(AddressBookCondition())) ] : [ NegatedCondition(AddressBookCondition()) ]

        case .Authorized:
            return silent ? [ SilentCondition(AddressBookCondition()) ] : [ AddressBookCondition() ]

        default:
            return []
        }
    }

    override func viewsForState(state: State) -> [UIView] {
        switch state {
        case .Unknown:
            return [statusNotDeterminedContainerView]
        case .Authorized:
            return [statusAuthorizedContainerView, resetPermissionsView]
        case .Denied:
            return [statusDeniedContainerView, resetPermissionsView]
        case .Completed:
            return [addressBookResultsContainerView, resetPermissionsView]
        }
    }

    func countContacts() {

        let countContactsOperation = AddressBookOperation { (addressBook, continueWithError) -> Void in
            let contacts: NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
            self.numberOfContacts = contacts.count
            self.state = .Completed
            continueWithError(error: nil)
        }
        countContactsOperation.addCondition(AddressBookCondition())
        queue.addOperation(countContactsOperation)
    }


    @IBAction func beginAuthorizationRequestButtonAction(sender: UIButton) {
        requestAccess()
    }

    @IBAction func countContactsButtonAction(sender: UIButton) {
        countContacts()
    }
}






