//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

extension Dictionary {

    internal init<S: Sequence>(sequence: S, keyMapper: (Value) -> Key?) where S.Iterator.Element == Value {
        self.init()
        for item in sequence {
            if let key = keyMapper(item) {
                self[key] = item
            }
        }
    }
}

// MARK: - Thread Safety

protocol ReadWriteLock {
    mutating func read<T>(_ block: () throws -> T) rethrows -> T
    mutating func write(_ block: @escaping () -> Void, completion: (() -> Void)?)
}

extension ReadWriteLock {

    mutating func write(_ block: @escaping () -> Void) {
        write(block, completion: nil)
    }
}

struct Lock: ReadWriteLock {

    let queue = DispatchQueue.concurrent(label: "run.kit.procedure.ProcedureKit.Lock", qos: .userInitiated)

    mutating func read<T>(_ block: () throws -> T) rethrows -> T {
        return try queue.sync(execute: block)
    }

    mutating func write(_ block: @escaping () -> Void, completion: (() -> Void)?) {
        queue.async(group: nil, flags: [.barrier]) {
            block()
            if let completion = completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
}

internal class Protector<T> {

    private var lock: ReadWriteLock = Lock()
    private var ward: T

    init(_ ward: T) {
        self.ward = ward
    }

    func read<U>(_ block: @escaping (T) -> U) -> U {
        return lock.read { [unowned self] in block(self.ward) }
    }

    func write(_ block: @escaping (inout T) -> Void) {
        lock.write({ block(&self.ward) })
    }

    func write(_ block: @escaping (inout T) -> Void, completion: (() -> Void)) {
        lock.write({ block(&self.ward) }, completion: completion)
    }
}

internal extension Protector where T: RangeReplaceableCollection {

    func append(_ newElement: T.Iterator.Element) {
        write { (ward: inout T) in
            ward.append(newElement)
        }
    }

    func append<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == T.Iterator.Element {
        write { (ward: inout T) in
            ward.append(contentsOf: newElements)
        }
    }
}


internal extension NSLock {

    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

internal extension NSRecursiveLock {

    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
