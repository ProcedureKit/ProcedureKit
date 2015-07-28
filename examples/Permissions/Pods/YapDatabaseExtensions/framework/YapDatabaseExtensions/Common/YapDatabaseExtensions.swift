//
//  Created by Daniel Thorpe on 08/04/2015.
//

import YapDatabase

/**

This is a struct used as a namespace for new types to
avoid any possible future clashes with `YapDatabase` types.

*/
public struct YapDB {

    /**
    Helper function for evaluating the path to a database for easy use in the YapDatabase constructor.
    
    :param: directory a NSSearchPathDirectory value, use .DocumentDirectory for production.
    :param: name a String, the name of the sqlite file.
    :param: suffix a String, will be appended to the name of the file.
    
    :returns: a String
    */
    public static func pathToDatabase(directory: NSSearchPathDirectory, name: String, suffix: String? = .None) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(directory, .UserDomainMask, true)
        let directory: String = (paths.first as? String) ?? NSTemporaryDirectory()
        let filename: String = {
            if let suffix = suffix {
                return "\(name)-\(suffix).sqlite"
            }
            return "\(name).sqlite"
            }()

        return directory.stringByAppendingPathComponent(filename)
    }

    /// Type of closure which can perform operations on newly created/opened database instances.
    public typealias DatabaseOperationsBlock = (YapDatabase) -> Void

    /**
    Conveniently create or read a YapDatabase with the given name in the application's documents directory.
    
    Optionally, pass a block which receives the database instance, which is called
    before being returned. This block allows for things like registering extensions.
    
    Typical usage in a production environment would be to use this inside a singleton pattern, eg
    
        extension YapDB {
            public static var userDefaults: YapDatabase {
                get {
                    struct DatabaseSingleton {
                        static func database() -> YapDatabase {
                            return YapDB.databaseNamed("User Defaults")
                        }
                        static let instance = DatabaseSingleton.database()
                    }
                    return DatabaseSingleton.instance
                }
            }
        }

    which would allow the following behavior in your app:
    
        let userDefaultDatabase = YapDB.userDefaults
    
    Note that you can only use this convenience if you use the default serializers
    and sanitizers etc.

    :param: name a String, which will be the name of the SQLite database in the documents folder.
    :param: operations a DatabaseOperationsBlock closure, which receives the database,
    but is executed before the database is returned.
    
    :returns: the YapDatabase instance.
    */
    public static func databaseNamed(name: String, operations: DatabaseOperationsBlock? = .None) -> YapDatabase {
        let db =  YapDatabase(path: pathToDatabase(.DocumentDirectory, name: name, suffix: .None))
        operations?(db)
        return db
    }


    /**
    Conveniently create an empty database for testing purposes in the app's Caches directory.
    
    This function should only be used in unit tests, as it will delete any previously existing 
    SQLite file with the same path.
    
    It should only be used like this inside your test case.
    
        func test_MyUnitTest() {
            let db = YapDB.testDatabaseForFile(__FILE__, test: __FUNCTION__)
            // etc etc
        }
    
        func test_GivenInitialData_MyUnitTest(initialDataImport: YapDB.DatabaseOperationsBlock) {
            let db = YapDB.testDatabaseForFile(__FILE__, test: __FUNCTION__, operations: initialDataImport)
            // etc etc
        }
    
    :param: file a String, which should be the swift special macro __FILE__
    :param: test a String, which should be the swift special macro __FUNCTION__
    :param: operations a DatabaseOperationsBlock closure, which receives the database,
    but is executed before the database is returned. This is very useful if you want to 
    populate the database with some objects before running the test.
    
    :returns: the YapDatabase instance.
    */
    public static func testDatabaseForFile(file: String, test: String, operations: DatabaseOperationsBlock? = .None) -> YapDatabase {
        let path = pathToDatabase(.CachesDirectory, name: file.lastPathComponent, suffix: test.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "()")))
        assert(!path.isEmpty, "Path should not be empty.")
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        let db =  YapDatabase(path: path)
        operations?(db)
        return db
    }
}

extension YapDB {

    /**

    A database index value type.

    :param: collection A String
    :param: key A String
    */
    public struct Index {
        public let collection: String
        public let key: String

        public init(collection: String, key: String) {
            self.collection = collection
            self.key = key
        }
    }
}

// MARK: - Identifiable

/**
A generic protocol which is used to return a unique identifier
for the type. To use `String` type identifiers, use the aliased
Identifier type.
*/
public protocol Identifiable {
    typealias IdentifierType: Printable
    var identifier: IdentifierType { get }
}

/**
A typealias of String, which implements the Printable
protocol. When implementing the Identifiable protocol, use
Identifier for your String identifiers.

    extension Person: Identifiable {
      let identifier: Identifier
    }

*/
public typealias Identifier = String

extension Identifier: Printable {
    public var description: String { return self }
}

// MARK: - Persistable

/**
Types which implement Persistable can be used in the functions
defined in this framework. It assumes that all instances of a type
are stored in the same YapDatabase collection.
*/
public protocol Persistable: Identifiable {

    /// The YapDatabase collection name the type is stored in.
    static var collection: String { get }
}

/**
A simple function which generates a String key from a Persistable
instance. 

Note that it is preferable to use this exclusively to ensure
a consistent key structure.

:param: persistable A Persistable type instance
:returns: A String
*/
public func keyForPersistable<P: Persistable>(persistable: P) -> String {
    return "\(persistable.identifier)"
}

/**
A simple function which generates a YapDB.Index from a Persistable
instance. All write(_:) store objects in the database using this function.

:param: persistable A Persistable type instance
:returns: A YapDB.Index
*/
public func indexForPersistable<P: Persistable>(persistable: P) -> YapDB.Index {
    return YapDB.Index(collection: persistable.dynamicType.collection, key: keyForPersistable(persistable))
}

/**
A generic protocol which extends Persistable. It allows types to
expose their own metadata object type for use in YapDatabase. 
The object metadata must conform to NSCoding.
*/
public protocol ObjectMetadataPersistable: Persistable {
    typealias MetadataType: NSCoding

    /// The metadata object for this Persistable type.
    var metadata: MetadataType { get }
}

/**
A generic protocol which extends Persistable. It allows types to
expose their own metadata value type for use in YapDatabase.
The metadata value must conform to Saveable.
*/
public protocol ValueMetadataPersistable: Persistable {
    typealias MetadataType: Saveable

    /// The metadata value for this Persistable type.
    var metadata: MetadataType { get }
}

// MARK: - Archiver & Saveable

/**
A generic protocol which acts as an archiver for value types.
*/
public protocol Archiver: NSCoding {
    typealias ValueType

    /// The value type which is being encoded/decoded
    var value: ValueType { get }

    /// Required initializer receiving the wrapped value type.
    init(_: ValueType)
}

/**
A generic protocol which can be implemented to vends another
object capable of archiving the receiver.
*/
public protocol Saveable {
    typealias ArchiverType: Archiver

    /// The archive(r)
    var archive: ArchiverType { get }
}

/**
Extracts a value type from an archive, if possible. 

It accepts an
optional AnyObject argument, this makes suitable when implementing
initWithCoder(_: NSCoder)

   let barcode: Barcode? = valueFromArchive(aDecoder.decodeObjectForKey("barcode"))

:param: archive An optional AnyObject
:returns: an optional Value
*/
public func valueFromArchive<Value where Value: Saveable, Value.ArchiverType.ValueType == Value>(archive: AnyObject?) -> Value? {
    return archive.map { ($0 as! Value.ArchiverType).value }
}

/**
Extracts an array of Value types from a sequence of archives.

:param: archives An optional SequenceType of AnyObject
:returns: an optional array of Value instances
*/
public func valuesFromArchives<Archives, Value where Archives: SequenceType, Archives.Generator.Element == AnyObject, Value: Saveable, Value.ArchiverType.ValueType == Value>(archives: Archives?) -> [Value]? {
    return archives.map { map($0, valueFromArchive) }
}

/**
Creates an archive from an optional Value.

Again, primarily useful when implmementing encodeWithCoder(_: NSCoder)

    aCoder.encodeObject(archiveFromValue(value.address), forKey: "address")

:param: value An optional Value
:returns: An optional ArchiverType instance.
*/
public func archiveFromValue<Value where Value: Saveable, Value.ArchiverType.ValueType == Value>(value: Value?) -> Value.ArchiverType? {
    return value.map { $0.archive }
}

/**
Creates an array of archives from an optional sequence of Value instances.

:param: values An optional SequenceType of Value instances.
:returns: An optional Array of ArchiverType instance.
*/
public func archivesFromValues<Values, Value where Values: SequenceType, Values.Generator.Element == Value, Value: Saveable, Value.ArchiverType.ValueType == Value>(values: Values?) -> [Value.ArchiverType]? {
    return values.map { map($0, { archiveFromValue($0) }) }
}

internal func map<S: SequenceType, T>(source: S, transform: (S.Generator.Element) -> T?) -> [T] {
    return reduce(source, [T](), { (var accumulator, element) -> [T] in
        if let transformed = transform(element) {
            accumulator.append(transformed)
        }
        return accumulator
    })
}

internal func unique<S: SequenceType where S.Generator.Element: Hashable>(items: S) -> [S.Generator.Element] {
    let initial: [S.Generator.Element] = []
    return reduce(items, initial) { (var accumulator, item) -> [S.Generator.Element] in
        if !contains(accumulator, item) {
            accumulator.append(item)
        }
        return accumulator
    }
}

extension YapDatabaseConnection {

    /**
    Synchronously reads from the database on the connection. The closure receives
    the read transaction, and the function returns the result of the closure. This
    makes it very suitable as a building block for more functional methods.
    
    The majority of the wrapped functions provided by these extensions use this as 
    their basis.

    :param: block A closure which receives YapDatabaseReadTransaction and returns T
    :returns: An instance of T
    */
    public func read<T>(block: (YapDatabaseReadTransaction) -> T) -> T {
        var result: T! = .None
        readWithBlock { result = block($0) }
        return result
    }

    /**
    Synchronously writes to the database on the connection. The closure receives
    the read write transaction, and the function returns the result of the closure.
    This makes it very suitable as a building block for more functional methods.

    The majority of the wrapped functions provided by these extensions use this as
    their basis.

    :param: block A closure which receives YapDatabaseReadWriteTransaction and returns T
    :returns: An instance of T
    */
    public func write<T>(block: (YapDatabaseReadWriteTransaction) -> T) -> T {
        var result: T! = .None
        readWriteWithBlock { result = block($0) }
        return result
    }

    /**
    Asynchronously reads from the database on the connection. The closure receives
    the read transaction, and completion block receives the result of the closure.
    This makes it very suitable as a building block for more functional methods.

    The majority of the wrapped functions provided by these extensions use this as
    their basis.

    :param: block A closure which receives YapDatabaseReadTransaction and returns T
    :param: queue A dispatch_queue_t, defaults to main queue, can be ommitted in most cases.
    :param: completion A closure which receives T and returns Void.
    */
    public func asyncRead<T>(block: (YapDatabaseReadTransaction) -> T, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (T) -> Void) {
        var result: T! = .None
        asyncReadWithBlock({ result = block($0) }, completionQueue: queue) { completion(result) }
    }

    /**
    Asynchronously writes to the database on the connection. The closure receives
    the read write transaction, and completion block receives the result of the closure.
    This makes it very suitable as a building block for more functional methods.

    The majority of the wrapped functions provided by these extensions use this as
    their basis.

    :param: block A closure which receives YapDatabaseReadWriteTransaction and returns T
    :param: queue A dispatch_queue_t, defaults to main queue, can be ommitted in most cases.
    :param: completion A closure which receives T and returns Void.
    */
    public func asyncWrite<T>(block: (YapDatabaseReadWriteTransaction) -> T, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (T) -> Void) {
        var result: T! = .None
        asyncReadWriteWithBlock({ result = block($0) }, completionQueue: queue) { completion(result) }
    }
}


// MARK: Hashable etc

extension YapDB.Index: Printable, Hashable {

    public var description: String {
        return "\(collection):\(key)"
    }

    public var hashValue: Int {
        return description.hashValue
    }
}

public func == (a: YapDB.Index, b: YapDB.Index) -> Bool {
    return (a.collection == b.collection) && (a.key == b.key)
}



// MARK: Saveable

extension YapDB.Index: Saveable {
    public typealias Archiver = YapDBIndexArchiver

    public var archive: Archiver {
        return Archiver(self)
    }
}

// MARK: Archivers

public final class YapDBIndexArchiver: NSObject, NSCoding, Archiver {
    public let value: YapDB.Index

    public init(_ v: YapDB.Index) {
        value = v
    }


    public required init(coder aDecoder: NSCoder) {
        let collection = aDecoder.decodeObjectForKey("collection") as! String
        let key = aDecoder.decodeObjectForKey("key") as! String
        value = YapDB.Index(collection: collection, key: key)
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(value.collection, forKey: "collection")
        aCoder.encodeObject(value.key, forKey: "key")
    }
}

