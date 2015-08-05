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
    
    // Permission not determined
    @IBOutlet weak var permissionNotDeterminedContainerView: UIView!
    @IBOutlet weak var permissionNotDeterminedLabel: UILabel!
    @IBOutlet weak var permissionTapTheButtonLabel: UILabel!
    @IBOutlet weak var permissionBeginButton: UIButton!

    // Permission access denied
    @IBOutlet weak var permissionAccessDeniedContainerView: UIView!
    @IBOutlet weak var permissionAccessDeniedView: UIView!
    
    // Permission granted
    @IBOutlet weak var permissionGrantedContainerView: UIView!
    @IBOutlet weak var permissionGrantedPerformOperationInstructionsLabel: UILabel!
    @IBOutlet weak var permissionGrantedPerformOperationButton: UIButton!
    
    // Operation Results
    @IBOutlet weak var operationResultsContainerView: UIView!
    @IBOutlet weak var operationResultsLabel: UILabel!
    
    // Permission reset instructions
    @IBOutlet weak var permissionResetInstructionsView: UIView!
    
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

    func condition<Condition: OperationCondition>() -> Condition {
        fatalError("Must be overridded in subclass.")
    }
    
    // MARK: Update UI

    func configureConditionsForState<Condition: OperationCondition>(state: State, silent: Bool = true) -> (Condition) -> [OperationCondition] {
        return { condition in
            switch (silent, state) {
            case (true, .Unknown):
                return [ SilentCondition(NegatedCondition(condition)) ]
            case (false, .Unknown):
                return [ NegatedCondition(condition) ]
            case (true, .Authorized):
                return [ SilentCondition(condition) ]
            case (false, .Authorized):
                return [ condition ]
            default:
                return []
            }
        }
    }

    func conditionsForState(state: State, silent: Bool = true) -> [OperationCondition] {
        // Subclasses should over-ride and call this...
        return configureConditionsForState(state, silent: silent)(BlockCondition { true })
    }

    func viewsForState(state: State) -> [UIView] {
        switch state {
        case .Unknown:
            return [permissionNotDeterminedContainerView]
        case .Authorized:
            return [permissionGrantedContainerView, permissionResetInstructionsView]
        case .Denied:
            return [permissionAccessDeniedContainerView, permissionResetInstructionsView]
        case .Completed:
            return [operationResultsContainerView, permissionResetInstructionsView]
        }
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

