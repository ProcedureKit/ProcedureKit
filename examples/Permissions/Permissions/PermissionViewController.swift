//
//  PermissionViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import PureLayout
import Operations

class PermissionViewController: UIViewController {

    class InfoBox: UIView {
        let informationLabel = UILabel.newAutoLayoutView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(informationLabel)
            informationLabel.autoPinEdgesToSuperviewMargins()
            configure()
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure() {
            informationLabel.textAlignment = .Center
            informationLabel.numberOfLines = 4
            informationLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        }
    }

    class InfoInstructionButtonBox: InfoBox {

        let instructionLabel = UILabel.newAutoLayoutView()
        let button = UIButton(type: .Custom)

        var verticalSpaceBetweenLabels: NSLayoutConstraint!
        var verticalSpaceBetweenButton: NSLayoutConstraint!

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(instructionLabel)
            addSubview(button)
            removeConstraints(constraints)
            informationLabel.autoPinEdgesToSuperviewMarginsExcludingEdge(.Bottom)
            verticalSpaceBetweenLabels = instructionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: informationLabel, withOffset: 10)
            instructionLabel.autoPinEdgeToSuperviewMargin(.Leading)
            instructionLabel.autoPinEdgeToSuperviewMargin(.Trailing)
            verticalSpaceBetweenButton = button.autoPinEdge(.Top, toEdge: .Bottom, ofView: instructionLabel, withOffset: 10)
            button.autoPinEdgeToSuperviewMargin(.Bottom)
            button.autoAlignAxisToSuperviewMarginAxis(.Vertical)
            configure()
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func configure() {
            super.configure()
            instructionLabel.textAlignment = .Center
            instructionLabel.numberOfLines = 0
            instructionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            button.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        }
    }
    
    enum Action: Selector {
        case RequestPermission = "requestPermissionAction:"
        case PerformOperation = "performOperationAction:"
    }
    
    enum State: Int {
        case Unknown, Authorized, Denied, Completed

        static var all: [State] = [ .Unknown, .Authorized, .Denied, .Completed ]
    }
    
    // UIViews
    let permissionNotDetermined = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionDenied = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionGranted = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionReset = InfoInstructionButtonBox.newAutoLayoutView()
    let operationResults = InfoBox.newAutoLayoutView()

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

    override func loadView() {

        let _view = UIView(frame: CGRectZero)
        _view.backgroundColor = UIColor.whiteColor()
        
        func configureHierarchy() {
            _view.addSubview(permissionNotDetermined)
            _view.addSubview(permissionDenied)
            _view.addSubview(permissionGranted)
            _view.addSubview(operationResults)
            _view.addSubview(permissionReset)
        }
        
        func configureLayout() {
            for view in [permissionNotDetermined, permissionDenied, permissionGranted] {
                view.autoSetDimension(.Width, toSize: 300)
                view.autoCenterInSuperview()
            }
            
            operationResults.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)

            permissionReset.button.hidden = true
            permissionReset.verticalSpaceBetweenButton.constant = 0
            permissionReset.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        }
        
        configureHierarchy()
        configureLayout()
        
        view = _view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        permissionNotDetermined.informationLabel.text = "We haven't yet asked permission to access your Address Book."
        permissionNotDetermined.instructionLabel.text = "Tap the button below to ask for permissions."
        permissionNotDetermined.button.setTitle("Start", forState: .Normal)
        permissionNotDetermined.button.addTarget(self, action: Action.RequestPermission.rawValue, forControlEvents: .TouchUpInside)
        
        permissionGranted.informationLabel.text = "Permissions was granted. Yay!"
        permissionGranted.instructionLabel.text = "We can now perform an operation as we've been granted the required permissions."
        permissionGranted.button.setTitle("Run", forState: .Normal)
        permissionGranted.button.addTarget(self, action: Action.PerformOperation.rawValue, forControlEvents: .TouchUpInside)
        
        permissionDenied.informationLabel.text = "Permission was denied or restricted. Oh Nos!"
        permissionDenied.instructionLabel.hidden = true
        permissionDenied.button.enabled = false
        permissionDenied.button.hidden = true
        
        permissionReset.informationLabel.text = "iOS remembers permissions for apps between launches and installes. But you can get around this."
        permissionReset.informationLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        permissionReset.informationLabel.textColor = UIColor.redColor()
        permissionReset.instructionLabel.text = "Either, run the app with a different bundle identififier. or reset your global permissions in General > Reset > Location & Address Book for example."
        permissionReset.instructionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        permissionReset.instructionLabel.textColor = UIColor.redColor()
        permissionReset.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.3)

        for view in [permissionNotDetermined, permissionGranted, permissionDenied, permissionReset, operationResults] {
            view.hidden = true
        }
        
        for button in [permissionNotDetermined.button, permissionGranted.button] {
            button.setTitleColor(UIColor.globalTintColor ?? UIColor.blueColor(), forState: .Normal)
        }
    }
    
    // For Overriding
    func requestPermission() {
        assertionFailure("Must be overridden")
    }
    
    func performOperation() {
        assertionFailure("Must be overridden")
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
        // Subclasses should override and call this...
        // return configureConditionsForState(state, silent: silent)(BlockCondition { true })
        fatalError("Requires subclassing otherwise view controller will be left hanging.")
    }

    func viewsForState(state: State) -> [UIView] {
        switch state {
        case .Unknown:
            return [permissionNotDetermined]
        case .Authorized:
            return [permissionGranted, permissionReset]
        case .Denied:
            return [permissionDenied, permissionReset]
        case .Completed:
            return [operationResults]
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
                viewsToHide.forEach { $0.hidden = true }
                viewsToShow.forEach { $0.hidden = false }
                continueWithError(error: nil)
            }
        }
        update.name = "Update UI for state \(state)"

        let conditions = conditionsForState(state, silent: silent)
        conditions.forEach { update.addCondition($0) }
        
        return update
    }

    // Actions
    
    @IBAction func requestPermissionAction(sender: UIButton) {
        requestPermission()
    }
    
    @IBAction func performOperationAction(sender: UIButton) {
        performOperation()
    }
}

