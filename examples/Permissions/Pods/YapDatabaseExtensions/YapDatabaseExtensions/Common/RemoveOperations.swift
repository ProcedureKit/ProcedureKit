//
//  RemoveOperations.swift
//  YapDatabaseExtensions
//
//  Created by Daniel Thorpe on 26/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import YapDatabase

extension YapDatabaseConnection {

    public func removeOperation(index: YapDB.Index) -> NSOperation {
        return writeBlockOperation { $0.removeAtIndex(index) }
    }

    public func removeOperation(indexes: [YapDB.Index]) -> NSOperation {
        return writeBlockOperation { $0.removeAtIndexes(indexes) }
    }

    public func removeOperation<Item where Item: Persistable>(item: Item) -> NSOperation {
        return writeBlockOperation { $0.remove(item) }
    }

    public func removeOperation<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items) -> NSOperation {
        return writeBlockOperation { $0.remove(items) }
    }
}
