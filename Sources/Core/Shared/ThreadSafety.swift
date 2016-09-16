//
//  ThreadSafety.swift
//  Operations
//
//  Created by Daniel Thorpe on 14/02/2016.
//
//

import Foundation

protocol ReadWriteLock {
    mutating func read<T>(block: () -> T) -> T
    mutating func write(block: () -> Void, completion: (() -> Void)?)
}

extension ReadWriteLock {

    mutating func write(block: () -> Void) {
        write(block, completion: nil)
    }
}

struct Lock: ReadWriteLock {

    let queue = Queue.Initiated.concurrent("me.danthorpe.Operations.Lock")

    mutating func read<T>(block: () -> T) -> T {
        var object: T!
        Dispatch.dispatch_sync(queue) {
            object = block()
        }
        return object
    }

    mutating func write(block: () -> Void, completion: (() -> Void)?) {
        dispatch_barrier_async(queue) {
            block()
            if let completion = completion {
                dispatch_async(Queue.Main.queue, completion)
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

    func read<U>(block: T -> U) -> U {
        return lock.read { [unowned self] in block(self.ward) }
    }

    func write(block: (inout T) -> Void) {
        lock.write({ block(&self.ward) })
    }

    func write(block: (inout T) -> Void, completion: (() -> Void)) {
        lock.write({ block(&self.ward) }, completion: completion)
    }
}

extension Protector where T: _ArrayType {

    func append(newElement: T.Generator.Element) {
        write({ (inout ward: T) in
            ward.append(newElement)
        })
    }

    func appendContentsOf<S: SequenceType where S.Generator.Element == T.Generator.Element>(newElements: S) {
        write({ (inout ward: T) in
            ward.appendContentsOf(newElements)
        })
    }
}

public func dispatch_sync(queue: dispatch_queue_t, _ block: () throws -> Void) rethrows {
    var failure: ErrorType? = .None

    let catcher = {
        do {
            try block()
        }
        catch {
            failure = error
        }
    }

    Dispatch.dispatch_sync(queue, catcher)

    if let failure = failure {
        try { throw failure }()
    }
}

public func dispatch_sync<T>(queue: dispatch_queue_t, _ block: () throws -> T) rethrows -> T {
    var result: T!
    try dispatch_sync(queue) {
        result = try block()
    }
    return result
}

internal func dispatch_main_sync<T>(block: () throws -> T) rethrows -> T {
    guard Queue.isMainQueue else {
        return try dispatch_sync(Queue.Main.queue, block)
    }
    return try block()
}
