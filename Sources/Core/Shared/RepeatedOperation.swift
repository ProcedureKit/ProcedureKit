//
//  RepeatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

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

func arc4random<T: IntegerLiteralConvertible>(type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, Int(sizeof(T)))
    return r
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

public enum WaitStrategy {

    case Fixed(NSTimeInterval)
    case Random((minimum: NSTimeInterval, maximum: NSTimeInterval))
    case Incrementing((initial: NSTimeInterval, increment: NSTimeInterval))
    case Exponential((period: NSTimeInterval, maximum: NSTimeInterval))
    case Fibonacci((period: NSTimeInterval, maximum: NSTimeInterval))

    func generate() -> AnyGenerator<NSTimeInterval> {
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

public class RepeatedOperation<T where T: NSOperation>: GroupOperation {

    private var delay: AnyGenerator<NSTimeInterval>
    private var generator: AnyGenerator<T>
    public internal(set) var operation: T? = .None

    public private(set) var attempts: Int = 0

    public init(strategy: WaitStrategy = .Fixed(0.1), maxNumberOfAttempts attempts: Int? = .None, _ generator: AnyGenerator<T>) {
        operation = generator.next()
        guard let op = operation else {
            preconditionFailure("The generator must return an operation to start with.")
        }

        switch attempts {
        case .Some(let attempts):
            delay = anyGenerator(FiniteGenerator(strategy.generate(), limit: attempts))
        case .None:
            delay = strategy.generate()
        }

        self.generator = generator
        super.init(operations: [op])
        name = "Repeated Operation"
    }

    public convenience init<G where G: GeneratorType, G.Element == T>(strategy: WaitStrategy = .Fixed(0.1), maxNumberOfAttempts attempts: Int? = .None, _ generator: G) {
        self.init(strategy: strategy, maxNumberOfAttempts: attempts, anyGenerator(generator))
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if let _ = operation as? DelayOperation { return }
        if let _ = operation as? T {
            addNextOperation()
        }
    }

    public func addNextOperation() {
        operation = generator.next()
        if let op = operation, delay = nextDelayOperation() {
            op.addDependency(delay)
            addOperations(delay, op)
            attempts += 1
        }
    }

    internal func nextDelayOperation() -> DelayOperation? {
        return delay.next().map { DelayOperation(interval: $0) }
    }
}

public protocol Repeatable {
    func shouldRepeat(count: Int) -> Bool
}

public class RepeatingGenerator<G: GeneratorType where G.Element: Repeatable>: GeneratorType {

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

    public convenience init(strategy: WaitStrategy = .Fixed(0.1), maxNumberOfAttempts attempts: Int? = .None, body: () -> T?) {
        self.init(strategy: strategy, maxNumberOfAttempts: attempts, RepeatingGenerator(anyGenerator(body)))
    }
}

