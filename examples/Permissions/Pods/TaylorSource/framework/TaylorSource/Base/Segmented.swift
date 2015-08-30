//
//  Segmented.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 29/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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

    public var editor: ComposedEditor {
        return ComposedEditor(editor: selectedDatasourceProvider.editor)
    }

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


