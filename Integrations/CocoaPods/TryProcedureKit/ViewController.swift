//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Cocoa
import ProcedureKit

class ViewController: NSViewController {

    lazy var queue = ProcedureQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        queue.addOperation(AsyncBlockProcedure { finishWithResult in
            DispatchQueue.default.async {
                print("Hello world")
                finishWithResult(success)
            }
        })

        getNetworkResource()
    }

    func getNetworkResource() {

        let procedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: URLRequest(url: "http://www.apple.com")) }
        procedure.log.severity = .info
        procedure.addDidFinishBlockObserver { procedure, error in
            guard let result = procedure.output.success else { return }
            procedure.log.info.message("Received: \(result.response)")
        }
        queue.addOperation(procedure)
    }
}
