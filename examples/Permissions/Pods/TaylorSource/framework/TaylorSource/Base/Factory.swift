//
//  Created by Daniel Thorpe on 16/04/2015.
//

// MARK: - Protocols


/// Protocol to expose a reuse identifier for cells and views.
public protocol ReusableElement {

    /// reuseIdentifier a String property
    static var reuseIdentifier: String { get }
}

/// Protocol Protocol to expose a nib for a view.
public protocol ReusableView: ReusableElement {
    static var nib: UINib { get }
}

/**
Utility function to instanctiate a view.
*/
public func loadReusableViewFromNib<T: UIView where T: ReusableView>(owner: AnyObject? = .None, options: [NSObject: AnyObject]? = .None) -> T? {
    return NSBundle(forClass: T.self).loadNibNamed(T.reuseIdentifier, owner: owner, options: options).last as? T
}

/**
An enum type for describing cells or views as either classes or nibs. It
helps if ReusableView is implemented on custom cells. E.g.

   .ClassWithIdentifier(MyCell.self, MyCell.reuseIdentifier)
   .NibWithIdentifier(MyCell.nib, MyCell.reuseIdentifier)
*/
public enum ReusableViewDescriptor {
    case ClassWithIdentifier(AnyClass, String)
    case NibWithIdentifier(UINib, String)
}

/**
An enum type which describes supplementary elements. For standard
headers and footers in UITableView and UICollectionView its simple
to use .Header and .Footer, but for arbitrary supplementary element
kinds. There is .Custom("My Custom Supplementary View").
*/
public enum SupplementaryElementKind {
    case Header, Footer
    case Custom(String)
}

struct SupplementaryElementIndex: Hashable {
    let kind: SupplementaryElementKind
    let key: String
}

/**
Protocol for registering and dequeuing cells from a cell based view. 

TaylorSource has implementations for UITableView and UICollectionView.
*/
public protocol ReusableCellBasedView: class {

    /// The generic type of the Cell.
    typealias CellType

    /**
    Registers a nib in the view.
    
    :param: nib A UINib to register.
    :param: reuseIdentifier A String for the reuseIdentifier.
    */
    func registerNib(nib: UINib, withIdentifier reuseIdentifier: String)

    /**
    Registers a class in the view.

    :param: aClass A AnyClass to register.
    :param: reuseIdentifier A String for the reuseIdentifier.
    */
    func registerClass(aClass: AnyClass, withIdentifier reuseIdentifier: String)

    /**
    Dequeues a cell with an identifier at an index path.

    :param: id A String the reuse identifier
    :param: indexPath the NSIndexPath which is required.
    :returns: an instance of the CellType.
    */
    func dequeueCellWithIdentifier(id: String, atIndexPath indexPath: NSIndexPath) -> CellType
}

public protocol ReusableSupplementaryViewBasedView: class {

    /// The generic type of the SupplementaryView.
    typealias SupplementaryViewType

    /**
    Registers a nib in the view for a supplementary element kind, with a reuse identifier.

    :param: nib A UINib to register.
    :param: kind the SupplementaryElementKind
    :param: reuseIdentifier the String.
    */
    func registerNib(nib: UINib, forSupplementaryViewKind kind: SupplementaryElementKind, withIdentifier reuseIdentifier: String)

    /**
    Registers a class in the view for a supplementary element kind, with a reuse identifier.

    :param: aClass A AnyClass to register.
    :param: kind the SupplementaryElementKind
    :param: reuseIdentifier the String.
    */
    func registerClass(aClass: AnyClass, forSupplementaryViewKind kind: SupplementaryElementKind, withIdentifier reuseIdentifier: String)

    /**
    Dequeues a view for a supplementary element kind with an identifier at an index path.

    :param: kind the SupplementaryElementKind
    :param: id A String the reuse identifier
    :param: indexPath the NSIndexPath which is required.
    :returns: an instance of the SupplementaryViewType.
    */
    func dequeueSupplementaryViewWithKind(kind: SupplementaryElementKind, identifier id: String, atIndexPath indexPath: NSIndexPath) -> SupplementaryViewType?
}

/**
Base protocol which the container view must implement.
*/
public protocol CellBasedView: ReusableCellBasedView, ReusableSupplementaryViewBasedView {
    func reloadData()
}

/**
A constraining protocol for the cell & supplementary view
index type. It must expose an indexPath.
*/
public protocol IndexPathIndexType {
    var indexPath: NSIndexPath { get }
}

// MARK: - Factory Type

/**
Generic protocol for Factory types.

The purpose of the factory is to enable the registration and dequeuing 
of cells, supplementary view and texts. This protocol is generic over 
the item, cell, supplementary view, container view, cell index and 
supplementary index.

The container view, e.g. UITableView, has constraints that it must
implement CellBasedView.

The CellIndexType and SupplementaryIndexType allow for the index
parameter of the configuration blocks to be generic.

*/
public protocol _FactoryType {

    typealias ItemType
    typealias CellType
    typealias SupplementaryViewType
    typealias ViewType: CellBasedView
    typealias CellIndexType: IndexPathIndexType
    typealias SupplementaryIndexType: IndexPathIndexType

    /// Cell configuration closure typealias.
    typealias CellConfiguration = (cell: CellType, item: ItemType, index: CellIndexType) -> Void

    /// Supplmentary view configuration closure typealias.
    typealias SupplementaryViewConfiguration = (supplementaryView: SupplementaryViewType, index: SupplementaryIndexType) -> Void

    /// Supplmentary text configuration closure typealias.
    typealias SupplementaryTextConfiguration = (index: SupplementaryIndexType) -> TextType?

    /// The type of the text returned, could be a String, or NSAttributedString for instance.
    typealias TextType

    // Registration

    /**
    Registers the cell in the view, and stores the configuration block in the factory.
    
    The key parameter is used to look up the configuration, as multiple configurations
    can be stored for the same base cell.
    
    :param: descriptor a ReusableViewDescriptor which descibes the cell with either nib or class.
    :param: view the CellBasedView conforming view.
    :param: key a String used for lookup
    :param: configuration the cell configuration closure.
    */
    mutating func registerCell(descriptor: ReusableViewDescriptor, inView view: ViewType, withKey key: String, configuration: CellConfiguration)

    /**
    Registers a supplementary view in the view, and stores the configuration block in the factory.

    The key parameter is used to look up the configuration, as multiple configurations
    can be stored for the same base cell.

    :param: descriptor a ReusableViewDescriptor which descibes the cell with either nib or class.
    :param: kind the SupplementaryElementKind kind.
    :param: view the CellBasedView conforming view.
    :param: key a String used for lookup
    :param: configuration the supplementary view configuration closure.
    */
    mutating func registerSupplementaryView(descriptor: ReusableViewDescriptor, kind: SupplementaryElementKind, inView: ViewType, withKey key: String, configuration: SupplementaryViewConfiguration)

    /**
    Registers the text configuration block.

    The text configuration block receives the SupplementaryIndexType, e.g. an NSIndexPath.

    :param: kind the SupplementaryElementKind kind.
    :param: configuration the text configuration closure.
    */
    mutating func registerTextWithKind(kind: SupplementaryElementKind, configuration: SupplementaryTextConfiguration)

    // Vending

    /**
    Returns a configured cell for the item at the index.
    
    :param: item, the dataum ItemType.
    :param: view, the cell based view, ViewType
    :param: index, the index a CellIndexType.
    */
    func cellForItem(item: ItemType, inView view: ViewType, atIndex index: CellIndexType) -> CellType

    /**
    Returns a configured supplementary view for the item at the index.

    :param: kind, the SupplementaryElementKind kind
    :param: view, the cell based view, ViewType
    :param: index, the index a CellIndexType.
    */
    func supplementaryViewForKind(kind: SupplementaryElementKind, inView view: ViewType, atIndex index: SupplementaryIndexType) -> SupplementaryViewType?

    /**
    Returns a configured text for the supplementary element of kind at index.

    :param: view, the cell based view, ViewType
    :param: index, the index a CellIndexType.
    */
    func supplementaryTextForKind(kind: SupplementaryElementKind, atIndex: SupplementaryIndexType) -> TextType?
}

/**
Concrete implementation of _FactoryType. Should be 
subclassed to constrain the CellIndexType and 
SupplementaryIndexType.
*/
public class Factory<
    Item, Cell, SupplementaryView, View, CellIndex, SupplementaryIndex
    where
    View: CellBasedView,
    CellIndex: IndexPathIndexType,
    SupplementaryIndex: IndexPathIndexType>: _FactoryType {

    typealias TextType = String
    typealias ItemType = Item
    typealias CellType = Cell
    typealias SupplementaryViewType = SupplementaryView
    typealias ViewType = View
    typealias CellIndexType = CellIndex
    typealias SupplementaryIndexType = SupplementaryIndex

    public typealias CellConfig = (cell: Cell, item: Item, index: CellIndexType) -> Void
    public typealias SupplementaryViewConfig = (supplementaryView: SupplementaryView, index: SupplementaryIndexType) -> Void
    public typealias SupplementaryTextConfig = (index: SupplementaryIndexType) -> String?

    public typealias GetCellKey = (Item, CellIndexType) -> String
    public typealias GetSupplementaryKey = (SupplementaryIndexType) -> String

    typealias ReuseIdentifier = String

    static var defaultCellKey: String {
        return "Default Cell Key"
    }

    static var defaultSuppplementaryViewKey: String {
        return "Default Suppplementary View Key"
    }

    let getCellKey: GetCellKey?
    let getSupplementaryKey: GetSupplementaryKey?

    var cells = [String: (ReuseIdentifier, CellConfig)]()
    var views = [SupplementaryElementIndex: (ReuseIdentifier, SupplementaryViewConfig)]()
    var texts = [SupplementaryElementKind: SupplementaryTextConfig]()

    init(cell: GetCellKey? = .None, supplementary: GetSupplementaryKey? = .None) {
        getCellKey = cell
        getSupplementaryKey = supplementary
    }

    // Registration

    public func registerCell(descriptor: ReusableViewDescriptor, inView view: View, configuration: CellConfig) {
        registerCell(descriptor, inView: view, withKey: self.dynamicType.defaultCellKey, configuration: configuration)
    }

    public func registerCell(descriptor: ReusableViewDescriptor, inView view: View, withKey key: String, configuration: CellConfig) {
        descriptor.registerInView(view)
        cells[key] = (descriptor.identifier, configuration)
    }

    public func registerSupplementaryView(descriptor: ReusableViewDescriptor, kind: SupplementaryElementKind, inView view: View, configuration: SupplementaryViewConfig) {
        registerSupplementaryView(descriptor, kind: kind, inView: view, withKey: self.dynamicType.defaultSuppplementaryViewKey, configuration: configuration)
    }

    public func registerSupplementaryView(descriptor: ReusableViewDescriptor, kind: SupplementaryElementKind, inView view: View, withKey key: String, configuration: SupplementaryViewConfig) {
        descriptor.registerInView(view, kind: kind)
        views[SupplementaryElementIndex(kind: kind, key: key)] = (descriptor.identifier, configuration)
    }

    public func registerTextWithKind(kind: SupplementaryElementKind, configuration: SupplementaryTextConfig) {
        texts[kind] = configuration
    }

    // Vending

    public func cellForItem(item: Item, inView view: View, atIndex index: CellIndex) -> Cell {
        let key = getCellKey?(item, index) ?? self.dynamicType.defaultCellKey
        if let (reuseIdentifier: String, configure: CellConfig) = cells[key] {
            let cell = view.dequeueCellWithIdentifier(reuseIdentifier, atIndexPath: index.indexPath) as! Cell
            configure(cell: cell, item: item, index: index)
            return cell
        }
        fatalError("No cell factory registered with key: \(key). Currently registered keys: \(([String])(cells.keys))")
    }

    public func supplementaryViewForKind(kind: SupplementaryElementKind, inView view: View, atIndex index: SupplementaryIndex) -> SupplementaryView? {
        let key = getSupplementaryKey?(index) ?? self.dynamicType.defaultSuppplementaryViewKey
        if let (reuseIdentifier: String, configure: SupplementaryViewConfig) = views[SupplementaryElementIndex(kind: kind, key: key)] {
            if let supplementaryView = view.dequeueSupplementaryViewWithKind(kind, identifier: reuseIdentifier, atIndexPath: index.indexPath) as? SupplementaryView {
                configure(supplementaryView: supplementaryView, index: index)
                return supplementaryView
            }
        }
        return .None
    }

    public func supplementaryTextForKind(kind: SupplementaryElementKind, atIndex index: SupplementaryIndex) -> String? {
        if let configure: SupplementaryTextConfig = texts[kind] {
            return configure(index: index)
        }
        return .None
    }

    // Convenience

    public func registerHeaderView(descriptor: ReusableViewDescriptor, inView view: View, configuration: SupplementaryViewConfig) {
        registerSupplementaryView(descriptor, kind: .Header, inView: view, configuration: configuration)
    }

    public func registerHeaderView(descriptor: ReusableViewDescriptor, inView view: View, withKey key: String, configuration: SupplementaryViewConfig) {
        registerSupplementaryView(descriptor, kind: .Header, inView: view, withKey: key, configuration: configuration)
    }

    public func registerFooterView(descriptor: ReusableViewDescriptor, inView view: View, configuration: SupplementaryViewConfig) {
        registerSupplementaryView(descriptor, kind: .Footer, inView: view, configuration: configuration)
    }

    public func registerFooterView(descriptor: ReusableViewDescriptor, inView view: View, withKey key: String, configuration: SupplementaryViewConfig) {
        registerSupplementaryView(descriptor, kind: .Footer, inView: view, withKey: key, configuration: configuration)
    }

    public func registerHeaderText(configuration: SupplementaryTextConfig) {
        registerTextWithKind(.Header, configuration: configuration)
    }

    public func registerFooterText(configuration: SupplementaryTextConfig) {
        registerTextWithKind(.Footer, configuration: configuration)
    }
}

/**
Basic Factory with NSIndexPath as the CellIndexType and SupplementaryIndexType.
*/
public class BasicFactory<
    Item, Cell, SupplementaryView, View
    where
    View: CellBasedView>: Factory<Item, Cell, SupplementaryView, View, NSIndexPath, NSIndexPath> {

    public override init(cell: GetCellKey? = .None, supplementary: GetSupplementaryKey? = .None) {
        super.init(cell: cell, supplementary: supplementary)
    }
}

// MARK: - Helpers

extension SupplementaryElementKind {

    init(_ kind: String) {
        switch kind {
        case UICollectionElementKindSectionHeader:
            self = .Header
        case UICollectionElementKindSectionFooter:
            self = .Footer
        default:
            self = .Custom(kind)
        }
    }
}

extension SupplementaryElementKind: Printable {

    public var description: String {
        switch self {
        case .Header: return UICollectionElementKindSectionHeader
        case .Footer: return UICollectionElementKindSectionFooter
        case .Custom(let custom): return custom
        }
    }
}

extension SupplementaryElementKind: Hashable {

    public var hashValue: Int {
        return description.hashValue
    }
}

public func == (a: SupplementaryElementKind, b: SupplementaryElementKind) -> Bool {
    return a.description == b.description
}

extension SupplementaryElementIndex: Hashable {

    var hashValue: Int {
        return "\(kind): \(key)".hashValue
    }
}

func == (a: SupplementaryElementIndex, b: SupplementaryElementIndex) -> Bool {
    return (a.key == b.key) && (a.kind == b.kind)
}

extension ReusableViewDescriptor {

    var identifier: String {
        switch self {
        case let .ClassWithIdentifier(_, identifier): return identifier
        case let .NibWithIdentifier(_, identifier): return identifier
        }
    }

    func registerInView<View: ReusableCellBasedView>(view: View) {
        switch self {
        case let .ClassWithIdentifier(aClass, identifier):
            view.registerClass(aClass, withIdentifier: identifier)
        case let .NibWithIdentifier(nib, identifier):
            view.registerNib(nib, withIdentifier: identifier)
        }
    }

    func registerInView<View: ReusableSupplementaryViewBasedView>(view: View, kind: SupplementaryElementKind) {
        switch self {
        case let .ClassWithIdentifier(aClass, identifier):
            view.registerClass(aClass, forSupplementaryViewKind: kind, withIdentifier: identifier)
        case let .NibWithIdentifier(nib, identifier):
            view.registerNib(nib, forSupplementaryViewKind: kind, withIdentifier: identifier)
        }
    }
}

extension NSIndexPath: IndexPathIndexType {

    public var indexPath: NSIndexPath {
        return self
    }
}

extension UITableView: CellBasedView {

    public func registerNib(nib: UINib, withIdentifier id: String) {
        registerNib(nib, forCellReuseIdentifier: id)
    }

    public func registerClass(aClass: AnyClass, withIdentifier id: String) {
        registerClass(aClass, forCellReuseIdentifier: id)
    }

    public func dequeueCellWithIdentifier(id: String, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return dequeueReusableCellWithIdentifier(id, forIndexPath: indexPath) as! UITableViewCell
    }

    public func registerNib(nib: UINib, forSupplementaryViewKind: SupplementaryElementKind, withIdentifier id: String) {
        registerNib(nib, forHeaderFooterViewReuseIdentifier: id)
    }

    public func registerClass(aClass: AnyClass, forSupplementaryViewKind: SupplementaryElementKind, withIdentifier id: String) {
        registerClass(aClass, forHeaderFooterViewReuseIdentifier: id)
    }

    public func dequeueSupplementaryViewWithKind(kind: SupplementaryElementKind, identifier: String, atIndexPath: NSIndexPath) -> UITableViewHeaderFooterView? {
        return dequeueReusableHeaderFooterViewWithIdentifier(identifier) as? UITableViewHeaderFooterView
    }
}

extension UICollectionView: CellBasedView {

    public func registerNib(nib: UINib, withIdentifier id: String) {
        registerNib(nib, forCellWithReuseIdentifier: id)
    }

    public func registerClass(aClass: AnyClass, withIdentifier id: String) {
        registerClass(aClass, forCellWithReuseIdentifier: id)
    }

    public func dequeueCellWithIdentifier(id: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return dequeueReusableCellWithReuseIdentifier(id, forIndexPath: indexPath) as! UICollectionReusableView
    }

    public func registerNib(nib: UINib, forSupplementaryViewKind kind: SupplementaryElementKind, withIdentifier id: String) {
        registerNib(nib, forSupplementaryViewOfKind: "\(kind)", withReuseIdentifier: id)
    }

    public func registerClass(aClass: AnyClass, forSupplementaryViewKind kind: SupplementaryElementKind, withIdentifier id: String) {
        registerClass(aClass, forSupplementaryViewOfKind: "\(kind)", withReuseIdentifier: id)
    }

    public func dequeueSupplementaryViewWithKind(kind: SupplementaryElementKind, identifier: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView? {
        return dequeueReusableSupplementaryViewOfKind("\(kind)", withReuseIdentifier: identifier, forIndexPath: indexPath) as? UICollectionReusableView
    }
}
