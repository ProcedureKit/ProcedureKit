//
//  Created by Daniel Thorpe on 20/04/2015.
//

import UIKit
import YapDatabase
import YapDatabaseExtensions

public struct YapDBDatasource<
    Factory
    where
    Factory: _FactoryType,
    Factory.CellIndexType == YapDBCellIndex,
    Factory.SupplementaryIndexType == YapDBSupplementaryIndex>: DatasourceType, SequenceType, CollectionType {

    typealias FactoryType = Factory

    public let identifier: String
    public let factory: Factory
    public var title: String? = .None

    private let observer: Observer<Factory.ItemType>

    var mappings: YapDatabaseViewMappings {
        return observer.mappings
    }

    public var readOnlyConnection: YapDatabaseConnection {
        return observer.readOnlyConnection
    }

    var configuration: Configuration<Factory.ItemType> {
        return observer.configuration
    }

    public init(id: String, database: YapDatabase, factory f: Factory, processChanges changes: YapDatabaseViewMappings.Changes, configuration: Configuration<Factory.ItemType>) {
        identifier = id
        factory = f
        observer = Observer(database: database, changes: changes, configuration: configuration)
    }

    public var numberOfSections: Int {
        return Int(mappings.numberOfSections())
    }

    public func numberOfItemsInSection(sectionIndex: Int) -> Int {
        return Int(mappings.numberOfItemsInSection(UInt(sectionIndex)))
    }

    public func itemAtIndexPath(indexPath: NSIndexPath) -> Factory.ItemType? {
        return observer.itemAtIndexPath(indexPath)
    }

    public func cellForItemInView(view: Factory.ViewType, atIndexPath indexPath: NSIndexPath) -> Factory.CellType {
        return readOnlyConnection.read { transaction in
            if let item = self.observer.itemAtIndexPath(indexPath, inTransaction: transaction) {
                let index = YapDBCellIndex(indexPath: indexPath, transaction: transaction)
                return self.factory.cellForItem(item, inView: view, atIndex: index)
            }
            fatalError("No item available at index path: \(indexPath)")
        }
    }

    public func viewForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.SupplementaryViewType? {

        let group = mappings.groupForSection(UInt(indexPath.section))
        return readOnlyConnection.read { transaction in
            let index = YapDBSupplementaryIndex(group: group, indexPath: indexPath, transaction: transaction)
            return self.factory.supplementaryViewForKind(kind, inView: view, atIndex: index)
        }
    }

    /**
    Will return an optional text for the supplementary kind

    :param: view the View which should dequeue the cell.
    :param: kind the kind of the supplementary element. See SupplementaryElementKind
    :param: indexPath the NSIndexPath of the item.
    :return: a TextType?
    */
    public func textForSupplementaryElementInView(view: Factory.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> Factory.TextType? {
        let group = mappings.groupForSection(UInt(indexPath.section))
        return readOnlyConnection.read { transaction in
            let index = YapDBSupplementaryIndex(group: group, indexPath: indexPath, transaction: transaction)
            return self.factory.supplementaryTextForKind(kind, atIndex: index)
        }
    }

    // SequenceType

    public func generate() -> AnyGenerator<Factory.ItemType> {
        return observer.generate()
    }

    // CollectionType

    public var startIndex: Int {
        return observer.startIndex
    }

    public var endIndex: Int {
        return observer.endIndex
    }

    public subscript(i: Int) -> Factory.ItemType {
        return observer.mapper[i]
    }
}

