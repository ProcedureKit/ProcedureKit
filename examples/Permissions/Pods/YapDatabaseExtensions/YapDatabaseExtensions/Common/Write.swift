//
//  Created by Daniel Thorpe on 22/04/2015.
//
//

import YapDatabase

// MARK: - YapDatabaseTransaction

extension YapDatabaseReadWriteTransaction {

    func writeAtIndex(index: YapDB.Index, object: AnyObject, metadata: AnyObject? = .None) {
        if let metadata: AnyObject = metadata {
            setObject(object, forKey: index.key, inCollection: index.collection, withMetadata: metadata)
        }
        else {
            setObject(object, forKey: index.key, inCollection: index.collection)
        }
    }
}

extension YapDatabaseReadWriteTransaction {

    /**
    Writes a Persistable object conforming to NSCoding to the database inside the read write transaction.
        
    :param: object An Object.
    :returns: The Object.
    */
    public func write<
        Object
        where
        Object: NSCoding,
        Object: Persistable>(object: Object) -> Object {
            writeAtIndex(indexForPersistable(object), object: object)
            return object
    }

    /**
    Writes a Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.
    
    :param: object An ObjectWithObjectMetadata.
    :returns: The ObjectWithObjectMetadata.
    */
    public func write<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata) -> ObjectWithObjectMetadata {
            writeAtIndex(indexForPersistable(object), object: object, metadata: object.metadata)
            return object
    }

    /**
    Writes a Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.
    
    :param: object An ObjectWithValueMetadata.
    :returns: The ObjectWithValueMetadata.
    */
    public func write<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(object: ObjectWithValueMetadata) -> ObjectWithValueMetadata {
            writeAtIndex(indexForPersistable(object), object: object, metadata: object.metadata.archive)
            return object
    }

    /**
    Writes a Persistable value, conforming to Saveable to the database inside the read write transaction.

    :param: value A Value.
    :returns: The Value.
    */
    public func write<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value) -> Value {
            writeAtIndex(indexForPersistable(value), object: value.archive)
            return value
    }

    /**
    Writes a Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: value A ValueWithValueMetadata.
    :returns: The ValueWithValueMetadata.
    */
    public func write<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata) -> ValueWithValueMetadata {
            writeAtIndex(indexForPersistable(value), object: value.archive, metadata: value.metadata.archive)
            return value
    }

    /**
    Writes a Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: value A ValueWithObjectMetadata.
    :returns: The ValueWithObjectMetadata.
    */
    public func write<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata) -> ValueWithObjectMetadata {
            writeAtIndex(indexForPersistable(value), object: value.archive, metadata: value.metadata)
            return value
    }
}

extension YapDatabaseReadWriteTransaction {

    /**
    Writes a sequence of Persistable Object instances conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of Object instances.
    :returns: An array of Object instances.
    */
    public func write<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects) -> [Object] {
            return objects.map { self.write($0) }
    }

    /**
    Writes a sequence of Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithObjectMetadata instances.
    :returns: An array of ObjectWithObjectMetadata instances.
    */
    public func write<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects) -> [ObjectWithObjectMetadata] {
            return objects.map { self.write($0) }
    }

    /**
    Writes a sequence of Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithValueMetadata instances.
    :returns: An array of ObjectWithValueMetadata instances.
    */
    public func write<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(objects: Objects) -> [ObjectWithValueMetadata] {
            return objects.map { self.write($0) }
    }

    /**
    Writes a sequence of Persistable Value instances conforming to Saveable to the database inside the read write transaction.

    :param: objects A SequenceType of Value instances.
    :returns: An array of Value instances.
    */
    public func write<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values) -> [Value] {
            return values.map { self.write($0) }
    }

    /**
    Writes a sequence of Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithValueMetadata instances.
    :returns: An array of ValueWithValueMetadata instances.
    */
    public func write<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(values: Values) -> [ValueWithValueMetadata] {
            return values.map { self.write($0) }
    }

    /**
    Writes a sequence of Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithObjectMetadata instances.
    :returns: An array of ValueWithObjectMetadata instances.
    */
    public func write<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values) -> [ValueWithObjectMetadata] {
            return values.map { self.write($0) }
    }
}

// MARK: - YapDatabaseConnection

extension YapDatabaseConnection {

    /**
    Synchonously writes a Persistable object conforming to NSCoding to the database using the connection.

    :param: object An Object.
    :returns: The Object.
    */
    public func write<
        Object
        where
        Object: NSCoding,
        Object: Persistable>(object: Object) -> Object {
            return write { $0.write(object) }
    }

    /**
    Synchonously writes a Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: object An ObjectWithObjectMetadata.
    :returns: The ObjectWithObjectMetadata.
    */
    public func write<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata) -> ObjectWithObjectMetadata {
            return write { $0.write(object) }
    }

    /**
    Synchonously writes a Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: object An ObjectWithValueMetadata.
    :returns: The ObjectWithValueMetadata.
    */
    public func write<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(object: ObjectWithValueMetadata) -> ObjectWithValueMetadata {
            return write { $0.write(object) }
    }

    /**
    Synchonously writes a Persistable value conforming to Saveable to the database using the connection.

    :param: value A Value.
    :returns: The Value.
    */
    public func write<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value) -> Value {
            return write { $0.write(value) }
    }

    /**
    Synchonously writes a Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: value A ValueWithValueMetadata.
    :returns: The ValueWithValueMetadata.
    */
    public func write<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata) -> ValueWithValueMetadata {
            return write { $0.write(value) }
    }

    /**
    Synchonously writes a Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: value A ValueWithObjectMetadata.
    :returns: The ValueWithObjectMetadata.
    */
    public func write<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata) -> ValueWithObjectMetadata {
            return write { $0.write(value) }
    }
}

extension YapDatabaseConnection {

    /**
    Asynchonously writes a Persistable object conforming to NSCoding to the database using the connection.

    :param: object An Object.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the Object.
    */
    public func asyncWrite<
        Object
        where
        Object: NSCoding,
        Object: Persistable>(object: Object, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object) -> Void) {
            asyncWrite({ $0.write(object) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: object An ObjectWithObjectMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ObjectWithObjectMetadata.
    */
    public func asyncWrite<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ObjectWithObjectMetadata) -> Void) {
            asyncWrite({ $0.write(object) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: object An ObjectWithValueMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ObjectWithValueMetadata.
    */
    public func asyncWrite<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable>(object: ObjectWithValueMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ObjectWithValueMetadata) -> Void) {
            asyncWrite({ $0.write(object) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value conforming to Saveable to the database using the connection.

    :param: value A Value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the Value.
    */
    public func asyncWrite<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value) -> Void) {
            asyncWrite({ $0.write(value) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: value An ValueWithValueMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ValueWithValueMetadata.
    */
    public func asyncWrite<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ValueWithValueMetadata) -> Void) {
            asyncWrite({ $0.write(value) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: value An ValueWithObjectMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ValueWithObjectMetadata.
    */
    public func asyncWrite<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ValueWithObjectMetadata) -> Void) {
            asyncWrite({ $0.write(value) }, queue: queue, completion: completion)
    }
}

extension YapDatabaseConnection {

    /**
    Synchonously writes Persistable objects conforming to NSCoding to the database using the connection.

    :param: objects A SequenceType of Object instances.
    :returns: An array of Object instances.
    */
    public func write<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects) -> [Object] {
            return write { $0.write(objects) }
    }

    /**
    Synchonously writes a sequence of Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithObjectMetadata instances.
    :returns: An array of ObjectWithObjectMetadata instances.
    */
    public func write<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects) -> [ObjectWithObjectMetadata] {
            return write { $0.write(objects) }
    }

    /**
    Synchonously writes a sequence of Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithValueMetadata instances.
    :returns: An array of ObjectWithValueMetadata instances.
    */
    public func write<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable>(objects: Objects) -> [ObjectWithValueMetadata] {
            return write { $0.write(objects) }
    }

    /**
    Synchonously writes Persistable values conforming to Saveable to the database using the connection.

    :param: values A SequenceType of Value instances.
    :returns: An array of Object instances.
    */
    public func write<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values) -> [Value] {
            return write { $0.write(values) }
    }

    /**
    Synchonously writes a sequence of Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithValueMetadata instances.
    :returns: An array of ValueWithValueMetadata instances.
    */
    public func write<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata>(values: Values) -> [ValueWithValueMetadata] {
            return write { $0.write(values) }
    }

    /**
    Synchonously writes a sequence of Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithObjectMetadata instances.
    :returns: An array of ValueWithObjectMetadata instances.
    */
    public func write<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values) -> [ValueWithObjectMetadata] {
            return write { $0.write(values) }
    }
}

extension YapDatabaseConnection {

    /**
    Asynchonously writes Persistable objects conforming to NSCoding to the database using the connection.

    :param: objects A SequenceType of Object instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances.
    */
    public func asyncWrite<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
            asyncWrite({ $0.write(objects) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithObjectMetadata instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of ObjectWithObjectMetadata instances.
    */
    public func asyncWrite<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ObjectWithObjectMetadata]) -> Void) {
            asyncWrite({ $0.write(objects) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithValueMetadata instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of ObjectWithValueMetadata instances.
    */
    public func asyncWrite<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ObjectWithValueMetadata]) -> Void) {
            asyncWrite({ $0.write(objects) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes Persistable values conforming to Saveable to the database using the connection.

    :param: values A SequenceType of Value instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances.
    */
    public func asyncWrite<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            asyncWrite({ $0.write(values) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithObjectMetadata instances.
    :returns: An array of ValueWithObjectMetadata instances.
    */
    public func asyncWrite<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ValueWithObjectMetadata]) -> Void) {
            asyncWrite({ $0.write(values) }, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithValueMetadata instances.
    :returns: An array of ValueWithValueMetadata instances.
    */
    public func asyncWrite<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.MetadataType: NSCoding,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ValueWithValueMetadata]) -> Void) {
            asyncWrite({ $0.write(values) }, queue: queue, completion: completion)
    }
}


// MARK: - YapDatabase

extension YapDatabase {

    /**
    Synchonously writes a Persistable object conforming to NSCoding to the database using a new connection.

    :param: object An Object.
    :returns: The Object.
    */
    public func write<Object where Object: NSCoding, Object: Persistable>(object: Object) -> Object {
        return newConnection().write(object)
    }

    /**
    Synchonously writes a Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: object An ObjectWithObjectMetadata.
    :returns: The ObjectWithObjectMetadata.
    */
    public func write<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata) -> ObjectWithObjectMetadata {
            return newConnection().write(object)
    }

    /**
    Synchonously writes a Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: object An ObjectWithValueMetadata.
    :returns: The ObjectWithValueMetadata.
    */
    public func write<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable>(object: ObjectWithValueMetadata) -> ObjectWithValueMetadata {
            return newConnection().write(object)
    }

    /**
    Synchonously writes a Persistable value conforming to Saveable to the database using a new connection.

    :param: value A Value.
    :returns: The Value.
    */
    public func write<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value) -> Value {
            return newConnection().write(value)
    }

    /**
    Synchonously writes a Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: value A ValueWithValueMetadata.
    :returns: The ValueWithValueMetadata.
    */
    public func write<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata) -> ValueWithValueMetadata {
            return newConnection().write(value)
    }

    /**
    Synchonously writes a Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: value A ValueWithObjectMetadata.
    :returns: The ValueWithObjectMetadata.
    */
    public func write<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata) -> ValueWithObjectMetadata {
            return newConnection().write(value)
    }
}

extension YapDatabase {

    /**
    Asynchonously writes a Persistable object conforming to NSCoding to the database using a new connection.

    :param: object An Object.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the Object.
    */
    public func asyncWrite<
        Object
        where
        Object: NSCoding,
        Object: Persistable>(object: Object, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Object) -> Void) {
            newConnection().asyncWrite(object, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable object with metadata, both conforming to NSCoding to the database using a new connection.

    :param: object An ObjectWithObjectMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ObjectWithObjectMetadata.
    */
    public func asyncWrite<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ObjectWithObjectMetadata) -> Void) {
            newConnection().asyncWrite(object, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable object, conforming to NSCoding, with metadata value type to the database using a new connection.

    :param: object An ObjectWithValueMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ObjectWithValueMetadata.
    */
    public func asyncWrite<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable>(object: ObjectWithValueMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ObjectWithValueMetadata) -> Void) {
        newConnection().asyncWrite(object, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value conforming to Saveable to the database using a new connection.

    :param: value A Value.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the Value.
    */
    public func asyncWrite<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (Value) -> Void) {
            newConnection().asyncWrite(value, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value with a metadata value, both conforming to Saveable, to the database using a new connection.

    :param: object An ValueWithValueMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ValueWithValueMetadata.
    */
    public func asyncWrite<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ValueWithValueMetadata) -> Void) {
            newConnection().asyncWrite(value, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database using a new connection.

    :param: object An ValueWithObjectMetadata.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives the ValueWithObjectMetadata.
    */
    public func asyncWrite<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (ValueWithObjectMetadata) -> Void) {
            newConnection().asyncWrite(value, queue: queue, completion: completion)
    }
}

extension YapDatabase {

    /**
    Synchonously writes Persistable objects conforming to NSCoding to the database using a new connection.

    :param: objects A SequenceType of Object instances.
    :returns: An array of Object instances.
    */
    public func write<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects) -> [Object] {
            return newConnection().write(objects)
    }

    /**
    Synchonously writes a sequence of Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithObjectMetadata instances.
    :returns: An array of ObjectWithObjectMetadata instances.
    */
    public func write<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects) -> [ObjectWithObjectMetadata] {
            return newConnection().write(objects)
    }

    /**
    Synchonously writes a sequence of Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithValueMetadata instances.
    :returns: An array of ObjectWithValueMetadata instances.
    */
    public func write<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType,
        ObjectWithValueMetadata: ValueMetadataPersistable>(objects: Objects) -> [ObjectWithValueMetadata] {
            return newConnection().write(objects)
    }

    /**
    Synchonously writes Persistable values conforming to Saveable to the database using a new connection.

    :param: values A SequenceType of Value instances.
    :returns: An array of Object instances.
    */
    public func write<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values) -> [Value] {
            return newConnection().write(values)
    }

    /**
    Synchonously writes a sequence of Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithValueMetadata instances.
    :returns: An array of ValueWithValueMetadata instances.
    */
    public func write<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata>(values: Values) -> [ValueWithValueMetadata] {
            return newConnection().write(values)
    }

    /**
    Synchonously writes a sequence of Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithObjectMetadata instances.
    :returns: An array of ValueWithObjectMetadata instances.
    */
    public func write<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values) -> [ValueWithObjectMetadata] {
            return newConnection().write(values)
    }
}

extension YapDatabase {

    /**
    Asynchonously writes Persistable objects conforming to NSCoding to the database using a new connection.

    :param: values A SequenceType of Object instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Object instances.
    */
    public func asyncWrite<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Object]) -> Void) {
            newConnection().asyncWrite(objects, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable object with metadata, both conforming to NSCoding to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithObjectMetadata instances.
    :returns: An array of ObjectWithObjectMetadata instances.
    */
    public func asyncWrite<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ObjectWithObjectMetadata]) -> Void) {
            newConnection().asyncWrite(objects, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable object, conforming to NSCoding, with metadata value type to the database inside the read write transaction.

    :param: objects A SequenceType of ObjectWithValueMetadata instances.
    :returns: An array of ObjectWithValueMetadata instances.
    */
    public func asyncWrite<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType: Archiver,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(objects: Objects, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ObjectWithValueMetadata]) -> Void) {
            newConnection().asyncWrite(objects, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes Persistable values conforming to Saveable to the database using a new connection.

    :param: values A SequenceType of Value instances.
    :param: queue A dispatch_queue_t, defaults to the main queue.
    :param: completion A closure which receives an array of Value instances.
    */
    public func asyncWrite<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([Value]) -> Void) {
            newConnection().asyncWrite(values, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable value with a metadata value, both conforming to Saveable, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithValueMetadata instances.
    :returns: An array of ValueWithValueMetadata instances.
    */
    public func asyncWrite<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ValueWithValueMetadata]) -> Void) {
            newConnection().asyncWrite(values, queue: queue, completion: completion)
    }

    /**
    Asynchonously writes a sequence of Persistable value, conforming to Saveable with a metadata object conforming to NSCoding, to the database inside the read write transaction.

    :param: objects A SequenceType of ValueWithObjectMetadata instances.
    :returns: An array of ValueWithObjectMetadata instances.
    */
    public func asyncWrite<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ([ValueWithObjectMetadata]) -> Void) {
            newConnection().asyncWrite(values, queue: queue, completion: completion)
    }
}

