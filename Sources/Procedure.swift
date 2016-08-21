//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol Procedure {

    var isExecuting: Bool { get }

    var isFinished: Bool { get }

    var isCancelled: Bool { get }

//    var errors: [Error] { get }

    func willEnqueue()

    func execute()

//    func cancel()

//    func cancel(withError: Error?)

//    func cancel(withErrors: [Error])

    func finish(withErrors: [Error])

    func add(observer: ProcedureObserver)
}
