//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

/**
 NetworkDownloadProcedure is a simple procedure which will perform a download task using
 URLSession based APIs. It only supports the completion block style API, therefore
 do not use this procedure if you wish to use delegate based APIs on URLSession.
 */
open class NetworkDownloadProcedure<Session: URLSessionTaskFactory>: Procedure, InputProcedure, OutputProcedure, NetworkOperation {

    public typealias CompletionBlock = (Result<HTTPResult<URL>>) -> Void

    public var input: Pending<URLRequest> = .pending
    public var output: Pending<Result<HTTPResult<URL>>> = .pending

    public private(set) var session: Session
    public let completion: CompletionBlock

    internal var task: Session.DownloadTask? = nil

    public var networkError: ProcedureKitNetworkError? {
        return output.error as? ProcedureKitNetworkError ?? errors.flatMap { $0 as? ProcedureKitNetworkError }.first
    }

    public init(session: Session, request: URLRequest? = nil, completionHandler: @escaping CompletionBlock = { _ in }) {

        self.session = session
        self.input = request.flatMap { .ready($0) } ?? .pending
        self.completion = completionHandler

        super.init()
        addWillCancelBlockObserver { procedure, _ in
            procedure.task?.cancel()
        }
    }

    open override func execute() {
        guard let request = input.value else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }

        task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let strongSelf = self else { return }

            defer { strongSelf.finish(withError: strongSelf.output.error) }

            if let error = error {
                strongSelf.output = .ready(.failure(ProcedureKitNetworkError(error as NSError)))
                return
            }

            guard let location = location, let response = response as? HTTPURLResponse else {
                strongSelf.output = .ready(.failure(ProcedureKitError.unknown))
                return
            }

            let http = HTTPResult(payload: location, response: response)

            strongSelf.output = .ready(.success(http))
            strongSelf.completion(.success(http))
        }

        task?.resume()
    }
}
