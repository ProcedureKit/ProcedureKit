//
//  Repeatable.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/03/2016.
//
//

import Foundation


/**

 ### Repeatable

 `Repeatable` is a very simple protocol, which your `NSOperation` subclasses
 can conform to. This allows the previous operation to define whether a new
 one should be executed. For this special case, `RepeatedOperation` can be
 initialized like this:

 ```swift
 let operation = RepeatedOperation { MyRepeatableOperation() }
 ```

 - see: RepeatedOperation
 */
public protocol Repeatable {

    /**
     Implement this funtion to return true if a new
     instance should be added to a RepeatedOperation.

     - parameter count: the number of instances already executed within
     the RepeatedOperation.
     - returns: a Bool, false will end the RepeatedOperation.
     */
    func shouldRepeat(_ count: Int) -> Bool
}

public class RepeatableGenerator<G: IteratorProtocol where G.Element: Repeatable>: IteratorProtocol {

    private var generator: G
    private var count: Int = 0
    private var current: G.Element?

    public init(_ generator: G) {
        self.generator = generator
    }

    public func next() -> G.Element? {
        if let current = current {
            guard current.shouldRepeat(count) else {
                return nil
            }
        }
        current = generator.next()
        count += 1
        return current
    }
}

extension RepeatedOperation where T: Repeatable {

    /**
     Initialize a RepeatedOperation using a closure with NSOperation subclasses
     which conform to Repeatable. This is the neatest initializer.

     ```swift
     let operation = RepeatedOperation { MyRepeatableOperation() }
     ```
     */
    public convenience init(maxCount max: Int? = .none, strategy: WaitStrategy = .fixed(0.1), body: () -> T?) {
        self.init(maxCount: max, strategy: strategy, generator: RepeatableGenerator(AnyIterator(body)))
    }
}

/**
 RepeatableOperation is an OldOperation subclass which conforms to Repeatable.

 It can be used to make an otherwise non-repeatable OldOperation repeatable. It
 does this by accepting, in addition to the operation instance, a closure
 shouldRepeat. This closure can be used to capture state (such as errors).

 When conforming to Repeatable, the closure is executed, passing in the
 current repeat count.
 */
public class RepeatableOperation<T: OldOperation>: OldOperation, OperationDidFinishObserver, Repeatable {

    let operation: T
    let shouldRepeatBlock: (Int) -> Bool

    /**
     Initialize the RepeatableOperation with an operation and
     shouldRepeat closure.

     - parameter [unnamed] operation: the operation instance.
     - parameter shouldRepeat: a closure of type Int -> Bool
     */
    public init(_ operation: T, shouldRepeat: (Int) -> Bool) {
        self.operation = operation
        self.shouldRepeatBlock = shouldRepeat
        super.init()
        name = "Repeatable<\(operation.operationName)>"
        addObserver(DidCancelObserver { [weak operation] _ in
            (operation as? OldOperation)?.cancel()
        })
    }

    /// Override implementation of execute
    public override func execute() {
        if !isCancelled {
            operation.addObserver(self)
            produceOperation(operation)
        }
    }

    /// Implementation for Repeatable
    public func shouldRepeat(_ count: Int) -> Bool {
        return shouldRepeatBlock(count)
    }

    /// Implementation for OperationDidFinishObserver
    public func didFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        if self.operation == operation {
            finish(errors)
        }
    }
}
