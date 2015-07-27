//
//  ViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import AddressBook
import Operations

class ViewController: UIViewController {

    let queue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()
        addressBookOperation()
    }

    func addressBookOperation() {

        let operation = BlockOperation {
            dispatch_async(Queue.Interactive.serial("me.operations.Permissions.logging")) {
                println("Inform the user that they will need to authorize the app to access the Address Book.")
            }
        }

        operation.addCondition(NegatedCondition(SilentCondition(AddressBookCondition())))
        operation.addObserver(BlockObserver { (_, errors) in
            if let error = errors.first as? AddressBookCondition.Error {
                switch error {
                case .AuthorizationDenied:
                    println("Authorization denied.")
                case .AuthorizationRestricted:
                    println("Authorization restricted.")
                case .AuthorizationNotDetermined:
                    println("Authorization request was suppressed.")
                }
            }
        })

        queue.addOperation(operation)
    }

    func addressBookOperationTwo() {

        let operation = AddressBookOperation { (addressBook, continuation) -> Void in
            let contacts: NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
            dispatch_async(Queue.Interactive.serial("me.operations.Permissions.logging")) {
                println("Number of contacts in Address Book: \(contacts.count).")
            }
            continuation()
        }

        queue.addOperation(operation)
    }
}



