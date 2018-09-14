//
//  ViewController.swift
//  TryProcedureKit iOS
//
//  Created by Daniel Thorpe on 05/12/2016.
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import UIKit
import ProcedureKit

class AnotherViewController: UIViewController, DismissingViewController {

    @IBOutlet weak var label: UILabel!
    var didDismissViewControllerBlock: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
    }

    @IBAction func cancel(_ sender: UIButton) {
        dismiss(animated: true, completion: didDismissViewControllerBlock)
    }
}

class ViewController: UIViewController {

    lazy var queue = ProcedureQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        let block = BlockProcedure { this in
            DispatchQueue.default.async {
                this.log.debug.message("Hello ProcedureKit")
                this.finish()
            }
        }
        block.addCondition(UserConfirmationCondition(from: self))
        queue.addOperation(block)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        print("\(type(of: self)) \(#function)")
        super.dismiss(animated: flag, completion: completion)
    }

    @IBAction func go(_ sender: UIButton) {
        guard
            let storyboard = storyboard,
            let another = storyboard.instantiateViewController(withIdentifier: "another") as? AnotherViewController
        else { return }
        let presentation = UIProcedure(present: another, from: self, withStyle: .present, waitForDismissal: true)
        presentation.log.severity = .info
        queue.addOperation(presentation)
    }

    @IBAction func alert(_ sender: UIButton) {

        let alert = AlertProcedure(title: "Hello World", from: self)
        alert.message = "This is a message in an alert"
        alert.add(actionWithTitle: "Sweet") { (procedure, action) in
            procedure.log.debug.message("Running the \(action) handler!")
        }
        queue.addOperation(alert)
    }
}
