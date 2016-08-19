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
    mutating func read<T>(_ block: () -> T) -> T
    mutating func write(_ block: () -> Void, completion: (() -> Void)?)
}

extension ReadWriteLock {

    mutating func write(_ block: () -> Void) {
        write(block, completion: nil)
    }
}

//struct Lock: ReadWriteLock {
//
//    let queue = Queue.Initiated.concurrent("me.danthorpe.Operations.Lock")
//
//    mutating func read<T>(_ block: () -> T) -> T {
//        var object: T!
//        Dispatch.dispatch_sync(queue) {
//            object = block()
//        }
//        return object
//    }
//
//    mutating func write(_ block: () -> Void, completion: (() -> Void)?) {
//        dispatch_barrier_async(queue) {
//            block()
//            if let completion = completion {
//                dispatch_async(Queue.Main.queue, completion)
//            }
//        }
//    }
//}

class Protector<T> {

//    private var lock: ReadWriteLock = Lock()
    private var ward: T

    init(_ ward: T) {
        self.ward = ward
    }

//    func read<U>(_ block: T -> U) -> U {
//        return lock.read { [unowned self] in block(self.ward) }
//    }
//
//    func write(_ block: (inout T) -> Void) {
//        lock.write({ block(&self.ward) })
//    }
//
//    func write(_ block: (inout T) -> Void, completion: (() -> Void)) {
//        lock.write({ block(&self.ward) }, completion: completion)
//    }
}

//extension Protector where T: _ArrayType {
//
//    func append(_ newElement: T.Generator.Element) {
//        write({ (inout ward: T) in
//            ward.append(newElement)
//        })
//    }
//
//    func appendContentsOf<S: SequenceType where S.Generator.Element == T.Generator.Element>(newElements: S) {
//        write({ (inout ward: T) in
//            ward.appendContentsOf(newElements)
//        })
//    }
//}


