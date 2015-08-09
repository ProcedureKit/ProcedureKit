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
            informationLabel.numberOfLines = 0
            informationLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        }
    }

    class InfoInstructionButtonBox: InfoBox {
        let instructionLabel = UILabel.newAutoLayoutView()
        let button = UIButton.buttonWithType(.Custom) as! UIButton
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(instructionLabel)
            addSubview(button)
            removeConstraints(constraints())
            informationLabel.autoPinEdgesToSuperviewMarginsExcludingEdge(.Bottom)
            instructionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: informationLabel, withOffset: 20)
            instructionLabel.autoPinEdgeToSuperviewMargin(.Leading)
            instructionLabel.autoPinEdgeToSuperviewMargin(.Trailing)
            button.autoPinEdge(.Top, toEdge: .Bottom, ofView: instructionLabel, withOffset: 20)
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
    
<<<<<<< Updated upstream
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
=======
    // UIViews
    let permissionNotDetermined = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionDenied = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionGranted = InfoInstructionButtonBox.newAutoLayoutView()
    let permissionReset = InfoInstructionButtonBox.newAutoLayoutView()
    let operationResults = InfoBox.newAutoLayoutView()
>>>>>>> Stashed changes
    
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

<<<<<<< Updated upstream
    func condition<Condition: OperationCondition>() -> Condition {
        fatalError("Must be overridded in subclass.")
=======
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
            
            permissionReset.autoSetDimension(.Height, toSize: 100)
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
        
        permissionReset.informationLabel.text = "iOS remembers permissions for apps between launches and installes. But you can get around this..."
        permissionReset.instructionLabel.text = "Either, run the app with a different bundle identififier. or reset your global permissions in General > Reset > Location & Address Book for example."
        permissionReset.informationLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        permissionReset.instructionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)

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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            return [permissionNotDeterminedContainerView]
        case .Authorized:
            return [permissionGrantedContainerView, permissionResetInstructionsView]
        case .Denied:
            return [permissionAccessDeniedContainerView, permissionResetInstructionsView]
        case .Completed:
            return [operationResultsContainerView, permissionResetInstructionsView]
=======
            return [permissionNotDetermined]
        case .Authorized:
            return [permissionGranted, permissionReset]
        case .Denied:
            return [permissionDenied, permissionReset]
        case .Completed:
            return [operationResults, permissionReset]
>>>>>>> Stashed changes
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

    // Actions
    
    @IBAction func requestPermissionAction(sender: UIButton) {
        requestPermission()
    }
    
    @IBAction func performOperationAction(sender: UIButton) {
        performOperation()
    }
}

