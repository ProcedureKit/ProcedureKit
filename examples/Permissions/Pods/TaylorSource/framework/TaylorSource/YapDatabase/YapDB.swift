//
//  Created by Daniel Thorpe on 20/04/2015.
//

import UIKit
import YapDatabase
import YapDatabaseExtensions

/**
A struct which owns a data mapper closure, used to map AnyObject? which is
stored in YapDatabase into strongly typed T? instances.
*/
public struct Configuration<T> {
    typealias DataItemMapper = (AnyObject?) -> T?

    let fetchConfiguration: YapDB.FetchConfiguration
    let itemMapper: DataItemMapper

    /**
    Initializer for the configuration.
    
    The DataItemMapper is designed to be used to un-archive value type. For example
    
        let config: Configuration<Event> = Configuration(fetch: events()) { valueFromArchive($0) }

    - parameter fetch: A YapDB.FetchConfiguration value. This is essentially the View extension with mappings configure block.
    - parameter itemMapper: A closure which is used to strongly type data coming out of YapDatabase.
    */
    public init(fetch: YapDB.FetchConfiguration, itemMapper i: DataItemMapper) {
        fetchConfiguration = fetch
        itemMapper = i
    }

    func createMappingsRegisteredInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) -> YapDatabaseViewMappings {
        return fetchConfiguration.createMappingsRegisteredInDatabase(database, withConnection: connection)
    }
}

/**
A struct which receives a database instance and Configuration<T> instance. It is 
responsible for owning the YapDatabaseViewMappings object, and its 
readOnlyConnection.

It implements SequenceType, and Int based CollectionType.

It has an NSIndexPath based API for accessing items.
*/
public struct Mapper<T>: SequenceType, CollectionType {

    let readOnlyConnection: YapDatabaseConnection
    var configuration: Configuration<T>
    var mappings: YapDatabaseViewMappings

    var name: String {
        return configuration.fetchConfiguration.name
    }

    var fetch: (inTransaction: YapDatabaseReadTransaction, atIndexPath: NSIndexPath) -> T? {
        return { (transaction, indexPath) in
            if let viewTransaction = transaction.ext(self.name) as? YapDatabaseViewTransaction {
                return self.configuration.itemMapper(viewTransaction.objectAtIndexPath(indexPath, withMappings: self.mappings))
            }
            return self.configuration.itemMapper(.None)
        }
    }

    public let startIndex: Int = 0
    public var endIndex: Int

    public subscript(i: Int) -> T {
        return itemAtIndexPath(mappings[i])!
    }

    /**
    Initialiser for Mapper<T>. During initialization, the 
    YapDatabaseViewMappings is created (and registered in the database).
    
    A new connection is created, and long lived read transaction started.
    
    On said transaction, the mappings object is updated.
    
    - parameter database: The YapDatabase instance.
    - parameter configuration: A Configuration<T> value.
    */
    public init(database: YapDatabase, configuration c: Configuration<T>) {
        configuration = c
        let _mappings = configuration.createMappingsRegisteredInDatabase(database, withConnection: .None)

        readOnlyConnection = database.newConnection()
        readOnlyConnection.beginLongLivedReadTransaction()
        readOnlyConnection.readWithBlock { transaction in
            _mappings.updateWithTransaction(transaction)
        }

        mappings = _mappings
        endIndex = Int(mappings.numberOfItemsInAllGroups())
    }

    mutating func replaceConfiguration(configuration c: Configuration<T>) {
        configuration = c
        let _mappings = configuration.createMappingsRegisteredInDatabase(readOnlyConnection.database, withConnection: .None)
        readOnlyConnection.readWithBlock { transaction in
            _mappings.updateWithTransaction(transaction)
        }
        mappings = _mappings
        endIndex = Int(mappings.numberOfItemsInAllGroups())
    }

    /**
    Returns a closure which will access the item at the index path in a provided read transaction.
    
    - parameter indexPath: The NSIndexPath to look up the item.
    - returns: (YapDatabaseReadTransaction) -> T? closure.
    */
    public func itemInTransactionAtIndexPath(indexPath: NSIndexPath) -> (YapDatabaseReadTransaction) -> T? {
        return { transaction in self.fetch(inTransaction: transaction, atIndexPath: indexPath) }
    }

    /**
    Returns a closure which will access the item in a read transaction at the provided index path.

    - parameter transaction: A YapDatabaseReadTransaction
    - returns: (NSIndexPath) -> T? closure.
    */
    public func itemAtIndexPathInTransaction(transaction: YapDatabaseReadTransaction) -> (NSIndexPath) -> T? {
        return { indexPath in self.fetch(inTransaction: transaction, atIndexPath: indexPath) }
    }

    /**
    Gets the item at the index path, using the internal readOnlyTransaction.

    - parameter indexPath: A NSIndexPath
    - returns: An optional T
    */
    public func itemAtIndexPath(indexPath: NSIndexPath) -> T? {
        return readOnlyConnection.read(itemInTransactionAtIndexPath(indexPath))
    }

    /**
    Gets the item at the index path, using a provided read transaction.

    - parameter indexPath: A NSIndexPath
    - parameter transaction: A YapDatabaseReadTransaction
    - returns: An optional T
    */
    public func itemAtIndexPath(indexPath: NSIndexPath, inTransaction transaction: YapDatabaseReadTransaction) -> T? {
        return fetch(inTransaction: transaction, atIndexPath: indexPath)
    }

    /**
    Reverse looks up the NSIndexPath for a key in a collection.

    - parameter key: A String
    - parameter collection: A String
    - returns: An optional NSIndexPath
    */
    public func indexPathForKey(key: String, inCollection collection: String) -> NSIndexPath? {
        return readOnlyConnection.read { transaction in
            if let viewTransaction = transaction.ext(self.name) as? YapDatabaseViewTransaction {
                return viewTransaction.indexPathForKey(key, inCollection: collection, withMappings: self.mappings)
            }
            return .None
        }
    }

    public func generate() -> AnyGenerator<T> {
        let mappingsGenerator = mappings.generate()
        return anyGenerator {
            if let indexPath = mappingsGenerator.next() {
                return self.itemAtIndexPath(indexPath)
            }
            return .None
        }
    }
}

/**
A database observer. This struct is used to respond to database changes and 
execute changes sets on the provided update block. 

Observer<T> implements SequenceType, and Int based CollectionType.
*/
public struct Observer<T> {

    let database: YapDatabase
    let mapper: Mapper<T>
    let queue: dispatch_queue_t
    let changes: YapDatabaseViewMappings.Changes
    var notificationHandler: NotificationCenterHandler!

    var configuration: Configuration<T> {
        return mapper.configuration
    }

    var name: String {
        return mapper.name
    }

    var mappings: YapDatabaseViewMappings {
        return mapper.mappings
    }

    var readOnlyConnection: YapDatabaseConnection {
        return mapper.readOnlyConnection
    }

    /**
    The initaliser. The observer owns the database instances, and then
    creates and owns a Mapper<T> using the configuration.
    
    Lastly, it registers for database changes.
    
    When YapDatabase posts a notification, the Observer posts it's update
    block through a concurrent queue using a dispatch_barrier_async.
    
    - parameter database: The YapDatabase instance.
    - parameter update: An update block, see extension on YapDatabaseViewMappings.
    :configuration: A Configuration<T> instance.
    */
    public init(database db: YapDatabase, changes c: YapDatabaseViewMappings.Changes, configuration: Configuration<T>) {
        database = db
        queue = dispatch_queue_create("TaylorSource.Database.Observer", DISPATCH_QUEUE_CONCURRENT)
        dispatch_set_target_queue(queue, Queue.UserInitiated.queue)
        mapper = Mapper(database: db, configuration: configuration)
        changes = c
        registerForDatabaseChanges()
    }

    mutating func unregisterForDatabaseChanges() {
        notificationHandler = .None
    }

    mutating func registerForDatabaseChanges() {
        notificationHandler = NSNotificationCenter.addObserverForName(YapDatabaseModifiedNotification, object: database, withCallback: processChangesWithBlock(changes))
    }

    func processChangesWithBlock(changes: YapDatabaseViewMappings.Changes) -> (NSNotification) -> Void {
        return { _ in
            if let changeset = self.createChangeset() {
                self.processChanges {
                    changes(changeset)
                }
            }
        }
    }

    func createChangeset() -> YapDatabaseViewMappings.Changeset? {
        let notifications = readOnlyConnection.beginLongLivedReadTransaction()

        var sectionChanges: NSArray? = nil
        var rowChanges: NSArray? = nil

        if let viewConnection = readOnlyConnection.ext(name) as? YapDatabaseViewConnection {
            viewConnection.getSectionChanges(&sectionChanges, rowChanges: &rowChanges, forNotifications: notifications, withMappings: mappings)
        }

        if (sectionChanges?.count ?? 0) == 0 && (rowChanges?.count ?? 0) == 0 {
            return .None
        }

        let changes: YapDatabaseViewMappings.Changeset = (sectionChanges as? [YapDatabaseViewSectionChange] ?? [], rowChanges as? [YapDatabaseViewRowChange] ?? [])
        return changes
    }

    // Thread Safety

    private func processChanges(block: dispatch_block_t) {
        dispatch_barrier_async(queue) {
            dispatch_async(Queue.Main.queue, block)
        }
    }

    // Public API

    /**
    Returns a closure which will access the item at the index path in a provided read transaction.

    - parameter indexPath: The NSIndexPath to look up the item.
    - returns: (YapDatabaseReadTransaction) -> T? closure.
    */
    public func itemInTransactionAtIndexPath(indexPath: NSIndexPath) -> (YapDatabaseReadTransaction) -> T? {
        return mapper.itemInTransactionAtIndexPath(indexPath)
    }

    /**
    Returns a closure which will access the item in a read transaction at the provided index path.

    - parameter transaction: A YapDatabaseReadTransaction
    - returns: (NSIndexPath) -> T? closure.
    */
    public func itemAtIndexPathInTransaction(transaction: YapDatabaseReadTransaction) -> (NSIndexPath) -> T? {
        return mapper.itemAtIndexPathInTransaction(transaction)
    }

    /**
    Gets the item at the index path, using the internal readOnlyTransaction.

    - parameter indexPath: A NSIndexPath
    - returns: An optional T
    */
    public func itemAtIndexPath(indexPath: NSIndexPath) -> T? {
        return mapper.itemAtIndexPath(indexPath)
    }

    /**
    Gets the item at the index path, using a provided read transaction.

    - parameter indexPath: A NSIndexPath
    - parameter transaction: A YapDatabaseReadTransaction
    - returns: An optional T
    */
    public func itemAtIndexPath(indexPath: NSIndexPath, inTransaction transaction: YapDatabaseReadTransaction) -> T? {
        return mapper.itemAtIndexPath(indexPath, inTransaction: transaction)
    }

    /**
    Reverse looks up the NSIndexPath for a key in a collection.

    - parameter key: A String
    - parameter collection: A String
    - returns: An optional NSIndexPath
    */
    public func indexPathForKey(key: String, inCollection collection: String) -> NSIndexPath? {
        return mapper.indexPathForKey(key, inCollection: collection)
    }
}

extension Observer: SequenceType {

    public func generate() -> AnyGenerator<T> {
        let mappingsGenerator = mappings.generate()
        return anyGenerator { () -> T? in
            if let indexPath = mappingsGenerator.next() {
                return self.itemAtIndexPath(indexPath)
            }
            return nil
        }
    }
}

extension Observer: CollectionType {

    public var startIndex: Int {
        return mapper.startIndex
    }

    public var endIndex: Int {
        return mapper.endIndex
    }

    public subscript(i: Int) -> T {
        return mapper[i]
    }
}

extension YapDatabaseViewMappings {

    /**
    Tuple type used to collect changes from YapDatabase.
    */
    public typealias Changeset = (sections: [YapDatabaseViewSectionChange], items: [YapDatabaseViewRowChange])

    /**
    Definition of a closure type which receives the changes from YapDatabase.
    */
    public typealias Changes = (Changeset) -> Void
}


// MARK: - SequenceType

/**
Implements SequenceType with NSIndexPath elements.
*/
extension YapDatabaseViewMappings: SequenceType {

    public func generate() -> AnyGenerator<NSIndexPath> {
        let countSections = Int(numberOfSections())
        var next = (section: 0, item: 0)
        return anyGenerator {
            let countItemsInSection = Int(self.numberOfItemsInSection(UInt(next.section)))
            if next.item < countItemsInSection {
                return NSIndexPath(forItem: next.item++, inSection: next.section)
            }
            else if next.section < countSections - 1 {
                next.item = 0
                next.section++
                return NSIndexPath(forItem: next.item++, inSection: next.section)
            }
            return .None
        }
    }
}

// MARK: - CollectionType

/**
Implements CollectionType with an Int index type returning NSIndexPath.
*/
extension YapDatabaseViewMappings: CollectionType {

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return Int(numberOfItemsInAllGroups())
    }

    public subscript(i: Int) -> NSIndexPath {
        get {
            var (section, item, accumulator, remainder, target) = (0, 0, 0, i, i)

            while accumulator < target {
                let count = Int(numberOfItemsInSection(UInt(section)))
                if (accumulator + count - 1) < target {
                    accumulator += count
                    remainder -= count
                    section++
                }
                else {
                    break
                }
            }

            item = remainder

            return NSIndexPath(forItem: item, inSection: section)
        }
    }
}

