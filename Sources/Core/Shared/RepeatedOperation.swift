//
//  RepeatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

/**
 Define a strategy for waiting a given time interval. The strategy
 can then create a NSTimeInterval generator. The strategies are:

 ### Fixed
 The fixed strategy is initialized with a time interval. Every
 interval is this value.
 - Requires: time interval must be greater than zero

 ### Random
 The random strategy is initialized with minimum and maximum
 bounds. These are both NSTimeInterval values. Each value from
 the generator is a random interval between these bounds.
 - requires: minimum time interval must be greater than or equal to zero
 - requires: maximum time interval must be greater than the minimum

 ### Incrementing
 The incrementing strategy is initialized with an starting or
 initial interval, and an increment value. Each value adds the
 increment to the previous value.
 - requires: initial time interval must be greater than or equal to zero.
 - notes: a decrementing strategy can be created with a large initial
    value and negative increments. The value will never be less than
    zero however.

 ### Exponential
 The exponential strategy is initialized with a time period, and
 a maximum value. Successive value of the generator multiply the
 period by an exponentially increasing factors, but not past the
 maximum.
 - requires: time period must be greater than or equal to zero
 - requires: maximum time interval must be greater than zero
 - requires: time period must be less than maxium
 ### Fibonacci
 Like the exponential strategy except the period is multipled by
 the Fibonacci numbers instead.
 - requires: time period must be greater than or equal to zero
 - requires: maximum time interval must be greater than zero
 - requires: time period must be less than maxium

*/
public enum WaitStrategy {

    case Fixed(NSTimeInterval)
    case Random((minimum: NSTimeInterval, maximum: NSTimeInterval))
    case Incrementing((initial: NSTimeInterval, increment: NSTimeInterval))
    case Exponential((period: NSTimeInterval, maximum: NSTimeInterval))
    case Fibonacci((period: NSTimeInterval, maximum: NSTimeInterval))

    internal func generator() -> IntervalGenerator {
        return IntervalGenerator(self)
    }
}

/**

 ### RepeatedOperation

 RepeatedOperation is an GroupOperation subclass which can be used in
 conjunction with a GeneratorType to schedule NSOperation subclasses of
 the same type on a private queue.

 This is useful directly for periodically running idempotent operations,
 and it forms the basis for operations types which can be retried in the
 event of a failure.

 The operations may optionally be scheduled after a delay has passed, or
 a date in the future has been reached.

 At the lowest level, which offers the most flexibility, RepeatedOperation
 is initialized with a generator. The generator (something conforming to
 GeneratorType) element type is (Delay?, T), where T is a NSOperation
 subclass, and Delay is an enum used in conjunction with DelayOperation.

 For example:

 ```swift
 let operation = RepeatedOperation(anyGenerator {
     return (.By(0.1), MyOperation())
 })
 ```

 The operation is a `GroupOperation` subclass which works by adding
 new instances of the operation to its group. This happens initially
 when the group starts, and then again when the child operation finishes.

 There are two ways to stop the operations from repeating.

 1. Return `nil` from the generator passed to the initializer
 2. Set the 1st argument, `maxCount` to a the number of times an
     operation will be executed (i.e. it includes the initial
     operation). The value defaults to .None which indicates repeating
     forever.

 Convenience initializers support the combination of a simple () -> T?
 block with standard wait strategies. See WaitStrategy for more information.

 For example, to use exponential back-off, with a maximum of 10 attempts:

 ```swift
 let operation = RepeatedOperation(maxCounts: 10,
     strategy: .Exponential((minimum: 1, maximum: 300)),
     anyGenerator {
         MyOperation()
     }
 )
 ```

 Note that in this case, the generator supplied only needs to return the
 operation instead of a tuple.

 - See: Wait
 - See: Repeatable

*/
public class RepeatedOperation<T where T: NSOperation>: GroupOperation {
    public typealias Payload = (Delay?, T)

    private var generator: AnyGenerator<Payload>

    /// - returns: the current operation being executed.
    public internal(set) var current: T

    /// - return: the count of operations that have executed.
    public internal(set) var count: Int = 1

    internal private(set) var configure: T -> Void = { _ in }

    static func createPayloadGeneratorWithMaxCount(max: Int? = .None, generator gen: AnyGenerator<Payload>) -> AnyGenerator<Payload> {
        return max.map { AnyGenerator(FiniteGenerator(gen, limit: $0 - 1)) } ?? gen
    }

    /**
     The most basic initializer.

     - parameter maxCount: an optional Int, which defaults to .None. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter generator: the AnyGenerator<(Delay?, T)> generator.
    */
    public init(maxCount max: Int? = .None, generator gen: AnyGenerator<Payload>) {

        guard let (_, operation) = gen.next() else {
            preconditionFailure("Operation Generator must return an instance initially.")
        }

        current = operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: gen)

        super.init(operations: [])
        name = "Repeated Operation <\(T.self)>"
    }

    /**
     An initializer, which accepts two generators, one for the delay and another for
     the operation.

     - parameter maxCount: an optional Int, which defaults to .None. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter delay: a generator with Delay element.
     - parameter generator: a generator with T element.
     */
    public init<D, G where D: GeneratorType, D.Element == Delay, G: GeneratorType, G.Element == T>(maxCount max: Int? = .None, delay: D, generator gen: G) {

        var tuple = TupleGenerator(primary: gen, secondary: delay)

        guard let (_, operation) = tuple.next() else {
            preconditionFailure("Operation Generator must return an instance initially.")
        }

        current = operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: AnyGenerator(tuple))

        super.init(operations: [])
        name = "Repeated Operation <\(T.self)>"
    }

    /**
     An initializer with wait strategy and generic operation generator.
     This is useful where another system can be responsible for vending instances of
     the custom operation. Typically there may be some state involved in such a Generator. e.g.

     ```swift
     class MyOperationGenerator: GeneratorType {
         func next() -> MyOperation? {
             // etc
         }
     }

     let operation = RepeatedOperation(generator: MyOperationGenerator())
     ```

     The wait strategy is useful if say, you want to repeat the operations with random
     delays, or exponential backoff. These standard schemes and be easily expressed.

     ```swift
     let operation = RepeatedOperation(
         strategy: .Random((0.1, 1.0)),
         generator: MyOperationGenerator()
     )
     ```

     - parameter maxCount: an optional Int, which defaults to .None. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter strategy: a WaitStrategy which defaults to a 0.1 second fixed interval.
     - parameter generator: a generic generator which has an Element equal to T.
     */
    public init<G where G: GeneratorType, G.Element == T>(maxCount max: Int? = .None, strategy: WaitStrategy = .Fixed(0.1), generator gen: G) {

        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }
        var tuple = TupleGenerator(primary: gen, secondary: delay)

        guard let (_, operation) = tuple.next() else {
            preconditionFailure("Operation Generator must return an instance initially.")
        }

        current = operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: AnyGenerator(tuple))

        super.init(operations: [])
        name = "Repeated Operation <\(T.self)>"
    }

    /// Public override of execute which configures and adds the first operation
    public override func execute() {
        configure(current)
        addOperation(current)
        super.execute()
    }

    /**
     Override of operationDidFinish: withErrors:

     This function ignores errors, and cases where the operation
     is a `DelayOperation`. If the operation is an instance of `T`
     it calls `addNextOperation()`.

     When subclassing, be very careful if downcasting `T` to
     say `Operation` instead of `MyOperation` (i.e. your specific
     operation which should be repeated).
    */
    public override func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        if let _ = operation as? DelayOperation { return }
        if let _ = operation as? T {
            addNextOperation()
        }
    }

    /**
     Adds another instance of the operation to the group.

     This function will call `next()` on the generator, setting
     the `operation` parameter. If the operation is not nil,
     it also will get the next delay operation, which may also
     be nil. If both operation & delay are not nil, the
     dependencies are setup, added to the group and the count is
     incremented.

     Subclasses which override, should almost certainly call
     super.

     - parameter shouldAddNext: closure which returns a Bool. Defaults
     to return true. Subclasses may inject additional logic here which
     can prevent another operation from being added.
    */
    public func addNextOperation(@autoclosure shouldAddNext: () -> Bool = true) {
        if let (delay, op) = next() {
            if shouldAddNext() {
                configure(op)
                if let delay = delay.map({ DelayOperation(delay: $0) }) {
                    op.addDependency(delay)
                    addOperations(delay, op)
                }
                else {
                    addOperation(op)
                }
                count += 1
                current = op
            }
        }
    }

    /**
     Returns the next operation from the generator. This is here to
     allow subclasses to override and configure the operation
     further before it is added.
    */
    public func next() -> Payload? {
        return generator.next()
    }

    /**
     Appends a configuration block to the current block. This
     can be used to configure every instance of the operation
     before it is added to the queue.

     Note that configuration block are executed in FIFO order,
     so it is possible to overwrite previous configurations.

     - parameter block: a block which receives an instance of T
    */
    public func addConfigureBlock(block: T -> Void) {
        let config = configure
        configure = { operation in
            config(operation)
            block(operation)
        }
    }
}
