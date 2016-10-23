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

    public var requirement: PendingValue<URLRequest> = .pending
    public var result: PendingValue<(Data, HTTPURLResponse)> = .pending

    public private(set) var session: Session
    public let completion: (Data, HTTPURLResponse) -> Void

    internal var task: Session.DataTask? = nil

    public init(session: Session, request: URLRequest? = nil, completionHandler: @escaping (Data, HTTPURLResponse) -> Void = { _, _ in }) {
        self.session = session
        self.requirement = request.flatMap { .ready($0) } ?? .pending
        self.completion = completionHandler
        super.init()
        addWillCancelBlockObserver { procedure, _ in
            procedure.task?.cancel()
        }
    }

    open override func execute() {
        guard let request = requirement.value else {
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

            strongSelf.result = .ready((data, response))
            strongSelf.completion(data, response)
            strongSelf.finish()
        }

        task?.resume()
    }
}
