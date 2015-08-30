//
//  Created by Daniel Thorpe on 16/04/2015.
//

import UIKit

/**
The core protocol of Datasource functionality.

It has an associated type, _FactoryType which in turn is responsible for
associates types for item model, cell class, supplementary view classes, 
parent view class and index types.

The factory provides an API to register cells and views, and in
turn it can be used to vend cells and view.

Types which implement DatasourceType (this protocol) should use the
factory in conjuction with a storage medium for data items.

This protocol exists to allow for the definition of different kinds of
datasources. Coupled with DatasourceProviderType, datasources can be
composed and extended with ease. See SegmentedDatasource for example.
*/
public protocol DatasourceType {
    typealias FactoryType: _FactoryType

    /// Access the factory from the datasource, likely should be a stored property.
    var factory: FactoryType { get }

    /// An identifier which is primarily to ease debugging and logging.
    var identifier: String { get }

    /// Optional human readable title
    var title: String? { get }

    /// The number of sections in the data source
    var numberOfSections: Int { get }

    /**
    The number of items in the section.

    :param: section The section index
    :returns: An Int, the number of items.
    */
    func numberOfItemsInSection(sectionIndex: Int) -> Int

    /**
    Access the underlying data item at the indexPath.
    
    :param: indexPath A NSIndexPath instance.
    :returns: An optional Item
    */
    func itemAtIndexPath(indexPath: NSIndexPath) -> FactoryType.ItemType?

    /**
    Vends a configured cell for the item.
    
    :param: view the View which should dequeue the cell.
    :param: indexPath the NSIndexPath of the item.
    :return: a FactoryType.CellType instance, this should be dequeued and configured.
    */
    func cellForItemInView(view: FactoryType.ViewType, atIndexPath indexPath: NSIndexPath) -> FactoryType.CellType

    /**
    Vends a configured supplementary view of kind.

    :param: view the View which should dequeue the cell.
    :param: kind the kind of the supplementary element. See SupplementaryElementKind
    :param: indexPath the NSIndexPath of the item.
    :return: a Factory.Type.SupplementaryViewType instance, this should be dequeued and configured.
    */
    func viewForSupplementaryElementInView(view: FactoryType.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> FactoryType.SupplementaryViewType?

    /**
    Vends a optional text for the supplementary kind
    
    :param: view the View which should dequeue the cell.
    :param: kind the kind of the supplementary element. See SupplementaryElementKind
    :param: indexPath the NSIndexPath of the item.
    :return: a TextType?
    */
    func textForSupplementaryElementInView(view: FactoryType.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> FactoryType.TextType?
}

public enum EditableDatasourceAction: Int {
    case None = 1, Insert, Delete

    public var editingStyle: UITableViewCellEditingStyle {
        switch self {
        case .None: return .None
        case .Insert: return .Insert
        case .Delete: return .Delete
        }
    }

    public init?(editingStyle: UITableViewCellEditingStyle) {
        switch editingStyle {
        case .None:
            self = .None
        case .Insert:
            self = .Insert
        case .Delete:
            self = .Delete
        }
    }
}

public typealias CanEditItemAtIndexPath = (indexPath: NSIndexPath) -> Bool
public typealias CommitEditActionForItemAtIndexPath = (action: EditableDatasourceAction, indexPath: NSIndexPath) -> Void
public typealias EditActionForItemAtIndexPath = (indexPath: NSIndexPath) -> EditableDatasourceAction
public typealias CanMoveItemAtIndexPath = (indexPath: NSIndexPath) -> Bool
public typealias CommitMoveItemAtIndexPathToIndexPath = (from: NSIndexPath, to: NSIndexPath) -> Void

public protocol DatasourceEditorType {

    var canEditItemAtIndexPath: CanEditItemAtIndexPath? { get }
    var commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? { get }
    var editActionForItemAtIndexPath: EditActionForItemAtIndexPath? { get }
    var canMoveItemAtIndexPath: CanMoveItemAtIndexPath? { get }
    var commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? { get }
}

/**
Suggested usage is not to use a DatasourceType directly, but instead to create
a bespoke type which implements this protocol, DatasourceProviderType, and vend
a configured datasource. This type could be considered to be like a view model
in MVVM paradigms. But in traditional MVC, such a type is just a model, which 
the view controller initalizes and owns.
*/
public protocol DatasourceProviderType {

    typealias Datasource: DatasourceType
    typealias Editor: DatasourceEditorType

    /// The underlying Datasource.
    var datasource: Datasource { get }

    /// An optional datasource editor
    var editor: Editor { get }
}

public struct NoEditor: DatasourceEditorType {
    public let canEditItemAtIndexPath: CanEditItemAtIndexPath? = .None
    public let commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? = .None
    public let editActionForItemAtIndexPath: EditActionForItemAtIndexPath? = .None
    public let canMoveItemAtIndexPath: CanMoveItemAtIndexPath? = .None
    public let commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? = .None
    public init() {}
}

public struct Editor: DatasourceEditorType {

    public let canEditItemAtIndexPath: CanEditItemAtIndexPath?
    public let commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath?
    public let editActionForItemAtIndexPath: EditActionForItemAtIndexPath?
    public let canMoveItemAtIndexPath: CanMoveItemAtIndexPath?
    public let commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath?

    public init(
        canEdit: CanEditItemAtIndexPath? = .None,
        commitEdit: CommitEditActionForItemAtIndexPath? = .None,
        editAction: EditActionForItemAtIndexPath? = .None,
        canMove: CanMoveItemAtIndexPath? = .None,
        commitMove: CommitMoveItemAtIndexPathToIndexPath? = .None) {
            canEditItemAtIndexPath = canEdit
            commitEditActionForItemAtIndexPath = commitEdit
            editActionForItemAtIndexPath = editAction
            canMoveItemAtIndexPath = canMove
            commitMoveItemAtIndexPathToIndexPath = commitMove
    }
}

public struct ComposedEditor: DatasourceEditorType {

    public let canEditItemAtIndexPath: CanEditItemAtIndexPath?
    public let commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath?
    public let editActionForItemAtIndexPath: EditActionForItemAtIndexPath?
    public let canMoveItemAtIndexPath: CanMoveItemAtIndexPath?
    public let commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath?

    public init(editor: DatasourceEditorType) {
        canEditItemAtIndexPath = editor.canEditItemAtIndexPath
        commitEditActionForItemAtIndexPath = editor.commitEditActionForItemAtIndexPath
        editActionForItemAtIndexPath = editor.editActionForItemAtIndexPath
        canMoveItemAtIndexPath = editor.canMoveItemAtIndexPath
        commitMoveItemAtIndexPathToIndexPath = editor.commitMoveItemAtIndexPathToIndexPath
    }
}




