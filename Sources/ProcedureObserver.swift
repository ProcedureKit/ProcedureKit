//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses to receive
 events at state transitions.
 */
public protocol ProcedureObserver {

    /**
     Observer gets notified when it is attached to a procedure.

     - parameter procedure: the observed `Procedure`.
     */
    func didAttachTo(procedure: Procedure)
}

public extension ProcedureObserver {

    /**
     Default implementation does nothing.

     - parameter procedure: the observed `Procedure`.
     */
    func didAttachTo(procedure: Procedure) { }
}
