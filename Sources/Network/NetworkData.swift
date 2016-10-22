//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

/**
 NetworkDataProcedure is a simple procedure which will perform a data task using
 URLSession based APIs. It only supports the completion block style API, therefore
 do not use this procedure if you wish to use delegate based APIs on URLSession.
*/
open class NetworkDataProcedure<Session: URLSessionTaskFactory>: Procedure, ResultInjectionProtocol {

    public var requirement: URLRequest? = nil
    public var result: (Data, HTTPURLResponse)? = nil

    public private(set) var session: Session
    public let completion: (Data, HTTPURLResponse) -> Void

    internal var task: Session.DataTask? = nil

    public init(session: Session, request: URLRequest? = nil, completionHandler: @escaping (Data, HTTPURLResponse) -> Void = { _, _ in }) {
        self.session = session
        self.requirement = request
        self.completion = completionHandler
        super.init()
        addWillCancelBlockObserver { procedure, _ in
            procedure.task?.cancel()
        }
    }

    open override func execute() {
        guard let request = requirement else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }

        task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }

            if let error = error {
                strongSelf.finish(withError: error)
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                strongSelf.finish(withError: ProcedureKitError.unknown)
                return
            }

            strongSelf.result = (data, response)
            strongSelf.completion(data, response)
            strongSelf.finish()
        }

        task?.resume()
    }
}
