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
    let container = CKContainer.defaultContainer()

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let zones = fetchZones()
        let records = fetchRecords()
        records.addDependency(zones)
        queue.addOperations(zones, records)
    }

    func fetchZones() -> Operation {

        // Fetch (all) Record Zones CloudKit Operation
        let operation = CloudKitOperation { CKFetchRecordZonesOperation.fetchAllRecordZonesOperation() }

        // Configure the container & database
        operation.container = container
        operation.database = container.privateCloudDatabase

        operation.setFetchRecordZonesCompletionBlock { zonesByID in
            if let zonesByID = zonesByID {
                for (zoneID, zone) in zonesByID {
                    print("id: \(zoneID), zone: \(zone)")
                }
            }
        }

        return operation
    }

    func fetchRecords() -> Operation {

        // Discover all contacts operation
        let operation = CloudKitOperation { CKFetchRecordsOperation.fetchCurrentUserRecordOperation() }

        // Configure the container & database
        operation.container = container
        operation.database = container.privateCloudDatabase

        operation.setFetchRecordsCompletionBlock { recordsByID in
            print("records by id: \(recordsByID)")
        }

        return operation
    }
}






