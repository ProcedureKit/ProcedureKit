//
//  RepeatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public enum MaximumTimeInterval {
    case Interval(NSTimeInterval)
    case Backoff
}

struct TimeDelayGenerator: GeneratorType {

    struct Info {

        let minimum: NSTimeInterval
        let maximum: MaximumTimeInterval
        let limit: Int?

        func interval(count: Int) -> NSTimeInterval {
            switch maximum {

            case .Backoff:
                let exp = (2.0 * pow(2.0, Double(count))) - 1
                let numberOfIntervals = NSTimeInterval(arc4random_uniform(UInt32(exp)))
                return minimum * numberOfIntervals

            case .Interval(let _interval):
                return _interval
            }
        }
    }

    private let info: Info
    private var count: Int = 0

    init(info: Info) {
        self.info = info
    }

    init(min: NSTimeInterval = 1, max: MaximumTimeInterval = .Backoff, limit: Int? = .None) {
        self.init(info: Info(minimum: min, maximum: max, limit: limit))
    }

    mutating func next() -> NSTimeInterval? {
        if let limit = info.limit {
            guard count == limit else {
                return nil
            }
        }
        return info.interval(count)
    }
}

public class RepeatedOperation<Generator: GeneratorType where Generator.Element: NSOperation>: GroupOperation {

    private var delay: TimeDelayGenerator
    private var generator: Generator
    public internal(set) var operation: Generator.Element? = .None

    public init(min: NSTimeInterval = 1, max: MaximumTimeInterval = .Backoff, limit: Int? = .None, generator: Generator) {
        self.delay = TimeDelayGenerator(min: min, max: max, limit: limit)
        self.generator = generator
        super.init(operations: [])
        name = "Repeated Operation"
    }

    public override func execute() {
        addNextOperation()
        super.execute()
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty {
            addNextOperation()
        }
    }

    public func addNextOperation() {
        operation = generator.next()
        if let op = operation, delay = nextDelayOperation() {
            op.addDependency(delay)
            addOperations(delay, op)
        }
    }

    internal func nextDelayOperation() -> DelayOperation? {
        return delay.next().map { DelayOperation(interval: $0) }
    }
}

