//
//  PermissionViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import Operations

class PermissionViewController: UIViewController {

    enum State: Int {
        case Unknown, Authorized, Denied, Completed

        static var all: [State] = [ .Unknown, .Authorized, .Denied, .Completed ]
    }

    let queue = OperationQueue()

    private var _state: State = .Unknown
    var state: State {
        get {
            return _state
        }
        set {
            switch (_state, newValue) {

            case (.Completed, _):
                break

            case (.Unknown, _):
                _state = newValue
                queue.addOperation(displayOperationForState(newValue, silent: true))

            default:
                _state = newValue
                queue.addOperation(displayOperationForState(newValue, silent: false))

            }
        }
    }

    // MARK: Update UI

    func conditionsForState(state: State, silent: Bool = true) -> [OperationCondition] {
        assertionFailure("Must be over-ridden in a subclass.")
        return []
    }

    func viewsForState(state: State) -> [UIView] {
        assertionFailure("Must be over-ridden in a subclass.")
        return []
    }

    func displayOperationForState(state: State, silent: Bool = true) -> Operation {
        let others: [State] = {
            var all = Set(State.all)
            let _ = all.remove(state)
            return Array(all)
        }()

        let viewsToHide = others.flatMap { self.viewsForState($0) }
        let viewsToShow = viewsForState(state)

        let update = BlockOperation { (continueWithError: BlockOperation.ContinuationBlockType) in
            dispatch_async(Queue.Main.queue) {
                viewsToHide.map { $0.hidden = true }
                viewsToShow.map { $0.hidden = false }
                continueWithError(error: nil)
            }
        }
        update.name = "Update UI for state: \(state)"

        let conditions = conditionsForState(state, silent: silent)
        conditions.map { update.addCondition($0) }
        
        return update
    }


}

