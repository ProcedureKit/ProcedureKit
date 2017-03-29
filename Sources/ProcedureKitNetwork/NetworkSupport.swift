//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

// MARK: - URLSession

public protocol URLSessionTaskProtocol {
    func resume()
    func cancel()
}

public protocol URLSessionDataTaskProtocol: URLSessionTaskProtocol { }
public protocol URLSessionDownloadTaskProtocol: URLSessionTaskProtocol { }
public protocol URLSessionUploadTaskProtocol: URLSessionTaskProtocol { }

public protocol URLSessionTaskFactory {
    associatedtype DataTask: URLSessionDataTaskProtocol
    associatedtype DownloadTask: URLSessionDownloadTaskProtocol
    associatedtype UploadTask: URLSessionUploadTaskProtocol

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> DownloadTask

    func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> UploadTask
}

extension URLSessionTask: URLSessionTaskProtocol { }
extension URLSessionDataTask: URLSessionDataTaskProtocol {}
extension URLSessionDownloadTask: URLSessionDownloadTaskProtocol { }
extension URLSessionUploadTask: URLSessionUploadTaskProtocol { }
extension URLSession: URLSessionTaskFactory { }

extension URL: ExpressibleByStringLiteral {

    public init(unicodeScalarLiteral value: String) {
        self.init(string: value)!
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(string: value)!
    }

    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}

// MARK: - Input & Output wrapper types

public protocol HTTPPayloadResponseProtocol: Equatable {
    associatedtype Payload: Equatable

    var payload: Payload? { get }
    var response: HTTPURLResponse { get }
}

public struct HTTPPayloadResponse<Payload: Equatable>: HTTPPayloadResponseProtocol {

    public static func == (lhs: HTTPPayloadResponse<Payload>, rhs: HTTPPayloadResponse<Payload>) -> Bool {
        return lhs.payload == rhs.payload && lhs.response == rhs.response
    }

    public var payload: Payload?
    public var response: HTTPURLResponse

    public init(payload: Payload, response: HTTPURLResponse) {
        self.payload = payload
        self.response = response
    }
}

public struct HTTPPayloadRequest<Payload: Equatable>: Equatable {
    public static func == (lhs: HTTPPayloadRequest <Payload>, rhs: HTTPPayloadRequest <Payload>) -> Bool {
        return lhs.payload == rhs.payload && lhs.request == rhs.request
    }

    public var request: URLRequest
    public var payload: Payload?

    public init(payload: Payload? = nil, request: URLRequest) {
        self.payload = payload
        self.request = request
    }
}

// MARK: - Error Handling

struct ProcedureKitNetworkError: Error {

    let underlyingError: Error

    var errorCode: Int {
        return (underlyingError as NSError).code
    }

    var isTransientError: Bool {
        switch errorCode {
        case NSURLErrorNetworkConnectionLost:
            return true
        default:
            return false
        }
    }

    var isTimeoutError: Bool {
        guard let procedureKitError = underlyingError as? ProcedureKitError else { return false }
        guard case .timedOut(with: _) = procedureKitError.context else { return false }
        return true
    }

    var waitForReachabilityChangeBeforeRetrying: Bool {
        switch errorCode {
        case NSURLErrorNotConnectedToInternet, NSURLErrorInternationalRoamingOff, NSURLErrorCallIsActive, NSURLErrorDataNotAllowed:
            return true
        default:
            return false
        }
    }

    init(error: Error) {
        self.underlyingError = error
    }
}

struct ProcedureKitNetworkResponse {

    let response: HTTPURLResponse?
    let error: ProcedureKitNetworkError?

    var httpStatusCode: HTTPStatusCode? {
        return response?.code
    }

    init(response: HTTPURLResponse? = nil, error: Error? = nil) {
        self.response = response
        self.error = error.map { ProcedureKitNetworkError(error: $0) }
    }
}

public protocol NetworkOperation {

    var networkError: Error? { get }

    var urlResponse: HTTPURLResponse? { get }
}

public enum HTTPStatusCode: Int, CustomStringConvertible {

    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102
    case checkpoint = 103

    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case imUsed = 226

    case multipleChoices = 300
    case movedPermenantly = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    case permanentRedirect = 308

    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case imATeapot = 418
    case misdirectedRequest = 421
    case unprocesssableEntity = 422
    case locked = 423
    case failedDependency = 424
    case urpgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeadersFieldTooLarge = 431
    case iisLoginTimeout = 440
    case nginxNoResponse = 444
    case iisRetryWith = 449
    case blockedByWindowsParentalControls = 450
    case unavailableForLegalReasons = 451
    case nginxSSLCertificateError = 495
    case nginxHTTPToHTTPS = 497
    case tokenExpired = 498
    case nginxClientClosedRequest = 499

    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case bandwidthLimitExceeded = 509
    case notExtended = 510
    case networkAuthenticationRequired = 511
    case siteIsFrozen = 530

    public var isInformational: Bool {
        switch rawValue {
        case 100..<200: return true
        default: return false
        }
    }

    public var isSuccess: Bool {
        switch rawValue {
        case 200..<300: return true
        default: return false
        }
    }

    public var isRedirection: Bool {
        switch rawValue {
        case 300..<400: return true
        default: return false
        }
    }

    public var isClientError: Bool {
        switch rawValue {
        case 400..<500: return true
        default: return false
        }
    }

    public var isServerError: Bool {
        switch rawValue {
        case 500..<600: return true
        default: return false
        }
    }

    public var localizedReason: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }

    public var description: String {
        return "\(rawValue) \(localizedReason)"
    }
}

// MARK: - Extensions

public extension HTTPURLResponse {

    public var code: HTTPStatusCode? {
        return HTTPStatusCode(rawValue: statusCode)
    }
}

extension NetworkOperation {

    func makeNetworkResponse() -> ProcedureKitNetworkResponse {
        return ProcedureKitNetworkResponse(response: urlResponse, error: networkError)
    }
}

extension NetworkOperation where Self: OutputProcedure, Self.Output: HTTPPayloadResponseProtocol {

    public var urlResponse: HTTPURLResponse? {
        return output.success?.response
    }
}
