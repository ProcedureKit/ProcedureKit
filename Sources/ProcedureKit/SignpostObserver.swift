//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import os

@available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *)
public final class SignpostObserver<Procedure: ProcedureProtocol> {

    public let log: OSLog

    public init(log: OSLog) {
        self.log = log
    }

    internal convenience init() {
        self.init(log: ProcedureKit.Signposts.procedure)
    }

    private func signpostID(for procedure: Procedure) -> OSSignpostID {
        return OSSignpostID(log: log, object: procedure)
    }
}

@available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *)
extension SignpostObserver: ProcedureObserver {

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        os_signpost(.begin, log: log, name: "Executing", signpostID: signpostID(for: procedure), "Procedure name: %{public}s", procedure.procedureName)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        os_signpost(.end, log: log, name: "Execution", signpostID: signpostID(for: procedure), "Procedure name: %{public}s, status: %{public}s", procedure.procedureName, procedure.status.rawValue)
    }
}
