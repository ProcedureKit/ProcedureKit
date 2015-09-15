//
//  Created by Daniel Thorpe on 21/04/2015.
//

import UIKit

// MARK: UITableView Support


/// A provider of a UITableViewDataSource.
public protocol UITableViewDataSourceProvider {    
    var tableViewDataSource: UITableViewDataSource { get }
}

/// An empty protocol to allow constraining a view type to UITableView.
public protocol UITableViewType { }
extension UITableView: UITableViewType { }

/**
A provider of table view datasource. The provider owns the Datasource (an
instance of something which implements DatasourceType), which it uses
to construct and a bridging class which implements UITableViewDataSource.

The ViewType of the Datasource's Factory is constrained to be a UITableViewType

This architecture allows for different kinds of DatasourceType(s) to
be used as the basic for a UITableViewDataSource, without the need
to implement UITableViewDataSource on any of them.
*/
public struct TableViewDataSourceProvider<DatasourceProvider where DatasourceProvider: DatasourceProviderType, DatasourceProvider.Datasource.FactoryType.ViewType: UITableViewType, DatasourceProvider.Datasource.FactoryType.TextType == String>: UITableViewDataSourceProvider {

    typealias TableView = DatasourceProvider.Datasource.FactoryType.ViewType

    public let provider: DatasourceProvider

    public var datasource: DatasourceProvider.Datasource {
        return provider.datasource
    }

    public var factory: DatasourceProvider.Datasource.FactoryType {
        return datasource.factory
    }
    
    let bridgedTableViewDataSource: TableViewDataSource

    /// Initalizes with a Datasource instance.
    public init(_ p: DatasourceProvider) {
        provider = p

        bridgedTableViewDataSource = TableViewDataSource(
            numberOfSections: { (view) -> Int in
                p.datasource.numberOfSections },
            numberOfRowsInSection: { (view, section) -> Int in
                p.datasource.numberOfItemsInSection(section) },
            cellForRowAtIndexPath: { (view, indexPath) -> UITableViewCell in
                p.datasource.cellForItemInView(view as! TableView, atIndexPath: indexPath) as! UITableViewCell },
            titleForHeaderInSection: { (view, section) -> String? in
                p.datasource.textForSupplementaryElementInView(view as! TableView, kind: .Header, atIndexPath: NSIndexPath(forRow: 0, inSection: section)) },
            titleForFooterInSection: { (view, section) -> String? in
                p.datasource.textForSupplementaryElementInView(view as! TableView, kind: .Footer, atIndexPath: NSIndexPath(forRow: 0, inSection: section)) }
        )
    }

    public var tableViewDataSource: UITableViewDataSource {
        return bridgedTableViewDataSource
    }
}

class TableViewDataSource: NSObject, UITableViewDataSource {

    private let numberOfSections: (UITableView) -> Int
    private let numberOfRowsInSection: (UITableView, Int) -> Int
    private let cellForRowAtIndexPath: (UITableView, NSIndexPath) -> UITableViewCell
    private let titleForHeaderInSection: (UITableView, Int) -> String?
    private let titleForFooterInSection: (UITableView, Int) -> String?

    init(
        numberOfSections: (UITableView) -> Int,
        numberOfRowsInSection: (UITableView, Int) -> Int,
        cellForRowAtIndexPath: (UITableView, NSIndexPath) -> UITableViewCell,
        titleForHeaderInSection: (UITableView, Int) -> String?,
        titleForFooterInSection: (UITableView, Int) -> String?) {

            self.numberOfSections = numberOfSections
            self.numberOfRowsInSection = numberOfRowsInSection
            self.cellForRowAtIndexPath = cellForRowAtIndexPath
            self.titleForHeaderInSection = titleForHeaderInSection
            self.titleForFooterInSection = titleForFooterInSection
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections(tableView)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(tableView, section)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cellForRowAtIndexPath(tableView, indexPath)
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection(tableView, section)
    }

    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return titleForFooterInSection(tableView, section)
    }
}

// MARK: - UICollectionView Support

/// A provider of a UICollectionViewDataSource
public protocol UICollectionViewDataSourceProvider {
    var collectionViewDataSource: UICollectionViewDataSource { get }
}

/// An empty protocol to allow constraining a view type to UICollectionView.
public protocol UICollectionViewType { }
extension UICollectionView: UICollectionViewType { }

/**
A provider of a UICollectionViewDataSource. The provider owns a Datasource (an
instance of something which implements DatasourceType), which it uses
to construct and a bridging class which implements UICollectionViewDataSource.

The ViewType of the Datasource's Factory is constrained to be a UICollectionViewType
*/
public struct CollectionViewDataSourceProvider<DatasourceProvider where DatasourceProvider: DatasourceProviderType, DatasourceProvider.Datasource.FactoryType.ViewType: UICollectionViewType>: UICollectionViewDataSourceProvider {

    typealias CollectionView = DatasourceProvider.Datasource.FactoryType.ViewType

    let provider: DatasourceProvider

    let bridgedDataSource: CollectionViewDataSource

    /// Initializes with a Datasource instance
    public init(_ p: DatasourceProvider) {
        provider = p
        bridgedDataSource = CollectionViewDataSource(
            numberOfSections: { (view) -> Int in
                p.datasource.numberOfSections },
            numberOfItemsInSection: { (view, section) -> Int in
                p.datasource.numberOfItemsInSection(section) },
            cellForItemAtIndexPath: { (view, indexPath) -> UICollectionViewCell in
                p.datasource.cellForItemInView(view as! CollectionView, atIndexPath: indexPath) as! UICollectionViewCell },
            viewForElementKindAtIndexPath: { (view, indexPath, element) -> UICollectionReusableView in
                p.datasource.viewForSupplementaryElementInView(view as! CollectionView, kind: SupplementaryElementKind(element), atIndexPath: indexPath) as! UICollectionReusableView }
        )
    }

    public var collectionViewDataSource: UICollectionViewDataSource {
        return bridgedDataSource
    }
}

class CollectionViewDataSource: NSObject, UICollectionViewDataSource {

    private let numberOfSections: (UICollectionView) -> Int
    private let numberOfItemsInSection: (UICollectionView, Int) -> Int
    private let cellForItemAtIndexPath: (UICollectionView, NSIndexPath) -> UICollectionViewCell
    private let viewForElementKindAtIndexPath: (UICollectionView, NSIndexPath, String) -> UICollectionReusableView

    init(numberOfSections: (UICollectionView) -> Int, numberOfItemsInSection: (UICollectionView, Int) -> Int, cellForItemAtIndexPath: (UICollectionView, NSIndexPath) -> UICollectionViewCell, viewForElementKindAtIndexPath: (UICollectionView, NSIndexPath, String) -> UICollectionReusableView) {
        self.numberOfSections = numberOfSections
        self.numberOfItemsInSection = numberOfItemsInSection
        self.cellForItemAtIndexPath = cellForItemAtIndexPath
        self.viewForElementKindAtIndexPath = viewForElementKindAtIndexPath
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections(collectionView)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsInSection(collectionView, section)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return cellForItemAtIndexPath(collectionView, indexPath)
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return viewForElementKindAtIndexPath(collectionView, indexPath, kind)
    }
}
