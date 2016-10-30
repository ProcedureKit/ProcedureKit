//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class ResilientNetworkProcedureTests: ProcedureKitTestCase {
    typealias NetworkProcedure = ResultProcedure<HTTPResult<Data>>

    func makeFakeNetworkProcedure(withHTTPResult result: HTTPResult<Data>) -> NetworkProcedure {
        return NetworkProcedure { result }
    }

    func makeFakeNetworkProcedure(withData data: Data, withResponse response: HTTPURLResponse) -> NetworkProcedure {
        return makeFakeNetworkProcedure(withHTTPResult: HTTPResult(payload: data, response: response))
    }

    func makeFakeNetworkProcedure(withData data: Data? = nil, withResponse response: HTTPURLResponse) -> NetworkProcedure {
        return makeFakeNetworkProcedure(withHTTPResult: HTTPResult(payload: data, response: response))
    }

    func makeFakeNetworkProcedure(withURL url: URL, statusCode: Int) -> NetworkProcedure {
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        return makeFakeNetworkProcedure(withResponse: response!)
    }

    func makeFakeNetworkRequest() -> NetworkProcedure {
        return makeFakeNetworkProcedure(withURL: "http://httpbin.org/status/200", statusCode: 200)
    }

    func makeRealNetworkProcedure(withURL url: URL) -> NetworkDataProcedure<URLSession> {
        return NetworkDataProcedure(session: URLSession.shared, request: URLRequest(url: url))
    }

    func makeRealNetworkRequest() -> NetworkDataProcedure<URLSession> {
        return makeRealNetworkProcedure(withURL: "http://httpbin.org/status/200")
    }
}

class BadRequestResilientNetworkProcedureTests: ResilientNetworkProcedureTests {

    struct Behavior: ResilientNetworkBehavior {
        var maximumNumberOfAttempts = 4
        var backoffStrategy: WaitStrategy = .incrementing(initial: 2, increment: 2)
        var requestTimeout: TimeInterval? = nil

        func shouldRetryRequest(forResponseWithStatusCode statusCode: HTTPStatusCode, errorCode: Int?) -> Bool {
            return false
        }

        func retryRequestAfter(suggestedDelay delay: Delay, forResponseWithStatusCode statusCode: HTTPStatusCode, errorCode: Int?) -> Delay? {
            return delay
        }
    }

    func makeFakeBadRequestNetworkProcedure() -> NetworkProcedure {
        return makeFakeNetworkProcedure(withURL: "http://httpbin.org/status/400", statusCode: 400)
    }

    func makeRealBadRequestNetworkProcedure() -> NetworkDataProcedure<URLSession> {
        return makeRealNetworkProcedure(withURL: "http://httpbin.org/status/400")
    }

    func test__no_retries() {
        let network = ResilientNetworkProcedure(behavior: Behavior(), body: makeFakeBadRequestNetworkProcedure)
        wait(for: network)
        XCTAssertEqual(network.count, 1)
    }
}

class NetworkTimeoutResilientNetworkProcedureTests: ResilientNetworkProcedureTests {

    struct Behavior: ResilientNetworkBehavior {
        var maximumNumberOfAttempts = 4
        var backoffStrategy: WaitStrategy = .incrementing(initial: 0.1, increment: 0.1)
        var requestTimeout: TimeInterval? = nil

        func shouldRetryRequest(forResponseWithStatusCode statusCode: HTTPStatusCode, errorCode: Int?) -> Bool {
            switch statusCode {
            case .requestTimeout: return true
            default: return false
            }
        }

        func retryRequestAfter(suggestedDelay delay: Delay, forResponseWithStatusCode statusCode: HTTPStatusCode, errorCode: Int?) -> Delay? {
            return delay
        }
    }

    func makeFakeNetworkTimeoutNetworkProcedure() -> NetworkProcedure {
        return makeFakeNetworkProcedure(withURL: "http://httpbin.org/status/408", statusCode: 408)
    }

    func makeFakeRequestIterator() -> IndexingIterator<[NetworkProcedure]> {
        return [ makeFakeNetworkTimeoutNetworkProcedure(), makeFakeNetworkRequest()].makeIterator()
    }

    func makeRealNetworkTimeoutNetworkProcedure() -> NetworkDataProcedure<URLSession> {
        return makeRealNetworkProcedure(withURL: "http://httpbin.org/status/408")
    }

    func makeRealRequestIterator() -> IndexingIterator<[NetworkDataProcedure<URLSession>]> {
        return [ makeRealNetworkTimeoutNetworkProcedure(), makeRealNetworkRequest()].makeIterator()
    }

    func test__one_retry() {
        let network = ResilientNetworkProcedure(behavior: Behavior(), iterator: makeFakeRequestIterator())
        network.log.severity = .notice
        wait(for: network)
        XCTAssertEqual(network.count, 2)
    }
}













