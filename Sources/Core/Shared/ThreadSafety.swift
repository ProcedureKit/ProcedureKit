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
        return queue.sync(execute: block)
    }

    mutating func write(_ block: () -> Void, completion: (() -> Void)?) {
		queue.async(flags: .barrier) {
            block()
            if let completion = completion {
                Queue.main.queue.async(execute: completion)
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
