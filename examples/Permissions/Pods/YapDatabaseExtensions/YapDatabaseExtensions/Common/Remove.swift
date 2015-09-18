//
//  Created by Daniel Thorpe on 22/04/2015.
//
//

import Foundation

import YapDatabase

// MARK: - YapDatabaseTransaction

extension YapDatabaseReadWriteTransaction {

    /**
    Removes the object stored at this index.

    :param: index A YapDB.Index
    */
    public func removeAtIndex(index: YapDB.Index) {
        removeObjectForKey(index.key, inCollection: index.collection)
    }

    /**
    Removes the object stored at these indexes.

    :param: indexes An Array<YapDB.Index>
    */
    public func removeAtIndexes(indexes: [YapDB.Index]) {
        indexes.forEach(removeAtIndex)
    }

    /**
    Removes any Persistable item.

    :param: item A Persistable item.
    */
    public func remove<Item where Item: Persistable>(item: Item) {
        removeAtIndex(indexForPersistable(item))
    }

    /**
    Removes a sequence of Persistable items.

    :param: items A sequence of Persistable items.
    */
    public func remove<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items) {
        removeAtIndexes(items.map(indexForPersistable))
    }
}



extension YapDatabaseConnection {

    /**
    Synchonously removes the object stored at this index.

    :param: index A YapDB.Index
    */
    public func removeAtIndex(index: YapDB.Index) {
        write({ $0.removeAtIndex(index) })
    }

    /**
    Synchonously removes the object stored at this index.

    :param: indexes An Array<YapDB.Index>
    */
    public func removeAtIndexes(indexes: [YapDB.Index]) {
        write({ $0.removeAtIndexes(indexes) })
    }

    /**
    Synchonously removes any Persistable item.

    :param: item A Persistable item.
    */
    public func remove<Item where Item: Persistable>(item: Item) {
        write({ $0.remove(item) })
    }

    /**
    Synchonously removes a sequence of Persistable items.

    :param: items A sequence of Persistable items.
    */
    public func remove<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items) {
        write({ $0.remove(items) })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchonously removes the object stored at this index.

    :param: index A YapDB.Index
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemoveAtIndex(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        asyncReadWriteWithBlock({ $0.removeAtIndex(index) }, completionQueue: queue, completionBlock: completion)
    }

    /**
    Asynchonously removes the object stored at this index.

    :param: indexes An Array<YapDB.Index>
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemoveAtIndexes(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        asyncReadWriteWithBlock({ $0.removeAtIndexes(indexes) }, completionQueue: queue, completionBlock: completion)
    }

    /**
    Synchonously removes any Persistable item.

    :param: item A Persistable item.
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemove<Item where Item: Persistable>(item: Item, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        asyncReadWriteWithBlock({ $0.remove(item) }, completionQueue: queue, completionBlock: completion)
    }

    /**
    Synchonously removes a sequence of Persistable items.

    :param: items A sequence of Persistable items.
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemove<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        asyncReadWriteWithBlock({ $0.remove(items) }, completionQueue: queue, completionBlock: completion)
    }
}



extension YapDatabase {

    /**
    Synchonously removes the object stored at this index.

    :param: index A YapDB.Index
    */
    public func removeAtIndex(index: YapDB.Index) {
        newConnection().removeAtIndex(index)
    }

    /**
    Synchonously removes the object stored at this index.

    :param: indexes An Array<YapDB.Index>
    */
    public func removeAtIndexes(indexes: [YapDB.Index]) {
        newConnection().removeAtIndexes(indexes)
    }

    /**
    Synchonously removes any Persistable item.

    :param: item A Persistable item.
    */
    public func remove<Item where Item: Persistable>(item: Item) {
        return newConnection().remove(item)
    }

    /**
    Synchonously removes a sequence of Persistable items.

    :param: items A sequence of Persistable items.
    */
    public func remove<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items) {
        return newConnection().remove(items)
    }
}

extension YapDatabase {

    /**
    Asynchonously removes the object stored at this index.

    :param: index A YapDB.Index
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemoveAtIndex(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        newConnection().asyncRemoveAtIndex(index, queue: queue, completion: completion)
    }

    /**
    Asynchonously removes the object stored at this index.

    :param: indexes An Array<YapDB.Index>
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemoveAtIndexes(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        newConnection().asyncRemoveAtIndexes(indexes, queue: queue, completion: completion)
    }

    /**
    Synchonously removes any Persistable item.

    :param: item A Persistable item.
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemove<Item where Item: Persistable>(item: Item, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        newConnection().asyncRemove(item, queue: queue, completion: completion)
    }

    /**
    Synchonously removes a sequence of Persistable items.

    :param: items A sequence of Persistable items.
    :param: queue The dispatch queue to run the completion closure on, defaults to the main queue
    :param: completion A void closure
    */
    public func asyncRemove<Items where Items: SequenceType, Items.Generator.Element: Persistable>(items: Items, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: () -> Void) {
        newConnection().asyncRemove(items, queue: queue, completion: completion)
    }
}


