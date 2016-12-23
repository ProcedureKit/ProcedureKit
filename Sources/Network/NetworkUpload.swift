//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

fileprivate var observerContext = 0

/**
 NetworkUploadProcedure is a simple procedure which will perform a upload task using
 URLSession based APIs. It only supports the completion block style API, therefore
 do not use this procedure if you wish to use delegate based APIs on URLSession.
 */
open class NetworkUploadProcedure<Session: URLSessionTaskFactory>: Procedure, InputProcedure, OutputProcedure, NetworkOperation, ProgressReporting {
    public typealias NetworkResult = ProcedureResult<HTTPPayloadResponse<Data>>
    public typealias CompletionBlock = (NetworkResult) -> Void

    public var input: Pending<HTTPPayloadRequest<Data>> {
        get { return stateLock.withCriticalScope { _input } }
        set {
            stateLock.withCriticalScope {
                _input = newValue
            }
        }
    }

    public var output: Pending<NetworkResult> {
        get { return stateLock.withCriticalScope { _output } }
        set {
            stateLock.withCriticalScope {
                _output = newValue
            }
        }
    }

    public private(set) var progress: Progress

    public let session: Session
    public let completion: CompletionBlock

    private let stateLock = NSLock()
    internal private(set) var task: Session.UploadTask? = nil
    private var _input: Pending<HTTPPayloadRequest<Data>> = .pending
    private var _output: Pending<NetworkResult> = .pending

    public var networkError: Error? {
        return errors.first
    }

    deinit {
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToSend))
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesSent))
    }

    public init(session: Session, request: URLRequest? = nil, data: Data? = nil, completionHandler: @escaping CompletionBlock = { _ in }) {

        self.progress = Progress(totalUnitCount: Int64(data?.count ?? -1))
        self.session = session
        self.completion = completionHandler
        super.init()
        self.input = request.flatMap { .ready(HTTPPayloadRequest(payload: data, request: $0)) } ?? .pending

        addDidCancelBlockObserver { procedure, _ in
            procedure.stateLock.withCriticalScope {
                procedure.task?.cancel()
            }
        }
    }

    open override func execute() {
        guard let requirement = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        stateLock.withCriticalScope {
            guard !isCancelled else { return }
            task = session.uploadTask(with: requirement.request, from: requirement.payload) { [weak self] data, response, error in
                guard let strongSelf = self else { return }

                if let error = error {
                    strongSelf.finish(withResult: .failure(error))
                    return
                }

                guard let data = data, let response = response as? HTTPURLResponse else {
                    strongSelf.finish(withResult: .failure(ProcedureKitError.unknown))
                    return
                }

                let http = HTTPPayloadResponse(payload: data, response: response)

                strongSelf.completion(.success(http))
                strongSelf.finish(withResult: .success(http))
            }

            task?.addObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToSend), options: [.new, .old], context: &observerContext)
            task?.addObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesSent), options: [.new, .old], context: &observerContext)

            task?.resume()
        }
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let keyPath = keyPath, let task = object as? Session.UploadTask {
            switch keyPath {
            case #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToSend):
                progress.totalUnitCount = task.countOfBytesExpectedToSend
            case #keyPath(URLSessionTaskProgressProtocol.countOfBytesSent):
                progress.completedUnitCount = task.countOfBytesSent
            default: break
            }
        }
    }

}
