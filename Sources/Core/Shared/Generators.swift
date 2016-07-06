//
//  Generators.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/03/2016.
//
//

import Foundation

func arc4random<T: IntegerLiteralConvertible>(_ type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, Int(sizeof(T.self)))
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
public struct RandomFailGenerator<G: IteratorProtocol>: IteratorProtocol {

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
            let r = (Double(arc4random(UInt64.self)) / Double(UInt64.max))
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

struct FibonacciGenerator: IteratorProtocol {
    var currentValue = 0, nextValue = 1

    mutating func next() -> Int? {
        let result = currentValue
        currentValue = nextValue
        nextValue += result
        return result
    }
}

struct FiniteGenerator<G: IteratorProtocol>: IteratorProtocol {

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

struct MapGenerator<G: IteratorProtocol, T>: IteratorProtocol {
    private let transform: (G.Element) -> T
    private var generator: G


    init(_ generator: G, transform: (G.Element) -> T) {
        self.generator = generator
        self.transform = transform
    }

    mutating func next() -> T? {
        return generator.next().map(transform)
    }
}

struct TupleGenerator<Primary: IteratorProtocol, Secondary: IteratorProtocol>: IteratorProtocol {

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


struct IntervalGenerator: IteratorProtocol {

    let strategy: WaitStrategy

    private var count: Int = 0
    private lazy var fibonacci = FibonacciGenerator()

    init(_ strategy: WaitStrategy) {
        self.strategy = strategy
    }

    mutating func next() -> TimeInterval? {
        switch strategy {

        case .fixed(let period):
            return period

        case .random(let (minimum, maximum)):
            let r = Double(arc4random(UInt64.self)) / Double(UInt64.max)
            return (r * (maximum - minimum)) + minimum

        case .incrementing(let (initial, increment)):
            let interval = initial + (TimeInterval(count) * increment)
            count += 1
            return max(0, interval)

        case .exponential(let (period, maximum)):
            let interval = period * pow(2.0, Double(count))
            count += 1
            return max(0, min(maximum, interval))

        case .fibonacci(let (period, maximum)):
            return fibonacci.next().map { fib in
                let interval = period * TimeInterval(fib)
                return max(0, min(maximum, interval))
            }
        }
    }
}
