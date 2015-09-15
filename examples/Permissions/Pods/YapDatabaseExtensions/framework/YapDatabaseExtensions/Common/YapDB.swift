//
//  Created by Daniel Thorpe on 22/04/2015.
//

import YapDatabase

protocol YapDatabaseViewProducer {
    func createDatabaseView() -> YapDatabaseView
}

protocol YapDatabaseViewRegistrar {
    func isRegisteredInDatabase(database: YapDatabase) -> Bool
    func registerInDatabase(database: YapDatabase, withConnection: YapDatabaseConnection?)
}

extension YapDB {

    /**
    A Swift enum wraps YapDatabaseView wrappers. It can be thought of being a Fetch
    Request type, as it defines what will be fetched out of the database. The Fetch
    instance should be used by injecting it into a FetchConfiguration.
    */
    public enum Fetch: YapDatabaseViewRegistrar {

        case View(YapDB.View)
        case Filter(YapDB.Filter)
        case Search(YapDB.Search)

        public var name: String {
            switch self {
            case let .View(view):       return view.name
            case let .Filter(filter):   return filter.name
            case let .Search(search):   return search.name
            }
        }

        var registrar: YapDatabaseViewRegistrar {
            switch self {
            case let .View(view):       return view
            case let .Filter(filter):   return filter
            case let .Search(search):   return search
            }
        }

        /**
        Utility function which can check if the extension is already registed in YapDatabase.
        
        :param: database A YapDatabase instance
        :returns: A Bool
        */
        public func isRegisteredInDatabase(database: YapDatabase) -> Bool {
            return registrar.isRegisteredInDatabase(database)
        }

        /**
        Utility function can register the extensions in YapDatabase, optionally using the supplied connection.

        :param: database A YapDatabase instance
        :param: connection An optiona YapDatabaseConnection, defaults to .None
        */
        public func registerInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) {
            registrar.registerInDatabase(database, withConnection: connection)
        }

        /**
        Creates the YapDatabaseViewMappings object. Ensures that any database extensions are registered before returning.

        :param: database A YapDatabase instance
        :param: connection An optiona YapDatabaseConnection, defaults to .None
        */
        public func createViewMappings(mappings: Mappings, inDatabase database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) -> YapDatabaseViewMappings {
            registerInDatabase(database, withConnection: connection)
            return YapDatabaseViewMappings(groupFilterBlock: mappings.filter, sortBlock: mappings.sort, view: name)
        }
    }
}

extension YapDB {

    /**
    The base class for other YapDatabaseView wrapper types.
    */
    public class BaseView {
        let name: String
        let version: String
        let collections: Set<String>?
        let persistent: Bool

        var options: YapDatabaseViewOptions {
            get {
                let options = YapDatabaseViewOptions()
                options.isPersistent = persistent
                options.allowedCollections = collections.map { YapWhitelistBlacklist(whitelist: $0) }
                return options
            }
        }

        init(name n: String, version v: String = "1.0", persistent p: Bool = true, collections c: [String]? = .None) {
            name = n
            version = v
            persistent = p
            collections = c.map { Set($0) }
        }

        /**
        Utility function which can check if the extension is already registed in YapDatabase.

        :param: database A YapDatabase instance
        :returns: A Bool
        */
        public func isRegisteredInDatabase(database: YapDatabase) -> Bool {
            return (database.registeredExtension(name) as? YapDatabaseView) != .None
        }
    }
}

extension YapDB {

    /**
    A wrapper around YapDatabaseView. It can be constructed with a name, which is
    the name the extension is registered under, a grouping enum type and a sorting enum type.
    */
    public class View: BaseView, YapDatabaseViewProducer, YapDatabaseViewRegistrar {

        /**
        An enum to make creating YapDatabaseViewGrouping easier. E.g.
        
            let grouping: YapDB.View.Grouping = .ByKey({ (collection, key) -> String! in
                // return a group or nil to exclude from the view.
            })

        */
        public enum Grouping {
            case ByKey(YapDatabaseViewGroupingWithKeyBlock)
            case ByObject(YapDatabaseViewGroupingWithObjectBlock)
            case ByMetadata(YapDatabaseViewGroupingWithMetadataBlock)
            case ByRow(YapDatabaseViewGroupingWithRowBlock)

            var object: YapDatabaseViewGrouping {
                switch self {
                case let .ByKey(block):         return YapDatabaseViewGrouping.withKeyBlock(block)
                case let .ByObject(block):      return YapDatabaseViewGrouping.withObjectBlock(block)
                case let .ByMetadata(block):    return YapDatabaseViewGrouping.withMetadataBlock(block)
                case let .ByRow(block):         return YapDatabaseViewGrouping.withRowBlock(block)
                }
            }
        }

        /**
        An enum to make creating YapDatabaseViewSorting easier.
        */
        public enum Sorting {
            case ByKey(YapDatabaseViewSortingWithKeyBlock)
            case ByObject(YapDatabaseViewSortingWithObjectBlock)
            case ByMetadata(YapDatabaseViewSortingWithMetadataBlock)
            case ByRow(YapDatabaseViewSortingWithRowBlock)

            var object: YapDatabaseViewSorting {
                switch self {
                case let .ByKey(block):         return YapDatabaseViewSorting.withKeyBlock(block)
                case let .ByObject(block):      return YapDatabaseViewSorting.withObjectBlock(block)
                case let .ByMetadata(block):    return YapDatabaseViewSorting.withMetadataBlock(block)
                case let .ByRow(block):         return YapDatabaseViewSorting.withRowBlock(block)
                }
            }
        }

        let grouping: Grouping
        let sorting: Sorting

        /**
        Initializer for a View. 
        
        :param: name A String, the name of the extension
        :param: grouping A Grouping instance - how should the view group the database items?
        :param: sorting A Sorting instance - inside each group, how should the view sort the items?
        :param: version A String, defaults to "1.0"
        :param: persistent A Bool, defaults to true - meaning that the contents of the view will be stored in YapDatabase between launches.
        :param: collections An optional array of collections which is used to white list the collections searched when populating the view.
        */
        public init(name: String, grouping g: Grouping, sorting s: Sorting, version: String = "1.0", persistent: Bool = true, collections: [String]? = .None) {
            grouping = g
            sorting = s
            super.init(name: name, version: version, persistent: persistent, collections: collections)
        }

        func createDatabaseView() -> YapDatabaseView {
            return YapDatabaseView(grouping: grouping.object, sorting: sorting.object, versionTag: version, options: options)
        }

        func registerInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) {
            if !isRegisteredInDatabase(database) {
                if let connection = connection {
                    database.registerExtension(createDatabaseView(), withName: name, connection: connection)
                }
                else {
                    database.registerExtension(createDatabaseView(), withName: name)
                }
            }
        }
    }
}

extension YapDB {

    /**
    A wrapper around YapDatabaseFilteredView. 
    
    A FilteredView is a view extension which consists of
    a parent view extension and a filtering block. In this case, the parent
    is a YapDB.Fetch type. This allows for filtering of other filters, and 
    even filtering of search results.
    */
    public class Filter: BaseView, YapDatabaseViewProducer, YapDatabaseViewRegistrar {

        /**
        An enum to make creating YapDatabaseViewFiltering easier.
        */
        public enum Filtering {
            case ByKey(YapDatabaseViewFilteringWithKeyBlock)
            case ByObject(YapDatabaseViewFilteringWithObjectBlock)
            case ByMetadata(YapDatabaseViewFilteringWithMetadataBlock)
            case ByRow(YapDatabaseViewFilteringWithRowBlock)

            var object: YapDatabaseViewFiltering {
                switch self {
                case let .ByKey(block):         return YapDatabaseViewFiltering.withKeyBlock(block)
                case let .ByObject(block):      return YapDatabaseViewFiltering.withObjectBlock(block)
                case let .ByMetadata(block):    return YapDatabaseViewFiltering.withMetadataBlock(block)
                case let .ByRow(block):         return YapDatabaseViewFiltering.withRowBlock(block)
                }
            }
        }

        let parent: YapDB.Fetch
        let filtering: Filtering

        /**
        Initializer for a Filter
        
        :param: name A String, the name of the extension
        :param: parent A YapDB.Fetch instance, the parent extensions which will be filtered.
        :param: filtering A Filtering, simple filtering of each item in the parent view.
        :param: version A String, defaults to "1.0"
        :param: persistent A Bool, defaults to true - meaning that the contents of the view will be stored in YapDatabase between launches.
        :param: collections An optional array of collections which is used to white list the collections searched when populating the view.
        */
        public init(name: String, parent p: YapDB.Fetch, filtering f: Filtering, version: String = "1.0", persistent: Bool = true, collections: [String]? = .None) {
            parent = p
            filtering = f
            super.init(name: name, version: version, persistent: persistent, collections: collections)
        }

        func createDatabaseView() -> YapDatabaseView {
            return YapDatabaseFilteredView(parentViewName: parent.name, filtering: filtering.object, versionTag: version, options: options)
        }

        func registerInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) {
            if !isRegisteredInDatabase(database) {
                parent.registerInDatabase(database, withConnection: connection)
                if let connection = connection {
                    database.registerExtension(createDatabaseView(), withName: name, connection: connection)
                }
                else {
                    database.registerExtension(createDatabaseView(), withName: name)
                }
            }
        }
    }
}

extension YapDB {

    /**
    A wrapper around YapDatabaseFullTextSearch. 
    
    A YapDatabaseFullTextSearch is a view extension which consists of
    a parent view extension, column names to query and a search handler.
    In this case, the parent is a YapDB.Fetch type. This
    allows for searching of other filters, and even searching inside search results.
    */
    public class Search: BaseView, YapDatabaseViewProducer, YapDatabaseViewRegistrar {

        /**
        An enum to make creating YapDatabaseFullTextSearchHandler easier.
        */
        public enum Handler {
            case ByKey(YapDatabaseFullTextSearchWithKeyBlock)
            case ByObject(YapDatabaseFullTextSearchWithObjectBlock)
            case ByMetadata(YapDatabaseFullTextSearchWithMetadataBlock)
            case ByRow(YapDatabaseFullTextSearchWithRowBlock)

            public var object: YapDatabaseFullTextSearchHandler {
                switch self {
                case let .ByKey(block):         return YapDatabaseFullTextSearchHandler.withKeyBlock(block)
                case let .ByObject(block):      return YapDatabaseFullTextSearchHandler.withObjectBlock(block)
                case let .ByMetadata(block):    return YapDatabaseFullTextSearchHandler.withMetadataBlock(block)
                case let .ByRow(block):         return YapDatabaseFullTextSearchHandler.withRowBlock(block)
                }
            }
        }

        let parent: YapDB.Fetch
        let searchName: String
        let columnNames: [String]
        let handler: Handler

        /**
        Initializer for a Search

        :param: name A String, the name of the search results view extension
        :param: parent A YapDB.Fetch instance, the parent extensions which will be filtered.
        :param: search A String, this is the name of full text search handler extension
        :param: columnNames An array of String instances, the column names are the dictionary keys used by the handler.
        :param: handler A Handler instance.
        :param: version A String, defaults to "1.0"
        :param: persistent A Bool, defaults to true - meaning that the contents of the view will be stored in YapDatabase between launches.
        :param: collections An optional array of collections which is used to white list the collections searched when populating the view.
        */
        public init(name: String, parent p: YapDB.Fetch, search: String, columnNames cn: [String], handler h: Handler, version: String = "1.0", persistent: Bool = true, collections: [String]? = .None) {
            parent = p
            searchName = search
            columnNames = cn
            handler = h
            super.init(name: name, version: version, persistent: persistent, collections: collections)
        }

        func createDatabaseView() -> YapDatabaseView {
            return YapDatabaseSearchResultsView(fullTextSearchName: searchName, parentViewName: parent.name, versionTag: version, options: .None)
        }

        func registerInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) {

            if (database.registeredExtension(searchName) as? YapDatabaseFullTextSearch) == .None {
                let fullTextSearch = YapDatabaseFullTextSearch(columnNames: columnNames, handler: handler.object, versionTag: version)
                if let connection = connection {
                    database.registerExtension(fullTextSearch, withName: searchName, connection: connection)
                }
                else {
                    database.registerExtension(fullTextSearch, withName: searchName)
                }
            }

            if !isRegisteredInDatabase(database) {
                parent.registerInDatabase(database, withConnection: connection)
                if let connection = connection {
                    database.registerExtension(createDatabaseView(), withName: name, connection: connection)
                }
                else {
                    database.registerExtension(createDatabaseView(), withName: name)
                }
            }
        }
    }
}

extension YapDB {

    public struct Mappings {

        static var passThroughFilter: YapDatabaseViewMappingGroupFilter {
            return { (_, _) in true }
        }

        static var caseInsensitiveGroupSort: YapDatabaseViewMappingGroupSort {
            return { (group1, group2, _) in group1.caseInsensitiveCompare(group2) }
        }

        let filter: YapDatabaseViewMappingGroupFilter
        let sort: YapDatabaseViewMappingGroupSort

        public init(filter f: YapDatabaseViewMappingGroupFilter = Mappings.passThroughFilter, sort s: YapDatabaseViewMappingGroupSort = Mappings.caseInsensitiveGroupSort) {
            filter = f
            sort = s
        }
    }
}

extension YapDB {

    public struct FetchConfiguration {

        public typealias MappingsConfigurationBlock = (YapDatabaseViewMappings) -> Void

        let fetch: Fetch
        let mappings: Mappings
        let block: MappingsConfigurationBlock?

        public var name: String {
            return fetch.name
        }

        public init(fetch f: Fetch, mappings m: Mappings = Mappings(), block b: MappingsConfigurationBlock? = .None) {
            fetch = f
            mappings = m
            block = b
        }

        public init(view: YapDB.View) {
            self.init(fetch: .View(view))
        }

        public init(filter: YapDB.Filter) {
            self.init(fetch: .Filter(filter))
        }

        public init(search: YapDB.Search) {
            self.init(fetch: .Search(search))
        }

        public func createMappingsRegisteredInDatabase(database: YapDatabase, withConnection connection: YapDatabaseConnection? = .None) -> YapDatabaseViewMappings {
            let databaseViewMappings = fetch.createViewMappings(mappings, inDatabase: database, withConnection: connection)
            block?(databaseViewMappings)
            return databaseViewMappings
        }
    }
}




