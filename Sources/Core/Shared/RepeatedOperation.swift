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

struct FixedWaitGenerator: GeneratorType {
    let period: NSTimeInterval

    init(period: NSTimeInterval) {
        precondition(period >= 0, "The minimum must be greater than or equal to zero, but it is: \(period)")
        self.period = period
    }

    mutating func next() -> NSTimeInterval? {
        return period
    }
}

struct RandomWaitGenerator: GeneratorType {
    let minimum: NSTimeInterval
    let maximum: NSTimeInterval

    init(minimum: NSTimeInterval, maximum: NSTimeInterval) {
        precondition(minimum >= 0, "The minimum must be greater than or equal to zero, but it is: \(minimum)")
        precondition(maximum > minimum, "The maximum must be greater than minimum.")
        self.minimum = minimum
        self.maximum = maximum
    }

    mutating func next() -> NSTimeInterval? {
        let r = Double(arc4random(UInt64)) / Double(UInt64.max)
        return (r * (maximum - minimum)) + minimum
    }
}

struct IncrementingWaitGenerator: GeneratorType {
    let initial: NSTimeInterval
    let increment: NSTimeInterval
    var count: Int = 0

    init(initial: NSTimeInterval, increment: NSTimeInterval) {
        precondition(initial >= 0, "The initial must be greater than or equal to zero, but it is: \(initial)")
        self.initial = initial
        self.increment = increment
    }

    mutating func next() -> NSTimeInterval? {
        let interval = initial + (NSTimeInterval(count) * increment)
        count += 1
        return max(0, interval)
    }
}

struct ExponentialWaitGenerator: GeneratorType {
    let period: NSTimeInterval
    let maximum: NSTimeInterval
    var count: Int = 0

    init(period: NSTimeInterval, maximum: NSTimeInterval) {
        precondition(period >= 0, "The period must be greater than or equal to zero, but it is: \(period)")
        precondition(maximum > 0, "The maximum must be greater than zero, but it is: \(maximum)")
        precondition(period < maximum, "The period must be less than the maximum, but it period: \(period) and maximum: \(maximum)")
        self.period = period
        self.maximum = maximum
    }

    mutating func next() -> NSTimeInterval? {
        let interval = period * pow(2.0, Double(count))
        count += 1
        return max(0, min(maximum, interval))
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

struct FibonacciWaitGenerator: GeneratorType {
    let period: NSTimeInterval
    let maximum: NSTimeInterval

    private var fibonacci = FibonacciGenerator()

    init(period: NSTimeInterval, maximum: NSTimeInterval) {
        precondition(period >= 0, "The period must be greater than or equal to zero, but it is: \(period)")
        precondition(maximum > 0, "The maximum must be greater than zero, but it is: \(maximum)")
        precondition(period < maximum, "The period must be less than the maximum, but it period: \(period) and maximum: \(maximum)")
        self.period = period
        self.maximum = maximum
    }

    mutating func next() -> NSTimeInterval? {
        return fibonacci.next().map { fib in
            let interval = period * NSTimeInterval(fib)
            return max(0, min(maximum, interval))
        }
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

    /**
     Returns a new generator using the strategy.
     - returns: a `AnyGenerator<NSTimeInterval>` instance.
    */
    public func generate() -> AnyGenerator<NSTimeInterval> {
        switch self {
        case .Fixed(let period):
            return anyGenerator(FixedWaitGenerator(period: period))
        case .Random(let (minimum, maximum)):
            return anyGenerator(RandomWaitGenerator(minimum: minimum, maximum: maximum))
        case .Incrementing(let (initial, increment)):
            return anyGenerator(IncrementingWaitGenerator(initial: initial, increment: increment))
        case .Exponential(let (period, maximum)):
            return anyGenerator(ExponentialWaitGenerator(period: period, maximum: maximum))
        case .Fibonacci(let (period, maximum)):
            return anyGenerator(FibonacciWaitGenerator(period: period, maximum: maximum))
        }
    }
}

/**

 ### RepeatedOperation

 This operation must be initialized with a generator which has an
 element which subclasses `NSOperation`. e.g.

 ```swift
 let operation = RepeatedOperation(anyGenerator { 
     return MyOperation() 
 })
 ```

 The operation is a `GroupOperation` subclass which works by adding 
 new instances of the operation to its group. This happens initially 
 when the group starts, and then again when the child operation finishes.

 After the initial child operation completes, new operations are 
 added with a delay on the queue. The time interval of the delay 
 can be configured via the first argument to the `RepeatedOperation`.

 There are two ways to stop the operations from repeating.

 1. Return `nil` from the generator passed to the initializer
 2. Set the 2nd argument, `maxNumberOfAttempts` which is an 
    optional `Int` defaulting to `.None`.

 The first argument is a `WaitStrategy` which is an enum of various 
 different mechanisms for defining waiting. See WaitStrategy for more.

 For example, to use exponential back-off, with a maximum of 10 attempts:

 ```swift
 let operation = RepeatedOperation(
     strategy: .Exponential((minimum: 1, maximum: 300)), 
     maxNumberOfAttempts: 10, 
     anyGenerator {
         MyOperation()
     }
 )
 ```

 - See: Wait
 - See: Repeatable

*/
public class RepeatedOperation<T where T: NSOperation>: GroupOperation {

    private var delay: AnyGenerator<NSTimeInterval>
    private var generator: AnyGenerator<T>

    /// - returns: the current operation being executed.
    public internal(set) var operation: T? = .None

    /// - return: the count of operations that have executed.
    public private(set) var count: Int = 0

    /**
     The designated initializer.
     
     - parameter delay: a generator of NSTimeInterval values
     - parameter maxCount: an optional Int, which defaults to .None. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter: (unnamed) the AnyGenerator<T> generator.
    */
    public init<D, G where D: GeneratorType, D.Element == NSTimeInterval, G: GeneratorType, G.Element == T>(delay: D, maxCount max: Int?, generator gen: G) {
        generator = gen as? AnyGenerator<T> ?? anyGenerator(gen)

        switch max {
        case .Some(let max):
            // Subtract 1 to account for the 1st attempt
            self.delay = anyGenerator(FiniteGenerator(delay, limit: max - 1))
        case .None:
            self.delay = anyGenerator(delay)
        }

        super.init(operations: [])
        name = "Repeated Operation"
    }

    /**
     A convenience initializer with generic generator. This is useful where another
     system can be responsible for vending instances of the custom operation. Typically
     there may be some state involved in such a Generator. e.g.
     
     ```swift
     class MyOperationGenerator: GeneratorType {
         func next() -> MyOperation? {
             // etc
         }
     }
     
     let operation = RepeatedOperation(MyOperationGenerator())
     ```

     - parameter strategy: a WaitStrategy which defaults to a 0.1 second fixed interval.
     - parameter maxCount: an optional Int, which defaults to .None. If not nil, this is
     the maximum number of operations which will be executed.
     - parameter: (unnamed) a generic generator which has an Element equal to T.
     */
    public convenience init<G where G: GeneratorType, G.Element == T>(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = .None, generator: G) {
        self.init(delay: strategy.generate(), maxCount: max, generator: generator)
    }

    /// Override of execute, subclasses which override this must call super.
    public override func execute() {
        addNextOperation()
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
    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
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
        if let op = next(), delay = nextDelayOperation() {
            if shouldAddNext() {
                op.addDependency(delay)
                addOperations(delay, op)
                count += 1
                operation = op
            }
        }
    }

    /**
     Returns the next operation from the generator. This is here to
     allow subclasses to override and configure the operation
     further before it is added.
    */
    public func next() -> T? {
        return generator.next()
    }

    internal func nextDelayOperation() -> DelayOperation? {
        return delay.next().map { DelayOperation(interval: $0) }
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

class RepeatingGenerator<G: GeneratorType where G.Element: Repeatable>: GeneratorType {

    private var generator: G
    private var count: Int = 0
    private var current: G.Element?

    init(_ generator: G) {
        self.generator = generator
    }

    func next() -> G.Element? {
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
    public convenience init(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = .None, body: () -> T?) {
        self.init(strategy: strategy, maxCount: max, generator: RepeatingGenerator(anyGenerator(body)))
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
    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        if self.operation == operation {
            finish(errors)
        }
    }
}

