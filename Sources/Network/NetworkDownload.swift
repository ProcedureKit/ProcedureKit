//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

fileprivate var observerContext = 0

/**
 NetworkDownloadProcedure is a simple procedure which will perform a download task using
 URLSession based APIs. It only supports the completion block style API, therefore
 do not use this procedure if you wish to use delegate based APIs on URLSession.
 */
open class NetworkDownloadProcedure<Session: URLSessionTaskFactory>: Procedure, InputProcedure, OutputProcedure, NetworkOperation, ProgressReporting {
    public typealias NetworkResult = ProcedureResult<HTTPPayloadResponse<URL>>
    public typealias CompletionBlock = (NetworkResult) -> Void

    public var input: Pending<URLRequest> {
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
    internal private(set) var task: Session.DownloadTask? = nil
    private var _input: Pending<URLRequest> = .pending
    private var _output: Pending<NetworkResult> = .pending

    public var networkError: Error? {
        return errors.first
    }

    deinit {
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToReceive))
        task?.removeObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesReceived))
    }

    public init(session: Session, request: URLRequest? = nil, completionHandler: @escaping CompletionBlock = { _ in }) {

        self.progress = Progress(totalUnitCount: -1)
        self.session = session
        self.completion = completionHandler
        super.init()
        self.input = request.flatMap { .ready($0) } ?? .pending

        addDidCancelBlockObserver { procedure, _ in
            procedure.stateLock.withCriticalScope {
                procedure.task?.cancel()
            }
        }
    }

    open override func execute() {
        guard let request = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        stateLock.withCriticalScope {
            guard !isCancelled else { return }
            task = session.downloadTask(with: request) { [weak self] location, response, error in
                guard let strongSelf = self else { return }

                if let error = error {
                    strongSelf.finish(withResult: .failure(error))
                    return
                }

                guard let location = location, let response = response as? HTTPURLResponse else {
                    strongSelf.finish(withResult: .failure(ProcedureKitError.unknown))
                    return
                }

                let http = HTTPPayloadResponse(payload: location, response: response)

                strongSelf.completion(.success(http))
                strongSelf.finish(withResult: .success(http))
            }

            task?.addObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToReceive), options: [.new, .old], context: &observerContext)
            task?.addObserver(self, forKeyPath: #keyPath(URLSessionTaskProgressProtocol.countOfBytesReceived), options: [.new, .old], context: &observerContext)

            task?.resume()
        }
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let keyPath = keyPath, let task = object as? Session.DownloadTask {
            switch keyPath {
            case #keyPath(URLSessionTaskProgressProtocol.countOfBytesExpectedToReceive):
                progress.totalUnitCount = task.countOfBytesExpectedToReceive
            case #keyPath(URLSessionTaskProgressProtocol.countOfBytesReceived):
                progress.completedUnitCount = task.countOfBytesReceived
            default: break
            }
        }
    }
}
