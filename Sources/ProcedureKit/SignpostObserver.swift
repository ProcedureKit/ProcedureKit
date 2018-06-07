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
        os_log("Will begin signpost for -> Procedure name: %{public}s, is group: %{public}hhd, is child: %{public}hhd", log: log, type: .default, procedure.procedureName, procedure.isGroup.intValue, procedure.isChild.intValue)
        os_signpost(
            type: .begin,
            log: log,
            name: "Execution",
            signpostID: signpostID(for: procedure),
            "Procedure name: %{public}s,id: %{public}s,is group: %{public}hhd,parent id: %{public}s", procedure.procedureName, procedure.identifier.uuidString, procedure.isGroup.intValue, procedure.parentIdentifier?.uuidString ?? "")
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        os_log("Will end signpost for %s", log: log, type: .default, procedure.procedureName as CVarArg)
        os_signpost(
            type: .end,
            log: log,
            name: "Execution",
            signpostID: signpostID(for: procedure),
            "Procedure name: %{public}s, status: %{public}s", procedure.procedureName, procedure.status.rawValue)
    }
}

extension Bool {

    var intValue: Int {
        return NSNumber(booleanLiteral: self).intValue
    }
}
