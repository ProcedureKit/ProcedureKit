//
//  ViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import AddressBook
import TaylorSource
import Operations

enum Demo: Int {

    struct Info {
        let title: String
        let subtitle: String
    }

    case AddressBook, Location, UserNotificationSettings

    static let all: [Demo] = [ .AddressBook, .Location, .UserNotificationSettings ]

    var info: Info {
        switch self {

        case .AddressBook:
            return Info(
                title: "Address Book",
                subtitle: "Access to ABAddressBook inside a AddressBookOperation. Use AddressBookCondition to test whether the user has granted permissions. Combine with SilentCondition and NegatedCondition to test this before presenting permissions."
            )

        case .Location:
            return Info(
                title: "Location",
                subtitle: "Get the user's current location. Use LocationCondition to test whether the user has granted permissions."
            )
            
        case .UserNotificationSettings:
            return Info(
                title: "User Notification Settings",
                subtitle: "Use this condition to ensure that your app has requested the appropriate permissions from the user before setting up notifications."
            )
        }
    }
}

struct ContentsDatasourceProvider: DatasourceProviderType {

    typealias Factory = BasicFactory<Demo, DemoContentCell, UITableViewHeaderFooterView, UITableView>
    typealias Datasource = StaticDatasource<Factory>

    let datasource: Datasource

    var canEditItemAtIndexPath: CanEditItemAtIndexPath?  = .None
    var commitEditActionForItemAtIndexPath: CommitEditActionForItemAtIndexPath? = .None
    var editActionForItemAtIndexPath: EditActionForItemAtIndexPath? = .None
    var canMoveItemAtIndexPath: CanMoveItemAtIndexPath? = .None
    var commitMoveItemAtIndexPathToIndexPath: CommitMoveItemAtIndexPathToIndexPath? = .None

    init(tableView: UITableView) {
        datasource = Datasource(id: "Contents", factory: Factory(), items: Demo.all)
        datasource.factory.registerCell(ReusableViewDescriptor.NibWithIdentifier(DemoContentCell.nib, DemoContentCell.reuseIdentifier), inView: tableView, configuration: DemoContentCell.configuration())
    }
}

class MainController: UIViewController {

    @IBOutlet var tableView: UITableView!

    let queue = OperationQueue()
    var provider: TableViewDataSourceProvider<ContentsDatasourceProvider>!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    func configure() {
        title = NSLocalizedString("Permissions", comment: "Permissions")
        provider = TableViewDataSourceProvider(ContentsDatasourceProvider(tableView: tableView))
        tableView.dataSource = provider.tableViewDataSource
        tableView.delegate = self
        tableView.estimatedRowHeight = 54.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
}

extension MainController: UITableViewDelegate {

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let demo = provider.datasource.itemAtIndexPath(indexPath) {
            var show: BlockOperation? = .None
            
            switch demo {
            case .Location:
                let viewController = LocationViewController()
                show = BlockOperation {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }

            case .AddressBook:
                let viewController = AddressBookViewController()
                show = BlockOperation {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
                
            case .UserNotificationSettings:
                let viewController = UserNotificationSettingsViewController()
                show = BlockOperation {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
            
            if let show = show {
                show.addCondition(MutuallyExclusive<UIViewController>())
                show.addObserver(BlockObserver { (_, errors) in
                    dispatch_async(Queue.Main.queue) {
                        tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                })
                
                queue.addOperation(show)
            }
        }
    }
}

class DemoContentCell: UITableViewCell, ReusableView {

    static var reuseIdentifier = "DemoContentCell"
    static var nib: UINib {
        return UINib(nibName: reuseIdentifier, bundle: nil)
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!

    class func configuration() -> ContentsDatasourceProvider.Datasource.FactoryType.CellConfiguration {
        return { (cell, demo, index) in
            cell.titleLabel.text = demo.info.title
            cell.textView.text = demo.info.subtitle
            cell.accessoryType = .DisclosureIndicator
        }
    }
}

extension UIStoryboardSegue {

    enum Segue: String {
        case AddressBook = "AddressBook"
        case Location = "Location"
        case UserNotificationSettings = "UserNotificationSettings"

        var pushSegueIdentifier: String {
            return segueIdentifierWithPrefix("push")
        }

        var presentSegueIdentifier: String {
            return segueIdentifierWithPrefix("present")
        }

        private func segueIdentifierWithPrefix(prefix: String) -> String {
            return "\(prefix).\(rawValue)"
        }

    }
}

