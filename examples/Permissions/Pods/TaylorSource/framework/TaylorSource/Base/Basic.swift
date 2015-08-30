//
//  Basic.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 29/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
Simple wrapper for a Datasource. TaylorSource is designed for composing Datasources
inside custom classes, referred to as *datasource providers*. There are Table View
and Collection View data source generators which accept datasource providers.

Therefore, if you absolutely don't want your own custom class to act as the datasource
provider, this structure is available to easily wrap any DatasourceType. e.g.

let datasource: UITableViewDataSourceProvider<BasicDatasourceProvider<StaticDatasource>>
tableView.dataSource = datasource.tableViewDataSource
*/
public struct BasicDatasourceProvider<Datasource: DatasourceType>: DatasourceProviderType {

    /// The wrapped Datasource
    public let datasource: Datasource

    public let editor = NoEditor()

    init(_ d: Datasource) {
        datasource = d
    }
}

/**
A concrete implementation of DatasourceType for simple immutable arrays of objects.
The static datasource is initalized with the model items to display. They all
are in the same section.

The cell and supplementary index types are both NSIndexPath, which means using a
BasicFactory. This means that the configure block for cells and supplementary views
will receive an NSIndexPath as their index argument.
*/
public final class StaticDatasource<
    Factory
    where
    Factory: _FactoryType,
    Factory.CellIndexType == NSIndexPath,
    Factory.SupplementaryIndexType == NSIndexPath>: DatasourceType, SequenceType, CollectionType {

    typealias FactoryType = Factory

    public let identifier: String
    public let factory: Factory
    public var title: String? = .None
    private var items: [Factory.ItemType]

    /**
    The initializer.

    :param: id a String identifier
    :factory: a Factory whose CellIndexType and SupplementaryIndexType must be NSIndexPath, such as BasicFactory.
    :items: an array of Factory.ItemType instances.
    */
    public init(id: String, factory f: Factory, items i: [Factory.ItemType]) {
        identifier = id
        factory = f
        items = i
    }

    /// The number of section, always 1 for a static datasource
    public var numberOfSections: Int {
        return 1
    }

    /// The number of items in a section, always the item count for a static datasource
    public func numberOfItemsInSection(sectionIndex: Int) -> Int {
        return items.count
    }

    /**
    The item at an indexPath. Will ignore the section property of the NSIndexPath.
    Will also return .None if the indexPath item index is out of bounds of the
    array of items.

    :param: indexPath an NSIndexPath
    :returns: an optional Factory.ItemType
    */
    public func itemAtIndexPath(indexPath: NSIndexPath) -> Factory.ItemType? {
        if items.startIndex <= indexPath.item && indexPath.item < items.endIndex {
            return items[indexPath.item]
        }
        return .None
    }

    /**
    Will return a cell.

    The cell is configured with the item at the index path first.
    Note, that the itemAtIndexPath method will gracefully return a .None if the
    indexPath is out of range. Here, we fatalError which will deliberately crash the
    app.

    :param: view the view instance.
    :param: indexPath an NSIndexPath
    :returns: an dequeued and configured Factory.CellType
    */
    public func cellForItemInView(view: Factory.ViewType, atIndexPath indexPath: NSIndexPath) -> Factory.CellType {
        if let item = itemAtIndexPath(indexPath) {
            return factory.cellForItem(item, inView: view, atIndex: indexPath)
        }
        fatalError("No item available at index path: \(indexPath)")
    }

    /**
    Will return a supplementary view.
    This is the result of running any registered closure from the factory
    for this supplementary element kind.

    :param: view the view instance.
    :param: kind the SupplementaryElementKind of the supplementary view.
    :returns: an dequeued and configured Factory.SupplementaryViewType
    */
    public func viewForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.SupplementaryViewType? {
        return factory.supplementaryViewForKind(kind, inView: view, atIndex: indexPath)
    }

    /**
    Will return an optional text for the supplementary kind

    :param: view the View which should dequeue the cell.
    :param: kind the kind of the supplementary element. See SupplementaryElementKind
    :param: indexPath the NSIndexPath of the item.
    :return: a TextType?
    */
    public func textForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.TextType? {
        return factory.supplementaryTextForKind(kind, atIndex: indexPath)
    }

    // SequenceType

    public func generate() -> Array<Factory.ItemType>.Generator {
        return items.generate()
    }

    // CollectionType

    public var startIndex: Int {
        return items.startIndex
    }

    public var endIndex: Int {
        return items.endIndex
    }

    public subscript(i: Int) -> Factory.ItemType {
        return items[i]
    }
}

