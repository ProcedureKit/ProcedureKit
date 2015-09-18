//
//  WriteOperations.swift
//  YapDatabaseExtensions
//
//  Created by Daniel Thorpe on 26/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import YapDatabase

extension YapDatabaseConnection {

    public func writeBlockOperation(block: (YapDatabaseReadWriteTransaction) -> Void) -> NSOperation {
        return NSBlockOperation { self.asyncReadWriteWithBlock(block) }
    }
}

extension YapDatabaseConnection {

    public func writeOperation<
        Object
        where
        Object: NSCoding,
        Object: Persistable>(object: Object) -> NSOperation {
            return writeBlockOperation { $0.write(object) }
    }

    public func writeOperation<
        ObjectWithObjectMetadata
        where
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(object: ObjectWithObjectMetadata) -> NSOperation {
            return writeBlockOperation { $0.write(object) }
    }

    public func writeOperation<
        ObjectWithValueMetadata
        where
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(object: ObjectWithValueMetadata) -> NSOperation {
            return writeBlockOperation { $0.write(object) }
    }

    public func writeOperation<
        Value
        where
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(value: Value) -> NSOperation {
            return writeBlockOperation { $0.write(value) }
    }

    public func writeOperation<
        ValueWithValueMetadata
        where
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(value: ValueWithValueMetadata) -> NSOperation {
            return writeBlockOperation { $0.write(value) }
    }

    public func writeOperation<
        ValueWithObjectMetadata
        where
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(value: ValueWithObjectMetadata) -> NSOperation {
            return writeBlockOperation { $0.write(value) }
    }
}

extension YapDatabaseConnection {

    public func writeOperation<
        Objects, Object
        where
        Objects: SequenceType,
        Objects.Generator.Element == Object,
        Object: NSCoding,
        Object: Persistable>(objects: Objects) -> NSOperation {
            return writeBlockOperation { $0.write(objects) }
    }

    public func writeOperation<
        Objects, ObjectWithObjectMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithObjectMetadata,
        ObjectWithObjectMetadata: NSCoding,
        ObjectWithObjectMetadata: ObjectMetadataPersistable>(objects: Objects) -> NSOperation {
            return writeBlockOperation { $0.write(objects) }
    }

    public func writeOperation<
        Objects, ObjectWithValueMetadata
        where
        Objects: SequenceType,
        Objects.Generator.Element == ObjectWithValueMetadata,
        ObjectWithValueMetadata: NSCoding,
        ObjectWithValueMetadata: ValueMetadataPersistable,
        ObjectWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ObjectWithValueMetadata.MetadataType.ArchiverType.ValueType == ObjectWithValueMetadata.MetadataType>(objects: Objects) -> NSOperation {
            return writeBlockOperation { $0.write(objects) }
    }

    public func writeOperation<
        Values, Value
        where
        Values: SequenceType,
        Values.Generator.Element == Value,
        Value: Saveable,
        Value: Persistable,
        Value.ArchiverType: NSCoding,
        Value.ArchiverType.ValueType == Value>(values: Values) -> NSOperation {
            return writeBlockOperation { $0.write(values) }
    }

    public func writeOperation<
        Values, ValueWithValueMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithValueMetadata,
        ValueWithValueMetadata: Saveable,
        ValueWithValueMetadata: ValueMetadataPersistable,
        ValueWithValueMetadata.ArchiverType: NSCoding,
        ValueWithValueMetadata.ArchiverType.ValueType == ValueWithValueMetadata,
        ValueWithValueMetadata.MetadataType.ArchiverType: NSCoding,
        ValueWithValueMetadata.MetadataType.ArchiverType.ValueType == ValueWithValueMetadata.MetadataType>(values: Values) -> NSOperation {
            return writeBlockOperation { $0.write(values) }
    }

    public func writeOperation<
        Values, ValueWithObjectMetadata
        where
        Values: SequenceType,
        Values.Generator.Element == ValueWithObjectMetadata,
        ValueWithObjectMetadata: Saveable,
        ValueWithObjectMetadata: ObjectMetadataPersistable,
        ValueWithObjectMetadata.ArchiverType: NSCoding,
        ValueWithObjectMetadata.MetadataType: NSCoding,
        ValueWithObjectMetadata.ArchiverType.ValueType == ValueWithObjectMetadata>(values: Values) -> NSOperation {
            return writeBlockOperation { $0.write(values) }
    }
}
