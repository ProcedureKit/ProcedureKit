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

    case immediate
    case fixed(TimeInterval)
    case random((minimum: TimeInterval, maximum: TimeInterval))
    case incrementing((initial: TimeInterval, increment: TimeInterval))
    case exponential((period: TimeInterval, maximum: TimeInterval))
    case fibonacci((period: TimeInterval, maximum: TimeInterval))

    internal func generator() -> IntervalGenerator {
        return IntervalGenerator(self)
    }
}

public struct RepeatedPayload<T where T: Operation> {
    public typealias ConfigureBlock = (T) -> Void

    public let delay: Delay?
    public let operation: T
    public let configure: ConfigureBlock?
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
     operation). The value defaults to .none which indicates repeating
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
public class RepeatedOperation<T where T: Operation>: GroupOperation {
    public typealias Payload = RepeatedPayload<T>

    private var generator: AnyIterator<Payload>

    /// - returns: the previous operation which was executed.
    public internal(set) var previous: T? = .none

    /// - returns: the current operation being executed.
    public internal(set) var current: T

    /// - return: the count of operations that have executed.
    public internal(set) var count: Int = 1

    internal private(set) var configure: Payload.ConfigureBlock = { _ in }

    static func createPayloadGeneratorWithMaxCount(_ max: Int? = .none, generator gen: AnyIterator<Payload>) -> AnyIterator<Payload> {
        return max.map { AnyIterator(FiniteGenerator(gen, limit: $0 - 1)) } ?? gen
    }

    /**
     The most basic initializer.

     - parameter maxCount: an optional Int, which defaults to .none. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter generator: the AnyGenerator<(Delay?, T)> generator.
    */
    public init(maxCount max: Int? = .none, generator gen: AnyIterator<Payload>) {

        guard let payload = gen.next() else {
            preconditionFailure("Procedure Generator must return an instance initially.")
        }

        current = payload.operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: gen)

        super.init(operations: [])
        name = "Repeated Procedure <\(T.self)>"
    }

    /**
     An initializer, which accepts two generators, one for the delay and another for
     the operation.

     - parameter maxCount: an optional Int, which defaults to .none. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter delay: a generator with Delay element.
     - parameter generator: a generator with T element.
     */
    public init<D, G where D: IteratorProtocol, D.Element == Delay, G: IteratorProtocol, G.Element == T>(maxCount max: Int? = .none, delay: D, generator gen: G) {

        let tuple = TupleGenerator(primary: gen, secondary: delay)
        var mapped = MapGenerator(tuple) { RepeatedPayload(delay: $0.0, operation: $0.1, configure: .none) }

        guard let payload = mapped.next() else {
            preconditionFailure("Procedure Generator must return an instance initially.")
        }

        current = payload.operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: AnyIterator(mapped))

        super.init(operations: [])
        name = "Repeated Procedure <\(T.self)>"
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

     - parameter maxCount: an optional Int, which defaults to .none. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter strategy: a WaitStrategy which defaults to a 0.1 second fixed interval.
     - parameter generator: a generic generator which has an Element equal to T.
     */
    public init<G where G: IteratorProtocol, G.Element == T>(maxCount max: Int? = .none, strategy: WaitStrategy = .fixed(0.1), generator gen: G) {

        let delay = MapGenerator(strategy.generator()) { Delay.by($0) }
        let tuple = TupleGenerator(primary: gen, secondary: delay)
        var mapped = MapGenerator(tuple) { RepeatedPayload(delay: $0.0, operation: $0.1, configure: .none) }

        guard let payload = mapped.next() else {
            preconditionFailure("Procedure Generator must return an instance initially.")
        }

        current = payload.operation
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: AnyIterator(mapped))
        super.init(operations: [])
        name = "Repeated Procedure <\(T.self)>"
    }

    /// Public override of execute which configures and adds the first operation
    public override func execute() {
        configure(current)
        addOperation(current)
        super.execute()
    }

    /**
     Override of willFinishOperation

     This function ignores errors cases where the operation
     is a `DelayOperation`. If the operation is an instance of `T`
     it calls `addNextOperation()`.

     When subclassing, be very careful if downcasting `T` to
     say `Procedure` instead of `MyOperation` (i.e. your specific
     operation which should be repeated).
     */
    public override func willAttemptRecoveryFromErrors(_ errors: [ErrorProtocol], inOperation operation: Operation) -> Bool {
        addNextOperation(operation === current)
        return super.willAttemptRecoveryFromErrors(errors, inOperation: operation)
    }

    /**
     Override of willFinishOperation

     This function ignores cases where the operation
     is a `DelayOperation`. If the operation is an instance of `T`
     it calls `addNextOperation()`.

     When subclassing, be very careful if downcasting `T` to
     say `Procedure` instead of `MyOperation` (i.e. your specific
     operation which should be repeated).
    */
    public override func willFinishOperation(_ operation: Operation) {
        addNextOperation(operation === current)
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
    @discardableResult
    public func addNextOperation(_ shouldAddNext: @autoclosure () -> Bool = true) -> Bool {
        guard !isCancelled && shouldAddNext(), let payload = next() else { return false }

        log.verbose("will add next operation: \(payload.operation)")

        if let newConfigureBlock = payload.configure {
            replaceConfigureBlock(newConfigureBlock)
        }

        configure(payload.operation)
        if let delay = payload.delay.map({ DelayOperation(delay: $0) }) {
            payload.operation.addDependency(delay)
            addOperations(delay, payload.operation)
        }
        else {
            addOperation(payload.operation)
        }
        count += 1
        previous = current
        current = payload.operation

        return true
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
    public func addConfigureBlock(_ block: Payload.ConfigureBlock) {
        let config = configure
        configure = { operation in
            config(operation)
            block(operation)
        }
    }

    /**
     Replace the current configuration block

     - parameter block: a block which receives an instance of T
     */
    public func replaceConfigureBlock(_ block: Payload.ConfigureBlock) {
        configure = block
        log.verbose("did replace configure block.")
    }
}
