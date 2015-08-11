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


/**
Suggested usage is not to use a DatasourceType directly, but instead to create
a bespoke type which implements this protocol, DatasourceProviderType, and vend
a configured datasource. This type could be considered to be like a view model
in MVVM paradigms. But in traditional MVC, such a type is just a model, which 
the view controller initalizes and owns.
*/
public protocol DatasourceProviderType {

    typealias Datasource: DatasourceType

    /// The underlying Datasource.
    var datasource: Datasource { get }

    var canEditItemAtIndexPath: CanEditItemAtIndexPath? { get }
    var commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? { get }
    var editActionForItemAtIndexPath: EditActionForItemAtIndexPath? { get }
    var canMoveItemAtIndexPath: CanMoveItemAtIndexPath? { get }
    var commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? { get }
}

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

    public let canEditItemAtIndexPath: CanEditItemAtIndexPath? = .None
    public let commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? = .None
    public let editActionForItemAtIndexPath: EditActionForItemAtIndexPath? = .None
    public let canMoveItemAtIndexPath: CanMoveItemAtIndexPath? = .None
    public let commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? = .None

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



struct SegmentedDatasourceState {
    var selectedIndex: Int = 0
}

/**
A Segmented Datasource. 

Usage scenario is where a view (e.g. UITableView) displays the content relevant to
a selected UISegmentedControl tab, typically displayed above or below the table.

The SegmentedDatasource receives an array of DatasourceProviderType instances. This
means they must all be the same type, and therefore have the same underlying associated 
types, e.g. model type. However, typical usage would involve using the tabs to 
filter the same type of objects with some other metric. See the Example project.

*/
public final class SegmentedDatasource<DatasourceProvider: DatasourceProviderType>: DatasourceType {

    public typealias UpdateBlock = () -> Void

    private let state: Protector<SegmentedDatasourceState>
    internal let update: UpdateBlock?
    internal let datasources: [DatasourceProvider]
    private var valueChangedHandler: TargetActionHandler? = .None

    public let identifier: String

    /// The index of the currently selected datasource provider
    public var indexOfSelectedDatasource: Int {
        return state.read { state in
            state.selectedIndex
        }
    }

    /// The currently selected datasource provider
    public var selectedDatasourceProvider: DatasourceProvider {
        return datasources[indexOfSelectedDatasource]
    }

    /// The currently selected datasource
    public var selectedDatasource: DatasourceProvider.Datasource {
        return selectedDatasourceProvider.datasource
    }

    /// The currently selected datasource's title
    public var title: String? {
        return selectedDatasource.title
    }

    /// The currently selected datasource's factory
    public var factory: DatasourceProvider.Datasource.FactoryType {
        return selectedDatasource.factory
    }

    init(id: String, datasources d: [DatasourceProvider], selectedIndex: Int = 0, didSelectDatasourceCompletion: UpdateBlock) {
        identifier = id
        datasources = d
        state = Protector(SegmentedDatasourceState(selectedIndex: selectedIndex))
        update = didSelectDatasourceCompletion
    }

    /**
    Configures a segmented control with the datasource.
    
    This will iterate through the datasources and insert a segment using the
    datasource title for each one.
    
    Additionally, it will add a handler for the .ValueChanged control event. The
    action will select the appropriate datasource and call the 
    didSelectDatasourceCompletion completion block.
    
    :param: segmentedControl the UISegmentedControl to configure.
    
    */
    public func configureSegmentedControl(segmentedControl: UISegmentedControl) {
        segmentedControl.removeAllSegments()

        for (index, provider) in enumerate(datasources) {
            var title = provider.datasource.title ?? "No title"
            segmentedControl.insertSegmentWithTitle(title, atIndex: index, animated: false)
        }

        valueChangedHandler = TargetActionHandler { self.selectedSegmentedIndexDidChange($0) }

        segmentedControl.addTarget(valueChangedHandler!, action: valueChangedHandler!.dynamicType.selector, forControlEvents: .ValueChanged)
        segmentedControl.selectedSegmentIndex = indexOfSelectedDatasource
    }


    /**
    Programatic interface to select a datasource at a given index.
    
    :param: index an Int index.
    */
    public func selectDatasourceAtIndex(index: Int) {
        precondition(0 <= index, "Index must be greater than zero.")
        precondition(index < datasources.count, "Index must be less than maximum number of datasources.")

        state.write({ (inout state: SegmentedDatasourceState) in
            state.selectedIndex = index
        }, completion: update)
    }

    func selectedSegmentedIndexDidChange(sender: AnyObject?) {
        if let segmentedControl = sender as? UISegmentedControl {
            segmentedControl.userInteractionEnabled = false
            selectDatasourceAtIndex(segmentedControl.selectedSegmentIndex)
            segmentedControl.userInteractionEnabled = true
        }
    }

    // DatasourceType

    public var numberOfSections: Int {
        return selectedDatasource.numberOfSections
    }

    public func numberOfItemsInSection(sectionIndex: Int) -> Int {
        return selectedDatasource.numberOfItemsInSection(sectionIndex)
    }

    public func itemAtIndexPath(indexPath: NSIndexPath) -> DatasourceProvider.Datasource.FactoryType.ItemType? {
        return selectedDatasource.itemAtIndexPath(indexPath)
    }

    public func cellForItemInView(view: DatasourceProvider.Datasource.FactoryType.ViewType, atIndexPath indexPath: NSIndexPath) -> DatasourceProvider.Datasource.FactoryType.CellType {
        return selectedDatasource.cellForItemInView(view, atIndexPath: indexPath)
    }

    public func viewForSupplementaryElementInView(view: DatasourceProvider.Datasource.FactoryType.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> DatasourceProvider.Datasource.FactoryType.SupplementaryViewType? {
        return selectedDatasource.viewForSupplementaryElementInView(view, kind: kind, atIndexPath: indexPath)
    }

    public func textForSupplementaryElementInView(view: DatasourceProvider.Datasource.FactoryType.ViewType, kind: SupplementaryElementKind, atIndexPath indexPath: NSIndexPath) -> DatasourceProvider.Datasource.FactoryType.TextType? {
        return selectedDatasource.textForSupplementaryElementInView(view, kind: kind, atIndexPath: indexPath)
    }

    // SequenceType

    public func generate() -> Array<DatasourceProvider>.Generator {
        return datasources.generate()
    }

    // CollectionType

    public var startIndex: Int {
        return datasources.startIndex
    }

    public var endIndex: Int {
        return datasources.endIndex
    }

    public subscript(i: Int) -> DatasourceProvider {
        return datasources[i]
    }
}

public struct SegmentedDatasourceProvider<DatasourceProvider: DatasourceProviderType>: DatasourceProviderType {

    public typealias UpdateBlock = () -> Void

    public let datasource: SegmentedDatasource<DatasourceProvider>

    /// The index of the currently selected datasource provider
    public var indexOfSelectedDatasource: Int {
        return datasource.indexOfSelectedDatasource
    }

    /// The currently selected datasource provider
    public var selectedDatasourceProvider: DatasourceProvider {
        return datasource.selectedDatasourceProvider
    }

    /// The currently selected datasource
    public var selectedDatasource: DatasourceProvider.Datasource {
        return datasource.selectedDatasource
    }

    public var canEditItemAtIndexPath: CanEditItemAtIndexPath? {
        return selectedDatasourceProvider.canEditItemAtIndexPath
    }

    public var commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? {
        return selectedDatasourceProvider.commitEditActionForItemAtIndexPath
    }

    public var editActionForItemAtIndexPath: EditActionForItemAtIndexPath? {
        return selectedDatasourceProvider.editActionForItemAtIndexPath
    }

    public var canMoveItemAtIndexPath: CanMoveItemAtIndexPath? {
        return selectedDatasourceProvider.canMoveItemAtIndexPath
    }

    public var commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? {
        return selectedDatasourceProvider.commitMoveItemAtIndexPathToIndexPath
    }

    /**
    The initializer.

    :param: id, a String identifier for the datasource.
    :param: datasources, an array of DatasourceProvider instances.
    :param: selectedIndex, the index of the initial selection.
    :param: didSelectDatasourceCompletion, a completion block which executes when selecting the datasource has completed. This block should reload the view.
    */
    public init(id: String, datasources: [DatasourceProvider], selectedIndex: Int = 0, didSelectDatasourceCompletion: () -> Void) {
        datasource = SegmentedDatasource(id: id, datasources: datasources, selectedIndex: selectedIndex, didSelectDatasourceCompletion: didSelectDatasourceCompletion)
    }

    /**
    Call the equivalent function on SegmentedDatasource.

    :param: segmentedControl the UISegmentedControl to configure.

    */
    public func configureSegmentedControl(segmentedControl: UISegmentedControl) {
        datasource.configureSegmentedControl(segmentedControl)
    }
}



