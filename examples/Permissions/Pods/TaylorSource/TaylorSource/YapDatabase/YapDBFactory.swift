//
//  Created by Daniel Thorpe on 16/04/2015.
//

import YapDatabase

public protocol UpdatableView {
    typealias ProcessChangesType
    var processChanges: ProcessChangesType { get }
}

public struct YapDBCellIndex: IndexPathIndexType {
    public let indexPath: NSIndexPath
    public let transaction: YapDatabaseReadTransaction
    public let selected: Bool?

    public init(indexPath: NSIndexPath, transaction: YapDatabaseReadTransaction, selected: Bool? = .None) {
        self.indexPath = indexPath
        self.transaction = transaction
        self.selected = selected
    }
}

public struct YapDBSupplementaryIndex: IndexPathIndexType {
    public let group: String
    public let indexPath: NSIndexPath
    public let transaction: YapDatabaseReadTransaction

    public init(group: String, indexPath: NSIndexPath, transaction: YapDatabaseReadTransaction) {
        self.group = group
        self.indexPath = indexPath
        self.transaction = transaction
    }
}

public class YapDBFactory<
    Item, Cell, SupplementaryView, View
    where
    View: CellBasedView>: Factory<Item, Cell, SupplementaryView, View, YapDBCellIndex, YapDBSupplementaryIndex> {

    public override init(cell: GetCellKey? = .None, supplementary: GetSupplementaryKey? = .None) {
        super.init(cell: cell, supplementary: supplementary)
    }
}

// MARK: - UpdatableView

extension UITableView: UpdatableView {

    public var processChanges: YapDatabaseViewMappings.Changes {
        return { [weak self] changeset in
            if let weakSelf = self {
                if weakSelf.tay_shouldProcessChangeset(changeset) {
                    weakSelf.tay_performBatchUpdates {
                        weakSelf.tay_processSectionChanges(changeset.sections)
                        weakSelf.tay_processRowChanges(changeset.items)
                    }
                }
            }
        }
    }


    /**
    Consumers can override this to intercept whether or not the default change set processing
    should kick in. This is because in some scenarios it makes sense to prevent it. For example
    a common scenario is that a table view controller presents a "create new item" modal. When
    the save action occurs, the modal is dismissed, and the table view controller is reloaded, 
    and the changeset can subsequently occur. Running the changeset in this situation will 
    result in an exception. TaylorSource will suppress this exception, regardless, but still.. 
    */
    public func tay_shouldProcessChangeset(changeset: YapDatabaseViewMappings.Changeset) -> Bool {
        return true
    }

    public func tay_processSectionChanges(sectionChanges: [YapDatabaseViewSectionChange]) {
        for change in sectionChanges {
            let indexes = NSIndexSet(index: Int(change.index))
            switch change.type {
            case .Delete:
                deleteSections(indexes, withRowAnimation: .Automatic)
            case .Insert:
                insertSections(indexes, withRowAnimation: .Automatic)
            default:
                break
            }
        }
    }

    public func tay_processRowChanges(rowChanges: [YapDatabaseViewRowChange]) {
        for change in rowChanges {
            switch change.type {
            case .Delete:
                deleteRowsAtIndexPaths([change.indexPath], withRowAnimation: .Automatic)
            case .Insert:
                insertRowsAtIndexPaths([change.newIndexPath], withRowAnimation: .Automatic)
            case .Move:
                deleteRowsAtIndexPaths([change.indexPath], withRowAnimation: .Automatic)
                insertRowsAtIndexPaths([change.newIndexPath], withRowAnimation: .Automatic)
            case .Update:
                reloadRowsAtIndexPaths([change.indexPath], withRowAnimation: .Automatic)
            }
        }
    }
}

extension UICollectionView: UpdatableView {

    public var processChanges: YapDatabaseViewMappings.Changes {
        return { [weak self] changeset in
            if let weakSelf = self {
                weakSelf.performBatchUpdates({
                    weakSelf.processSectionChanges(changeset.sections)
                    weakSelf.processItemChanges(changeset.items)
                }, completion: nil)
            }
        }
    }

    func processSectionChanges(sectionChanges: [YapDatabaseViewSectionChange]) {
        for change in sectionChanges {
            let indexes = NSIndexSet(index: Int(change.index))
            switch change.type {
            case .Delete:
                deleteSections(indexes)
            case .Insert:
                insertSections(indexes)
            default:
                break
            }
        }
    }

    func processItemChanges(itemChanges: [YapDatabaseViewRowChange]) {
        for change in itemChanges {
            switch change.type {
            case .Delete:
                deleteItemsAtIndexPaths([change.indexPath])
            case .Insert:
                insertItemsAtIndexPaths([change.newIndexPath])
            case .Move:
                deleteItemsAtIndexPaths([change.indexPath])
                insertItemsAtIndexPaths([change.newIndexPath])
            case .Update:
                reloadItemsAtIndexPaths([change.indexPath])
            }
        }
    }
}

