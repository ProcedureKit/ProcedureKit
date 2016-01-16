//
//  ViewController.swift
//  Last Opened
//
//  Created by Daniel Thorpe on 11/01/2016.
//  Copyright © 2016 Daniel Thorpe. All rights reserved.
//

import UIKit
import CloudKit
import Operations

class ViewController: UIViewController {

    let queue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch (all) Record Zones CloudKit Operation
        let operation = CloudKitOperation { CKFetchRecordZonesOperation.fetchAllRecordZonesOperation() }

        // Add an authorized condition
        operation.addCondition(AuthorizedFor(Capability.Cloud()))

        // Configure the container & database
        let container = CKContainer.defaultContainer()
        operation.container = container
        operation.database = container.privateCloudDatabase

        operation.setFetchRecordZonesCompletionBlock { zonesByID in
            print("zones: \(zonesByID)")
        }

        queue.addOperation(operation)
    }

}

