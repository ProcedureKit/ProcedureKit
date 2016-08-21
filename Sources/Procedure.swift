//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol Procedure {

    var executing: Bool { get }

    var finished: Bool { get }

    var cancelled: Bool { get }

//    var errors: [Error] { get }

//    func willEnqueue()

//    func execute()

//    func cancel()

//    func cancel(withError: Error?)

//    func cancel(withErrors: [Error])

    func add(observer: ProcedureObserver)
}
