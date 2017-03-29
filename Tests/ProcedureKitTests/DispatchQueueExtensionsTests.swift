//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit
import Dispatch

private let dispatchQosClassOrder: [DispatchQoS.QoSClass] = [.unspecified, .background, .utility, .default, .userInitiated, .userInteractive]

class DispatchQoSClassTests: XCTestCase {

    func test_dispatchqos_qosclass_comparable() {
        for (i, currentQoSClass) in dispatchQosClassOrder.enumerated() {
            if i > 0 {
                let qosClassesLessThanCurrent = dispatchQosClassOrder.prefix(i)
                for qosClass in qosClassesLessThanCurrent {
                    XCTAssertLessThan(qosClass, currentQoSClass)
                }
            }
            XCTAssertEqual(currentQoSClass, currentQoSClass)
            if i < dispatchQosClassOrder.count - 1 {
                let qosClassesGreaterThanCurrent = dispatchQosClassOrder.suffix(dispatchQosClassOrder.count - i - 1)
                for qosClass in qosClassesGreaterThanCurrent {
                    XCTAssertGreaterThan(qosClass, currentQoSClass)
                }
            }
        }
    }
}

class DispatchQoSTests: XCTestCase {

    func test_dispatchqos_comparable() {
        for (i, currentQoSClass) in dispatchQosClassOrder.enumerated() {
            if i > 0 {
                let qosClassesLessThanCurrent = dispatchQosClassOrder.prefix(i)
                for qosClass in qosClassesLessThanCurrent {
                    XCTAssertLessThan(DispatchQoS(qosClass: qosClass, relativePriority: 0), DispatchQoS(qosClass: currentQoSClass, relativePriority: 0))
                }
            }
            XCTAssertLessThan(DispatchQoS(qosClass: currentQoSClass, relativePriority: 0), DispatchQoS(qosClass: currentQoSClass, relativePriority: 1))
            XCTAssertEqual(DispatchQoS(qosClass: currentQoSClass, relativePriority: 0), DispatchQoS(qosClass: currentQoSClass, relativePriority: 0))
            XCTAssertGreaterThan(DispatchQoS(qosClass: currentQoSClass, relativePriority: 1), DispatchQoS(qosClass: currentQoSClass, relativePriority: 0))
            if i < dispatchQosClassOrder.count - 1 {
                let qosClassesGreaterThanCurrent = dispatchQosClassOrder.suffix(dispatchQosClassOrder.count - i - 1)
                for qosClass in qosClassesGreaterThanCurrent {
                    XCTAssertGreaterThan(DispatchQoS(qosClass: qosClass, relativePriority: 0), DispatchQoS(qosClass: currentQoSClass, relativePriority: 0))
                }
            }
        }
    }
}
