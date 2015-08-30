//
//  Created by Daniel Thorpe on 22/04/2015.
//
//

import YapDatabase

// MARK: - YapDatabaseTransaction

extension YapDatabaseReadTransaction {

    /**
    Reads the object sored at this index using the transaction.
    
    :param: index The YapDB.Index value.
    :returns: An optional AnyObject.
    */
    public func readAtIndex(index: YapDB.Index) -> AnyObject? {
        return objectForKey(index.key, inCollection: index.collection)
    }

    /**
    Reads the object sored at this index using the transaction.
    
    :param: index The YapDB.Index value.
    :returns: An optional Object.
    */
    public func readAtIndex<Object where Object: Persistable>(index: YapDB.Index) -> Object? {
        return readAtIndex(index) as? Object
    }

    /**
    Unarchives a value type if stored at this index
    
    :param: index The YapDB.Index value.
    :returns: An optional Value.
    */
    public func readAtIndex<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType.ValueType == Value>(index: YapDB.Index) -> Value? {
            return Value.ArchiverType.unarchive(readAtIndex(index))
    }
}

extension YapDatabaseReadTransaction {

    /**
    Reads any metadata sored at this index using the transaction.

    :param: index The YapDB.Index value.
    :returns: An optional AnyObject.
    */
    public func readMetadataAtIndex(index: YapDB.Index) -> AnyObject? {
        return metadataForKey(index.key, inCollection: index.collection)
    }

    /**
    Reads metadata which is an object type sored at this index using the transaction.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataObject.
    */
    public func readMetadataAtIndex<
        MetadataObject
        where
        MetadataObject: NSCoding>(index: YapDB.Index) -> MetadataObject? {
            return readMetadataAtIndex(index) as? MetadataObject
    }

    /**
    Unarchives metadata which is a value type if stored at this index using the transaction.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataValue.
    */
    public func readMetadataAtIndex<
        MetadataValue
        where
        MetadataValue: Saveable,
        MetadataValue.ArchiverType: NSCoding,
        MetadataValue.ArchiverType.ValueType == MetadataValue>(index: YapDB.Index) -> MetadataValue? {
            return MetadataValue.ArchiverType.unarchive(readMetadataAtIndex(index))
    }
}

extension YapDatabaseReadTransaction {

    /**
    Reads the objects sored at these indexes using the transaction.
    
    :param: indexes An array of YapDB.Index values.
    :returns: An array of Object instances.
    */
    public func readAtIndexes<
        Object
        where
        Object: Persistable>(indexes: [YapDB.Index]) -> [Object] {
            return indexes.unique().flatMap { self.readAtIndex($0) }
    }

    /**
    Reads the values sored at these indexes using the transaction.
    
    :param: indexes An array of YapDB.Index values.
    :returns: An array of Value instances.
    */
    public func readAtIndexes<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType.ValueType == Value>(indexes: [YapDB.Index]) -> [Value] {
            return indexes.unique().flatMap { self.readAtIndex($0) }
    }
}

extension YapDatabaseReadTransaction {

    /**
    Reads the Object sored by key in this transaction.

    :param: key A String
    :returns: An optional Object
    */
    public func read<
        Object
        where
        Object: Persistable>(key: String) -> Object? {
            return objectForKey(key, inCollection: Object.collection) as? Object
    }

    /**
    Reads the Value sored by key in this transaction.

    :param: key A String
    :returns: An optional Value
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(key: String) -> Value? {
            return Value.ArchiverType.unarchive(objectForKey(key, inCollection: Value.collection))
    }
}

extension YapDatabaseReadTransaction {

    /**
    Reads the objects at the given keys in this transaction. Keys which 
    have no corresponding objects will be filtered out.

    :param: keys An array of String instances
    :returns: An array of Object types.
    */
    public func read<
        Object
        where
        Object: Persistable>(keys: [String]) -> [Object] {
            return keys.unique().flatMap { self.read($0) }
    }

    /**
    Reads the values at the given keys in this transaction. Keys which 
    have no corresponding values will be filtered out.

    :param: keys An array of String instances
    :returns: An array of Value types.
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> [Value] {
            return keys.unique().flatMap { self.read($0) }
    }
}

extension YapDatabaseReadTransaction {

    /**
    Reads all the items in the database for a particular Persistable Object.
    Example usage:
    
        let people: [Person] = transaction.readAll()

    :returns: An array of Object types.
    */
    public func readAll<Object where Object: Persistable>() -> [Object] {
        return (allKeysInCollection(Object.collection) as! [String]).flatMap { self.read($0) }
    }

    /**
    Reads all the items in the database for a particular Persistable Value.
    Example usage:

        let barcodes: [Barcode] = transaction.readAll()

    :returns: An array of Value types.
    */
    public func readAll<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>() -> [Value] {
            return (allKeysInCollection(Value.collection) as! [String]).flatMap { self.read($0) }
    }
}

extension YapDatabaseReadTransaction {

    /**
    Returns an array of Object type for the given keys, with an array of keys which don't have
    corresponding objects in the database.

        let (people: [Person], missing) = transaction.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Object], [String]) tuple.
    */
    public func filterExisting<Object where Object: Persistable>(keys: [String]) -> ([Object], [String]) {
        let existing: [Object] = read(keys)
        let existingKeys = existing.map { indexForPersistable($0).key }
        let missingKeys = keys.filter { !existingKeys.contains($0) }
        return (existing, missingKeys)
    }

    /**
    Returns an array of Value type for the given keys, with an array of keys which don't have
    corresponding values in the database.

        let (barcode: [Barcode], missing) = transaction.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Value], [String]) tuple.
    */
    public func filterExisting<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> ([Value], [String]) {
            let existing: [Value] = read(keys)
            let existingKeys = existing.map { indexForPersistable($0).key }
            let missingKeys = keys.filter { !existingKeys.contains($0) }
            return (existing, missingKeys)
    }
}






// MARK: - YapDatabaseConnection

extension YapDatabaseConnection {

    /**
    Synchronously reads the object sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional AnyObject.
    */
    public func readAtIndex(index: YapDB.Index) -> AnyObject? {
        return read({ $0.readAtIndex(index) })
    }

    /**
    Synchronously reads the Object sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional Object.
    */
    public func readAtIndex<Object where Object: Persistable>(index: YapDB.Index) -> Object? {
        return read({ $0.readAtIndex(index) })
    }

    /**
    Synchronously reads the Value sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional Value.
    */
    public func readAtIndex<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(index: YapDB.Index) -> Value? {
            return read({ $0.readAtIndex(index) })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchronously reads the Object sored at this index using the connection.

    :param: index The YapDB.Index value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Object
    */
    public func asyncReadAtIndex<Object where Object: Persistable>(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object?) -> Void) {
        asyncRead({ $0.readAtIndex(index) }, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value sored at this index using the connection.

    :param: index The YapDB.Index value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Value
    */
    public func asyncReadAtIndex<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType.ValueType == Value>(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value?) -> Void) {
            asyncRead({ $0.readAtIndex(index) }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads the metadata sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional AnyObject.
    */
    public func readMetadataAtIndex(index: YapDB.Index) -> AnyObject? {
        return read { $0.readMetadataAtIndex(index) }
    }

    /**
    Synchronously reads the object metadata sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataObject.
    */
    public func readMetadataAtIndex<
        MetadataObject
        where
        MetadataObject: NSCoding>(index: YapDB.Index) -> MetadataObject? {
            return read { $0.readMetadataAtIndex(index) as? MetadataObject }
    }

    /**
    Synchronously metadata which is a value type if stored at this index using the transaction.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataValue.
    */
    public func readMetadataAtIndex<
        MetadataValue
        where
        MetadataValue: Saveable,
        MetadataValue.ArchiverType: NSCoding,
        MetadataValue.ArchiverType.ValueType == MetadataValue>(index: YapDB.Index) -> MetadataValue? {
            return read { $0.readMetadataAtIndex(index) }
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads the objects sored at these indexes using the connection.

    :param: indexes An array of YapDB.Index values.
    :returns: An array of Object instances.
    */
    public func readAtIndexes<Object where Object: Persistable>(indexes: [YapDB.Index]) -> [Object] {
        return read({ $0.readAtIndexes(indexes) })
    }

    /**
    Synchronously reads the values sored at these indexes using the connection.

    :param: indexes An array of YapDB.Index values.
    :returns: An array of Value instances.
    */
    public func readAtIndexes<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(indexes: [YapDB.Index]) -> [Value] {
            return read({ $0.readAtIndexes(indexes) })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchronously reads the objects sored at these indexes using the connection.

    :param: indexes An array of YapDB.Index values.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances
    */
    public func asyncReadAtIndexes<Object where Object: Persistable>(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
        asyncRead({ $0.readAtIndexes(indexes) }, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the values sored at these indexes using the connection.

    :param: indexes An array of YapDB.Index values.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances
    */
    public func asyncReadAtIndexes<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            asyncRead({ $0.readAtIndexes(indexes) }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads the Object sored by key in this connection.

    :param: key A String
    :returns: An optional Object
    */
    public func read<Object where Object: Persistable>(key: String) -> Object? {
        return read({ $0.read(key) })
    }

    /**
    Synchronously reads the Value sored by key in this connection.

    :param: key A String
    :returns: An optional Value
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(key: String) -> Value? {
            return read({ $0.read(key) })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchronously reads the Object sored by key in this connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Object
    */
    public func asyncRead<Object where Object: Persistable>(key: String, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object?) -> Void) {
        asyncRead({ $0.read(key) }, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value sored by key in this connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Value
    */
    public func asyncRead<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(key: String, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value?) -> Void) {
            asyncRead({ $0.read(key) }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads the Object instances sored by the keys in this connection.

    :param: keys An array of String instances
    :returns: An array of Object instances
    */
    public func read<Object where Object: Persistable>(keys: [String]) -> [Object] {
        return read({ $0.read(keys) })
    }

    /**
    Synchronously reads the Value instances sored by the keys in this connection.

    :param: keys An array of String instances
    :returns: An array of Value instances
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> [Value] {
            return read({ $0.read(keys) })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchronously reads the Object instances sored by the keys in this connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances
    */
    public func asyncRead<Object where Object: Persistable>(keys: [String], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
        asyncRead({ $0.read(keys) }, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value instances sored by the keys in this connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances
    */
    public func asyncRead<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            asyncRead({ $0.read(keys) }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads all the items in the database for a particular Persistable Object.
    Example usage:

        let people: [Person] = connection.readAll()

    :returns: An array of Object types.
    */
    public func readAll<Object where Object: Persistable>() -> [Object] {
        return read({ $0.readAll() })
    }

    /**
    Synchronously reads all the items in the database for a particular Persistable Value.
    Example usage:

    let barcodes: [Barcode] = connection.readAll()

    :returns: An array of Value types.
    */
    public func readAll<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>() -> [Value] {
            return read({ $0.readAll() })
    }
}

extension YapDatabaseConnection {

    /**
    Asynchronously reads all the items in the database for a particular Persistable Object.
    Example usage:

        connection.readAll() { (people: [Person] in }

    :returns: An array of Object types.
    */
    public func asyncReadAll<Object where Object: Persistable>(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
        asyncRead({ $0.readAll() }, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads all the items in the database for a particular Persistable Value.
    Example usage:

        connection.readAll() { (barcodes: [Barcode] in }

    :returns: An array of Value types.
    */
    public func asyncReadAll<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            asyncRead({ $0.readAll() }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously returns an array of Object type for the given keys, with an array of keys which don't have
    corresponding objects in the database.

        let (people: [Person], missing) = connection.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Object], [String]) tuple.
    */
    public func filterExisting<Object where Object: Persistable>(keys: [String]) -> (existing: [Object], missing: [String]) {
        return read({ $0.filterExisting(keys) })
    }

    /**
    Synchronously returns an array of Value type for the given keys, with an array of keys which don't have
    corresponding values in the database.

        let (barcode: [Barcode], missing) = connection.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Value], [String]) tuple.
    */
    public func filterExisting<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> (existing: [Value], missing: [String]) {
            return read({ $0.filterExisting(keys) })
    }
}


// MARK: - YapDatabase

extension YapDatabase {

    /**
    Synchronously reads the Object sored at this index using a new connection.

    :param: index The YapDB.Index value.
    :returns: An optional Object.
    */
    public func readAtIndex<Object where Object: Persistable>(index: YapDB.Index) -> Object? {
        return newConnection().readAtIndex(index)
    }

    /**
    Synchronously reads the Value sored at this index using a new connection.

    :param: index The YapDB.Index value.
    :returns: An optional Value.
    */
    public func readAtIndex<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(index: YapDB.Index) -> Value? {
            return newConnection().readAtIndex(index)
    }
}

extension YapDatabase {

    /**
    Asynchronously reads the Object sored at this index using a new connection.

    :param: index The YapDB.Index value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Object
    */
    public func asyncReadAtIndex<Object where Object: Persistable>(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object?) -> Void) {
        newConnection().asyncReadAtIndex(index, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value sored at this index using a new connection.

    :param: index The YapDB.Index value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Value
    */
    public func asyncReadAtIndex<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType.ValueType == Value>(index: YapDB.Index, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value?) -> Void) {
            newConnection().asyncReadAtIndex(index, queue: queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchronously reads the object metadata sored at this index using the connection.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataObject.
    */
    public func readMetadataAtIndex<
        MetadataObject
        where
        MetadataObject: NSCoding>(index: YapDB.Index) -> MetadataObject? {
            return newConnection().readMetadataAtIndex(index) as? MetadataObject
    }

    /**
    Synchronously metadata which is a value type if stored at this index using the transaction.

    :param: index The YapDB.Index value.
    :returns: An optional MetadataValue.
    */
    public func readMetadataAtIndex<
        MetadataValue
        where
        MetadataValue: Saveable,
        MetadataValue.ArchiverType: NSCoding,
        MetadataValue.ArchiverType.ValueType == MetadataValue>(index: YapDB.Index) -> MetadataValue? {
            return newConnection().readMetadataAtIndex(index)
    }
}

extension YapDatabase {

    /**
    Synchronously reads the objects sored at these indexes using a new connection.

    :param: indexes An array of YapDB.Index values.
    :returns: An array of Object instances.
    */
    public func readAtIndexes<Object where Object: Persistable>(indexes: [YapDB.Index]) -> [Object] {
        return newConnection().readAtIndexes(indexes)
    }

    /**
    Synchronously reads the values sored at these indexes using a new connection.

    :param: indexes An array of YapDB.Index values.
    :returns: An array of Value instances.
    */
    public func readAtIndexes<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(indexes: [YapDB.Index]) -> [Value] {
            return newConnection().readAtIndexes(indexes)
    }
}

extension YapDatabase {

    /**
    Asynchronously  reads the objects sored at these indexes using a new connection.

    :param: indexes An array of YapDB.Index values.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances
    */
    public func asyncReadAtIndexes<Object where Object: Persistable>(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
        return newConnection().asyncReadAtIndexes(indexes, queue: queue, completion: completion)
    }

    /**
    Asynchronously  reads the values sored at these indexes using a new connection.

    :param: indexes An array of YapDB.Index values.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances
    */
    public func asyncReadAtIndexes<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(indexes: [YapDB.Index], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            return newConnection().asyncReadAtIndexes(indexes, queue: queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchronously reads the Object sored by key in a new connection.

    :param: key A String
    :returns: An optional Object
    */
    public func read<Object where Object: Persistable>(key: String) -> Object? {
        return newConnection().read(key)
    }

    /**
    Synchronously reads the Value sored by key in a new connection.

    :param: key A String
    :returns: An optional Value
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(key: String) -> Value? {
            return newConnection().read(key)
    }
}

extension YapDatabase {

    /**
    Asynchronously reads the Object sored by key in a new connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Object
    */
    public func asyncRead<Object where Object: Persistable>(key: String, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object?) -> Void) {
        newConnection().asyncRead(key, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value sored by key in a new connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an optional Value
    */
    public func asyncRead<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(key: String, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value?) -> Void) {
            newConnection().asyncRead(key, queue: queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchronously reads the Object instances sored by the keys in a new connection.

    :param: keys An array of String instances
    :returns: An array of Object instances
    */
    public func read<
        Object
        where
        Object: Persistable>(keys: [String]) -> [Object] {
            return newConnection().read(keys)
    }

    /**
    Synchronously reads the Value instances sored by the keys in a new connection.

    :param: keys An array of String instances
    :returns: An array of Value instances
    */
    public func read<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> [Value] {
            return newConnection().read(keys)
    }
}

extension YapDatabase {

    /**
    Asynchronously reads the Object instances sored by the keys in a new connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances
    */
    public func asyncRead<
        Object
        where
        Object: Persistable>(keys: [String], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
            newConnection().asyncRead(keys, queue: queue, completion: completion)
    }

    /**
    Asynchronously reads the Value instances sored by the keys in a new connection.

    :param: keys An array of String instances
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances
    */
    public func asyncRead<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String], queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            newConnection().asyncRead(keys, queue: queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchronously reads all the items in the database for a particular Persistable Object in a new connection.
    Example usage:

        let people: [Person] = database.readAll()

    :returns: An array of Object types.
    */
    public func readAll<
        Object
        where
        Object: Persistable>() -> [Object] {
            return newConnection().readAll()
    }

    /**
    Synchronously reads all the items in the database for a particular Persistable Value in a new connection.
    Example usage:

    let barcodes: [Barcode] = database.readAll()

    :returns: An array of Value types.
    */
    public func readAll<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>() -> [Value] {
            return newConnection().readAll()
    }
}

extension YapDatabase {

    /**
    Asynchronously reads all the items in the database for a particular Persistable Object in a new connection.
    Example usage:

        database.readAll() { (people: [Person] in }

    :returns: An array of Object types.
    */
    public func asyncReadAll<
        Object
        where
        Object: Persistable>(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
            newConnection().asyncReadAll(queue, completion: completion)
    }

    /**
    Asynchronously reads all the items in the database for a particular Persistable Value in a new connection.
    Example usage:

        database.readAll() { (barcodes: [Barcode] in }

    :returns: An array of Object types.
    */
    public func asyncReadAll<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            newConnection().asyncReadAll(queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchronously returns an array of Object type for the given keys, with an array of keys which don't have
    corresponding objects in the database, using a new connection.

        let (people: [Person], missing) = database.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Object], [String]) tuple.
    */
    public func filterExisting<Object where Object: Persistable>(keys: [String]) -> (existing: [Object], missing: [String]) {
        return newConnection().filterExisting(keys)
    }

    /**
    Synchronously returns an array of Value type for the given keys, with an array of keys which don't have
    corresponding values in the database, using a new connection.

        let (barcode: [Barcode], missing) = database.filterExisting(keys)

    :param: keys An array of String instances
    :returns: An ([Value], [String]) tuple.
    */
    public func filterExisting<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(keys: [String]) -> (existing: [Value], missing: [String]) {
            return newConnection().filterExisting(keys)
    }
}



