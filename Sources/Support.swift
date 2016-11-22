//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

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

public class Protector<T> {

    private var lock = Lock()
    private var ward: T

    public init(_ ward: T) {
        self.ward = ward
    }

    public var access: T {
        return read { $0 }
    }

    public func read<U>(_ block: @escaping (T) -> U) -> U {
        return lock.read { [unowned self] in block(self.ward) }
    }

    public func write(_ block: @escaping (inout T) -> Void) {
        lock.write({ block(&self.ward) })
    }

    /// Synchronously modify the protected value
    ///
    /// - Returns: The value returned by the `block`, if any. (discardable)
    @discardableResult public func write<U>(_ block: (inout T) -> U) -> U {
        return lock.write_sync({ block(&self.ward) })
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
