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
        let attempts: Int?

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

    init(min: NSTimeInterval = 1, max: MaximumTimeInterval = .Backoff, attempts: Int? = .None) {
        self.init(info: Info(minimum: min, maximum: max, attempts: attempts))
    }

    mutating func next() -> NSTimeInterval? {
        if let maxNumberOfAttempts = info.attempts {
            guard count == maxNumberOfAttempts else {
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

    public init(min: NSTimeInterval = 1, max: MaximumTimeInterval = .Backoff, maxNumberOfAttempts attempts: Int? = .None, generator: Generator) {
        self.delay = TimeDelayGenerator(min: min, max: max, attempts: attempts)
        self.generator = generator
        super.init(operations: [])
        name = "Repeated Operation"
    }

    public override func execute() {
        addNextOperation()
        super.execute()
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let _ = operation as? Generator.Element {
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

public protocol RepeatingOperationType {
    var shouldRepeat: Bool { get }
}

public class RepeatingOperationGenerator<O where O: NSOperation, O: RepeatingOperationType>: GeneratorType {

    private var generator: AnyGenerator<O>
    private var operation: O?

    public init(_ creator: () -> O?) {
        generator = anyGenerator(creator)
    }

    public func next() -> O? {
        if let op = operation {
            guard op.shouldRepeat else {
                return nil
            }
        }

        operation = generator.next()

        return operation
    }
}


