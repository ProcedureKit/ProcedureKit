//
//  Entity.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 29/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public protocol EntityType {
    typealias ItemType

    var numberOfSections: Int { get }

    func numberOfItemsInSection(sectionIndex: Int) -> Int

    func itemAtIndexPath(indexPath: NSIndexPath) -> ItemType?
}

public struct EntityDatasource<
    Factory, Entity
    where
    Entity: EntityType,
    Factory: _FactoryType,
    Entity.ItemType == Factory.ItemType,
    Factory.CellIndexType == NSIndexPath,
    Factory.SupplementaryIndexType == NSIndexPath>: DatasourceType {

    public typealias FactoryType = Factory

    public let factory: Factory
    public let identifier: String
    public var title: String? = .None
    public private(set) var entity: Entity

    public init(id: String, factory f: Factory, entity e: Entity) {
        identifier = id
        factory = f
        entity = e
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
        if let item = itemAtIndexPath(indexPath) {
            return factory.cellForItem(item, inView: view, atIndex: indexPath)
        }
        fatalError("No item available at index path: \(indexPath)")
    }

    public func viewForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.SupplementaryViewType? {
        return factory.supplementaryViewForKind(kind, inView: view, atIndex: indexPath)
    }

    public func textForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.TextType? {
        return factory.supplementaryTextForKind(kind, atIndex: indexPath)
    }
}


