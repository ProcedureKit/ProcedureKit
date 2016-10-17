//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import ProcedureKit

open class NetworkDataProcedure<Session: URLSessionTaskFactory>: Procedure, ResultInjectionProtocol {

    public var requirement: URLRequest? = nil
    public var result: (Data, URLResponse)? = nil

    public private(set) var session: Session
    public let completion: (Data, URLResponse) -> Void

    internal var task: Session.DataTask? = nil

    //swiftlint:disable:next force_cast
    public init(session: Session = URLSession.shared as! Session, request: URLRequest? = nil, completionHandler: @escaping (Data, URLResponse) -> Void = { _, _ in }) {
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

            guard let data = data, let response = response else {
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
