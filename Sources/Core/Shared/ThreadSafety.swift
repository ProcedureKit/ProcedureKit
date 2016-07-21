//
//  ThreadSafety.swift
//  Operations
//
//  Created by Daniel Thorpe on 14/02/2016.
//
//

import Foundation

protocol ReadWriteLock {
    mutating func read<T>(_ block: () -> T) -> T
    mutating func write(_ block: () -> Void, completion: (() -> Void)?)
}

extension ReadWriteLock {

    mutating func write(_ block: () -> Void) {
        write(block, completion: nil)
    }
}

struct Lock: ReadWriteLock {

    let queue = Queue.initiated.concurrent("me.danthorpe.Operations.Lock")

    mutating func read<T>(_ block: () -> T) -> T {
        var object: T!
        queue.sync {
            object = block()
        }
        return object
    }

    mutating func write(_ block: () -> Void, completion: (() -> Void)?) {
        queue.async(flags: .barrier, execute: {
            block()
            if let completion = completion {
                Queue.main.queue.async(execute: completion)
            }
        })
    }
}

internal class Protector<T> {

    private var lock: ReadWriteLock = Lock()
    private var ward: T

    init(_ ward: T) {
        self.ward = ward
    }

    func read<U>(_ block: (T) -> U) -> U {
        return lock.read { [unowned self] in block(self.ward) }
    }

    func write(_ block: (inout T) -> Void) {
        lock.write({ block(&self.ward) })
    }

    func write(_ block: (inout T) -> Void, completion: (() -> Void)) {
        lock.write({ block(&self.ward) }, completion: completion)
    }
}

extension Protector where T: RangeReplaceableCollection {

    func append(_ newElement: T.Iterator.Element) {
        write({ (ward: inout T) in
            ward.append(newElement)
        })
    }

    func appendContentsOf<S: Sequence where S.Iterator.Element == T.Iterator.Element>(_ newElements: S) {
        write({ (ward: inout T) in
            ward.append(contentsOf: newElements)
        })
    }
}

public func dispatch_sync(queue: DispatchQueue, _ block: () throws -> Void) rethrows {
    var failure: ErrorProtocol? = .none

    let catcher = {
        do {
            try block()
        }
        catch {
            failure = error
        }
    }

    queue.sync(execute: catcher)

    if let failure = failure {
        try { throw failure }()
    }
}

public func dispatch_sync<T>(queue: DispatchQueue, _ block: () throws -> T) rethrows -> T {
    var result: T!
    try queue.sync {
        result = try block()
    }
    return result
}

internal func dispatch_main_sync<T>(block: () throws -> T) rethrows -> T {
    guard Queue.isMainQueue else {
        return try DispatchQueue.main.sync(execute: block) //dispatch_sync(Queue.main.queue, block)
    }
    return try block()
}
