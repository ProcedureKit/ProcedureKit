//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class RepeatTestCase: ProcedureKitTestCase {
    public var repeatProcedure: RepeatProcedure<TestProcedure>!

    public func createIterator(withDelay delay: Delay = .by(0.001)) -> AnyIterator<RepeatProcedurePayload<TestProcedure>> {
        return AnyIterator { RepeatProcedurePayload(operation: TestProcedure(), delay: .by(0.01)) }
    }

    public func createIterator(succeedsAfterCount target: Int) -> AnyIterator<TestProcedure> {
        var count = 0
        return AnyIterator {
            guard count < target else { return nil }
            defer { count += 1 }
            if count < target - 1 {
                return TestProcedure(error: TestError())
            }
            else {
                return TestProcedure()
            }
        }
    }
}

open class RetryTestCase: ProcedureKitTestCase {
    public typealias Test = TestProcedure
    public typealias Retry = RetryProcedure<TestProcedure>
    public typealias Handler = Retry.Handler

    public class RetryTestCaseInfo {
        public var numberOfExecuctions: Int = 0
        public var numberOfFailures: Int = 0
    }

    public var retry: Retry!

    public func createOperationIterator(succeedsAfterFailureCount failureThreshold: Int) -> AnyIterator<Test> {
        let info = RetryTestCaseInfo()
        return AnyIterator {
            let procedure = TestProcedure()
            procedure.add(condition: BlockCondition {
                guard info.numberOfFailures == failureThreshold else { throw ProcedureKitError.conditionFailed() }
                return true
            })
            procedure.addWillFinishBlockObserver { _, _, _ in
                info.numberOfExecuctions += 1
                info.numberOfFailures += 1
            }
            return procedure
        }
    }

    public func createPayloadIterator(succeedsAfterFailureCount failureThreshold: Int) -> AnyIterator<RepeatProcedurePayload<Test>> {
        let info = RetryTestCaseInfo()
        return AnyIterator {
            let procedure = TestProcedure()
            procedure.add(condition: BlockCondition {
                guard info.numberOfFailures == failureThreshold else { throw ProcedureKitError.conditionFailed() }
                return true
            })
            procedure.addWillFinishBlockObserver { _, _, _ in
                info.numberOfExecuctions += 1
                info.numberOfFailures += 1
            }
            return RepeatProcedurePayload(operation: procedure, delay: .by(0.0001))
        }
    }
}
