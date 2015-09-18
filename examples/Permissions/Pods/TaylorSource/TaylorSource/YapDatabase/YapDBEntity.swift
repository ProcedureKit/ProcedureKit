//
//  YapDBEntity.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 30/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import YapDatabase
import YapDatabaseExtensions

public struct YapDBEntityDatasource<
    Factory, Entity
    where
    Entity: EntityType,
    Entity: Persistable,
    Factory: _FactoryType,
    Entity.ItemType == Factory.ItemType,
    Factory.CellIndexType == YapDBCellIndex,
    Factory.SupplementaryIndexType == YapDBSupplementaryIndex>: DatasourceType {

    public typealias FactoryType = Factory

    public let factory: Factory
    public let identifier: String
    public var title: String? = .None
    public private(set) var entity: Entity

    public var readOnlyConnection: YapDatabaseConnection {
        return observer.readOnlyConnection
    }

    private let observer: Observer<Entity>

    var configuration: Configuration<Entity> {
        return observer.configuration
    }

    var mappings: YapDatabaseViewMappings {
        return observer.mappings
    }

    public init(id: String, database: YapDatabase, factory f: Factory, entity e: Entity, entityDidChange didChange: dispatch_block_t, itemMapper: Configuration<Entity>.DataItemMapper) {

        identifier = id
        factory = f
        entity = e

        let index = indexForPersistable(e)
        let view: YapDB.View = {

            let grouping = YapDB.View.Grouping.ByKey({ (_, collection, key) -> String! in
                if collection == index.collection && key == index.key {
                    return collection
                }
                return nil
            })

            let sorting = YapDB.View.Sorting.ByKey({ (_, _, _, _, _, _) -> NSComparisonResult in
                return .OrderedSame
            })

            let view = YapDB.View(
                name: "Fetch Entity for \(id)",
                grouping: grouping,
                sorting: sorting,
                collections: [index.collection])
            
            return view
        }()

        let configuration: Configuration<Entity> = {
            let fetchConfig = YapDB.FetchConfiguration(view: view)
            return Configuration(fetch: fetchConfig, itemMapper: itemMapper)
        }()

        observer = Observer(database: database, changes: { _ in didChange() }, configuration: configuration)
    }

    // Datasource

    public var numberOfSections: Int {
        return entity.numberOfSections
    }

    public func numberOfItemsInSection(sectionIndex: Int) -> Int {
        return entity.numberOfItemsInSection(sectionIndex)
    }

    public func itemAtIndexPath(indexPath: NSIndexPath) -> Factory.ItemType? {
        return entity.itemAtIndexPath(indexPath)
    }


    public func cellForItemInView(view: Factory.ViewType, atIndexPath indexPath: NSIndexPath) -> Factory.CellType {
        return readOnlyConnection.read { transaction in
            if let item = self.itemAtIndexPath(indexPath) {
                let index = YapDBCellIndex(indexPath: indexPath, transaction: transaction)
                return self.factory.cellForItem(item, inView: view, atIndex: index)
            }
            fatalError("No item available at index path: \(indexPath)")
        }
    }

    public func viewForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.SupplementaryViewType? {
        return readOnlyConnection.read { transaction in
            let index = YapDBSupplementaryIndex(group: "", indexPath: indexPath, transaction: transaction)
            return self.factory.supplementaryViewForKind(kind, inView: view, atIndex: index)
        }
    }

    public func textForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.TextType? {
        return readOnlyConnection.read { transaction in
            let index = YapDBSupplementaryIndex(group: "", indexPath: indexPath, transaction: transaction)
            return self.factory.supplementaryTextForKind(kind, atIndex: index)
        }
    }
}


