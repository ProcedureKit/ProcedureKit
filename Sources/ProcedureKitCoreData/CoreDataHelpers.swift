//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
import ProcedureKit
import Foundation
#endif

import CoreData

// MARK: - Internal Core Data Helpers

internal extension NSManagedObject {

    static var entityName: String {
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            return entity().name ?? description()
        }
        else {
            return description()
        }
    }
}


internal extension NSManagedObjectContext {

    typealias VoidBlock = () -> Void
    typealias VoidBlockBlock = (VoidBlock) -> Void

    /// - see: https://oleb.net/blog/2018/02/performandwait/
    func performAndWait<T>(block: () throws -> T) rethrows -> T {

        func _helper(fn: VoidBlockBlock, execute work: () throws -> T, rescue: ((Error) throws -> (T))) rethrows -> T {
            var r: T?
            var e: Error?

            withoutActuallyEscaping(work) { _work in
                fn {
                    do { r = try _work() }
                    catch { e = error }
                }
            }

            if let error = e {
                return try rescue(error)
            }
            guard let result = r else {
                fatalError("Failed to generate a result or throw error.")
            }
            return result
        }

        return try _helper(fn: performAndWait(_:), execute: block, rescue: { throw $0 })
    }
}
