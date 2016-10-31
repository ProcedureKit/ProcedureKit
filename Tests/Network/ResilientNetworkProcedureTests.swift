//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class ResilientNetworkProcedureTestCase: ProcedureKitTestCase {
    typealias NetworkProcedure = ResultProcedure<HTTPResult<Data>>

    func makeFakeNetworkProcedure(withHTTPResult result: HTTPResult<Data>) -> NetworkProcedure {
        return NetworkProcedure { result }
    }

    func makeFakeNetworkProcedure(withData data: Data? = nil, withResponse response: HTTPURLResponse) -> NetworkProcedure {
        return makeFakeNetworkProcedure(withHTTPResult: HTTPResult(payload: data, response: response))
    }

    func makeFakeNetworkProcedure(withURL url: URL, statusCode: Int) -> NetworkProcedure {
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        return makeFakeNetworkProcedure(withResponse: response!)
    }

    func makeFakeNetworkProcedure() -> NetworkProcedure {
        return makeFakeNetworkProcedure(withURL: "http://httpbin.org/status/200", statusCode: 200)
    }

    func makeRealNetworkProcedure(withURL url: URL) -> NetworkDataProcedure<URLSession> {
        return NetworkDataProcedure(session: URLSession.shared, request: URLRequest(url: url))
    }

    func makeRealNetworkRequest() -> NetworkDataProcedure<URLSession> {
        return makeRealNetworkProcedure(withURL: "http://httpbin.org/status/200")
    }
}

class TimeoutResilientNetworkProcedureTests: ResilientNetworkProcedureTestCase {

    struct Behavior: ResilientNetworkBehavior {

        var maximumNumberOfAttempts = 4
        var backoffStrategy: WaitStrategy = .incrementing(initial: 1, increment: 1)
        var requestTimeout: TimeInterval? = 0.2

        func shouldRetryRequest(forResponse response: ResilientNetworkResponse) -> Bool {
            switch (response.statusCode, response.error) {
            case (.some(.requestTimeout), _), (_, .some(.requestTimeout)):
                return true
            default:
                return false
            }
        }

        func retryRequestAfter(suggestedDelay delay: Delay, forResponse response: ResilientNetworkResponse) -> Delay? {
            switch (response.statusCode, response.error) {
            case (.some(.requestTimeout), _), (_, .some(.requestTimeout)):
                return .by(1)
            default:
                return delay
            }
        }
    }

    func makeFakeNetworkTimeoutNetworkProcedure() -> NetworkProcedure {
        return makeFakeNetworkProcedure(withURL: "http://httpbin.org/status/408", statusCode: 408)
    }

    func makeRealNetworkTimeoutNetworkProcedure() -> NetworkDataProcedure<URLSession> {
        return makeRealNetworkProcedure(withURL: "http://httpbin.org/status/408")
    }

    func test__given_status_code_indicates_request_timeout__then_retry() {
        let iterator = [ makeFakeNetworkTimeoutNetworkProcedure(), makeFakeNetworkProcedure()].makeIterator()
        let network = ResilientNetworkProcedure(behavior: Behavior(), iterator: iterator)
        network.log.severity = .notice
        wait(for: network, withTimeout: 4)
        XCTAssertEqual(network.count, 2)
    }

}

class BadRequestResilientNetworkProcedureTests: ResilientNetworkProcedureTestCase {

    struct Behavior: ResilientNetworkBehavior {
        var maximumNumberOfAttempts = 4
        var backoffStrategy: WaitStrategy = .incrementing(initial: 2, increment: 2)
        var requestTimeout: TimeInterval? = nil

        func shouldRetryRequest(forResponse response: ResilientNetworkResponse) -> Bool {
            return false
        }

        func retryRequestAfter(suggestedDelay delay: Delay, forResponse response: ResilientNetworkResponse) -> Delay? {
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














