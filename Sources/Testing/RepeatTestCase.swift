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
}
