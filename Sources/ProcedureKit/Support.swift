//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

internal func _abstractMethod(file: StaticString = #file, line: UInt = #line) {
    fatalError("Method must be overriden", file: file, line: line)
}

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
    mutating func write_async(_ block: @escaping () -> Void, completion: (() -> Void)?)
    mutating func write_sync<T>(_ block: () throws -> T) rethrows -> T
}

extension ReadWriteLock {

    mutating func write_async(_ block: @escaping () -> Void) {
        write_async(block, completion: nil)
    }
}

struct Lock: ReadWriteLock {

    let queue = DispatchQueue.concurrent(label: "run.kit.procedure.ProcedureKit.Lock", qos: .userInitiated)

    mutating func read<T>(_ block: () throws -> T) rethrows -> T {
        return try queue.sync(execute: block)
    }

    mutating func write_async(_ block: @escaping () -> Void, completion: (() -> Void)?) {
        queue.async(group: nil, flags: [.barrier]) {
            block()
            if let completion = completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    mutating func write_sync<T>(_ block: () throws -> T) rethrows -> T {
        let result = try queue.sync(flags: [.barrier]) {
            try block()
        }
        return result
    }
}

/// A wrapper class for a pthread_mutex
final public class PThreadMutex {
    private var mutex = pthread_mutex_t()

    public init() {
        let result = pthread_mutex_init(&mutex, nil)
        precondition(result == 0, "Failed to create pthread mutex")
    }

    deinit {
        let result = pthread_mutex_destroy(&mutex)
        assert(result == 0, "Failed to destroy mutex")
    }

    fileprivate func lock() {
        let result = pthread_mutex_lock(&mutex)
        assert(result == 0, "Failed to lock mutex")
    }

    fileprivate func unlock() {
        let result = pthread_mutex_unlock(&mutex)
        assert(result == 0, "Failed to unlock mutex")
    }

    /// Convenience API to execute block after acquiring the lock
    ///
    /// - Parameter block: the block to run
    /// - Returns: returns the return value of the block
    public func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        defer { unlock() }
        let value = block()
        return value
    }
}

public class Protector<T> {

    private var lock = PThreadMutex()
    private var ward: T

    public init(_ ward: T) {
        self.ward = ward
    }

    public var access: T {
        var value: T?
        lock.lock()
        value = ward
        lock.unlock()
        return value!
    }

    public func read<U>(_ block: (T) -> U) -> U {
        return lock.withCriticalScope { block(self.ward) }
    }

    /// Synchronously modify the protected value
    ///
    /// - Returns: The value returned by the `block`, if any. (discardable)
    @discardableResult public func write<U>(_ block: (inout T) -> U) -> U {
        return lock.withCriticalScope { block(&self.ward) }
    }

    /// Synchronously overwrite the protected value
    public func overwrite(with newValue: T) {
        write { (ward: inout T) in ward = newValue }
    }
}

public extension Protector where T: RangeReplaceableCollection {

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

    func append<C: Collection>(contentsOf newElements: C) where C.Iterator.Element == T.Iterator.Element {
        write { (ward: inout T) in
            ward.append(contentsOf: newElements)
        }
    }
}

public extension Protector where T: Strideable {

    func advance(by stride: T.Stride) {
        write { (ward: inout T) in
            ward = ward.advanced(by: stride)
        }
    }
}

public extension NSLock {

    /// Convenience API to execute block after acquiring the lock
    ///
    /// - Parameter block: the block to run
    /// - Returns: returns the return value of the block
    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

public extension NSRecursiveLock {

    /// Convenience API to execute block after acquiring the lock
    ///
    /// - Parameter block: the block to run
    /// - Returns: returns the return value of the block
    func withCriticalScope<T>(block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
