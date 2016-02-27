//
//  RepeatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

func arc4random<T: IntegerLiteralConvertible>(type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, Int(sizeof(T)))
    return r
}

/**
 Random Failure Generator
 
 This generator will randomly return nil (instead of the
 composed generator's `next()`) according to the probability
 of failure argument.
 
 For example, to simulate 1% failure rate:
 
 ```swift
 let one = RandomFailGenerator(generator, probability: 0.01)
 ```
*/
public struct RandomFailGenerator<G: GeneratorType>: GeneratorType {

    private var generator: G
    private let shouldNotFail: () -> Bool

    /**
     Initialize the generator with another generator and expected 
     probabilty of failure.
     
     - parameter: the generator
     - parameter probability: the expected probability of failure, defaults to 0.1, or 10%
    */
    public init(_ generator: G, probability: Double = 0.1) {
        self.generator = generator
        self.shouldNotFail = {
            let r = (Double(arc4random(UInt64)) / Double(UInt64.max))
            return r > probability
        }
    }

    /// GeneratorType implementation
    public mutating func next() -> G.Element? {
        guard shouldNotFail() else {
            return nil
        }
        return generator.next()
    }
}

struct FibonacciGenerator: GeneratorType {
    var currentValue = 0, nextValue = 1

    mutating func next() -> Int? {
        let result = currentValue
        currentValue = nextValue
        nextValue += result
        return result
    }
}

struct FiniteGenerator<G: GeneratorType>: GeneratorType {

    private let limit: Int
    private var generator: G

    var count: Int = 0

    init(_ generator: G, limit: Int = 10) {
        self.generator = generator
        self.limit = limit
    }

    mutating func next() -> G.Element? {
        guard count < limit else {
            return nil
        }
        count += 1
        return generator.next()
    }
}

struct MapGenerator<G: GeneratorType, T>: GeneratorType {
    private let transform: G.Element -> T
    private var generator: G


    init(_ generator: G, transform: G.Element -> T) {
        self.generator = generator
        self.transform = transform
    }

    mutating func next() -> T? {
        return generator.next().map(transform)
    }
}

struct TupleGenerator<Primary: GeneratorType, Secondary: GeneratorType>: GeneratorType {

    private var primary: Primary
    private var secondary: Secondary

    init(primary: Primary, secondary: Secondary) {
        self.primary = primary
        self.secondary = secondary
    }

    mutating func next() -> (Secondary.Element?, Primary.Element)? {
        return primary.next().map { ( secondary.next(), $0) }
    }
}

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

struct IntervalGenerator: GeneratorType {

    let strategy: WaitStrategy

    private var count: Int = 0
    private lazy var fibonacci = FibonacciGenerator()

    init(_ strategy: WaitStrategy) {
        self.strategy = strategy
    }

    mutating func next() -> NSTimeInterval? {
        switch strategy {

        case .Fixed(let period):
            return period

        case .Random(let (minimum, maximum)):
            let r = Double(arc4random(UInt64)) / Double(UInt64.max)
            return (r * (maximum - minimum)) + minimum

        case .Incrementing(let (initial, increment)):
            let interval = initial + (NSTimeInterval(count) * increment)
            count += 1
            return max(0, interval)

        case .Exponential(let (period, maximum)):
            let interval = period * pow(2.0, Double(count))
            count += 1
            return max(0, min(maximum, interval))

        case .Fibonacci(let (period, maximum)):
            return fibonacci.next().map { fib in
                let interval = period * NSTimeInterval(fib)
                return max(0, min(maximum, interval))
            }
        }
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
        return max.map { anyGenerator(FiniteGenerator(gen, limit: $0 - 1)) } ?? gen
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
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: anyGenerator(tuple))

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
        generator = RepeatedOperation<T>.createPayloadGeneratorWithMaxCount(max, generator: anyGenerator(tuple))
        
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
        configure = { op in
            config(op)
            block(op)
        }
    }
}

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
    func shouldRepeat(count: Int) -> Bool
}

public class RepeatableGenerator<G: GeneratorType where G.Element: Repeatable>: GeneratorType {

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
    public convenience init(maxCount max: Int? = .None, strategy: WaitStrategy = .Fixed(0.1), body: () -> T?) {
        self.init(maxCount: max, strategy: strategy, generator: RepeatableGenerator(anyGenerator(body)))
    }
}

/**
 RepeatableOperation is an Operation subclass which conforms to Repeatable.
 
 It can be used to make an otherwise non-repeatable Operation repeatable. It
 does this by accepting, in addition to the operation instance, a closure
 shouldRepeat. This closure can be used to capture state (such as errors).
 
 When conforming to Repeatable, the closure is executed, passing in the 
 current repeat count.
*/
public class RepeatableOperation<T: Operation>: Operation, OperationDidFinishObserver, Repeatable {

    let operation: T
    let shouldRepeatBlock: Int -> Bool

    /**
     Initialize the RepeatableOperation with an operation and
     shouldRepeat closure.
     
     - parameter [unnamed] operation: the operation instance.
     - parameter shouldRepeat: a closure of type Int -> Bool
    */
    public init(_ operation: T, shouldRepeat: Int -> Bool) {
        self.operation = operation
        self.shouldRepeatBlock = shouldRepeat
        super.init()
        name = "Repeatable<\(operation.operationName)>"
        addObserver(CancelledObserver { [weak operation] _ in
            (operation as? Operation)?.cancel()
        })
    }

    /// Override implementation of execute
    public override func execute() {
        if !cancelled {
            operation.addObserver(self)
            produceOperation(operation)
        }
    }

    /// Implementation for Repeatable
    public func shouldRepeat(count: Int) -> Bool {
        return shouldRepeatBlock(count)
    }

    /// Implementation for OperationDidFinishObserver
    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        if self.operation == operation {
            finish(errors)
        }
    }
}

