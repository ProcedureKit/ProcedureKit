//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/// Struct to hold the values necessary for each
/// iteration of a RepeatProcedure. It is generic
/// over the Operation type (i.e. the type being
/// iterated). However, it also holds an optional
/// Delay property, and an optional ConfigureBlock.
public struct RepeatProcedurePayload<T: Operation> {
    public typealias ConfigureBlock = (T) -> Void

    /// - returns: the operation value
    public let operation: T
    /// - returns: the optional Delay
    public let delay: Delay?
    /// - returns: the optional ConfigureBlock
    public let configure: ConfigureBlock?

    /// Initializes a payload struct.
    ///
    /// - Parameters:
    ///   - operation: an instance of an Operation subclass T
    ///   - delay: an optional Delay value, which defaults to nil
    ///   - configure: an optional closure which receives the operation, and which defaults to nil
    public init(operation: T, delay: Delay? = nil, configure: ConfigureBlock? = nil) {
        self.operation = operation
        self.delay = delay
        self.configure = configure
    }

    /// Sets the delay property.
    ///
    /// - Parameter newDelay: the new Delay property
    /// - Returns: a new RepeatProcedurePayload value.
    public func set(delay newDelay: Delay?) -> RepeatProcedurePayload {
        return RepeatProcedurePayload(operation: operation, delay: newDelay, configure: configure)
    }
}

/// RepeatProcedure is a GroupProcedure subclass which can be used to create
/// polling or repeating procedures. Each child procedure is a new instance
/// of the same Operation subclass T. For example `RepeatProcedure<MyOperation>`
/// will create and execute instances of MyOperation repeatedly, and we say
/// that the RepeatProcedure is generic over T, which in this case is
/// MyOperation.
///
/// While RepeatProcedure can be initialized in a variety of ways, it helps
/// to understand that it works by using an Iterator. The iterator's payload
/// is a structure which holds an instance of the Operation subclass (`T`),
/// and optional Delay value, and an optional configuration block. The block
/// receives the instance, and can be used to prepare the operation before
/// it is executed.
///
/// All of the initializers available will ultimately create the underlying
/// iterator.
open class RepeatProcedure<T: Operation>: GroupProcedure {

    public typealias Payload = RepeatProcedurePayload<T>

    static func create<V>(withMax max: Int? = nil, andIterator base: V) -> (T, AnyIterator<Payload>) where V: IteratorProtocol, V.Element == Payload {

        var base = base
        guard let payload = base.next() else { preconditionFailure("Payload Iterator must return an instance initially.") }

        if let max = max {
            return (payload.operation, AnyIterator(FiniteIterator(base, limit: max - 1)))
        }
        return (payload.operation, AnyIterator(base))
    }

    static func create<D, V>(withMax max: Int? = nil, andDelay delay: D, andIterator base: V) -> (T, AnyIterator<Payload>) where D: IteratorProtocol, D.Element == Delay, V: IteratorProtocol, V.Element == T {
        let tmp = MapIterator(PairIterator(primary: base, secondary: delay)) { Payload(operation: $0.0, delay: $0.1) }
        return create(withMax: max, andIterator: tmp)
    }

    private let _repeatStateLock = PThreadMutex()

    @discardableResult
    fileprivate func synchronise<T>(block: () -> T) -> T {
        return _repeatStateLock.withCriticalScope(block: block)
    }

    private var _iterator: AnyIterator<Payload>

    private var _previous: T?

    /// - returns: the previous executing operation instance of T
    public internal(set) var previous: T? {
        get { return synchronise { _previous } }
        set { synchronise { _previous = newValue } }
    }

    private var _current: T

    /// - returns: the currently executing operation instance of T
    public internal(set) var current: T {
        get { return synchronise { _current } }
        set { synchronise { _current = newValue } }
    }

    private var _count: Int = 1

    /// - returns: the number of operation instances
    public var count: Int {
        return synchronise { _count }
    }

    private var _configure: Payload.ConfigureBlock = { _ in }
    internal var configure: Payload.ConfigureBlock {
        return synchronise { _configure }
    }

    /// Initialize RepeatProcedure with an iterator, the element of the iterator a `RepeatProcedurePayload<T>`.
    /// Other arguments allow for specific dispatch queues, and a maximum count of iteratations.
    ///
    /// - Parameters:
    ///   - dispatchQueue: an optional DispatchQueue, which defaults to nil
    ///   - max: an optional Int, which defaults to nil.
    ///   - iterator: a generic IteratorProtocol type, with a Payload Element type
    public init<PayloadIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, iterator: PayloadIterator) where PayloadIterator: IteratorProtocol, PayloadIterator.Element == Payload {
        (_current, _iterator) = RepeatProcedure.create(withMax: max, andIterator: iterator)
        super.init(dispatchQueue: dispatchQueue, operations: [])
    }

    /// Initialize RepeatProcedure with two iterators, the first one has `Delay` elements, the
    /// second has `T` elements - i.e. the Operation subclass to be repeated.
    /// Other arguments allow for specific dispatch queues, and a maximum count of iteratations.
    ///
    /// - Parameters:
    ///   - dispatchQueue: an optional DispatchQueue, which defaults to nil
    ///   - max: an optional Int, which defaults to nil.
    ///   - delay: a generic IteratorProtocol type, with a Delay Element type
    ///   - iterator: a generic IteratorProtocol type, with a T Element type
    public init<OperationIterator, DelayIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, delay: DelayIterator, iterator: OperationIterator) where OperationIterator: IteratorProtocol, DelayIterator: IteratorProtocol, OperationIterator.Element == T, DelayIterator.Element == Delay {
        (_current, _iterator) = RepeatProcedure.create(withMax: max, andDelay: delay, andIterator: iterator)
        super.init(dispatchQueue: dispatchQueue, operations: [])
    }

    /// Initialize RepeatProcedure with a WaitStrategy and an iterator, which has `T` type
    /// elements - i.e. the Operation subclass to be repeated.
    /// Other arguments allow for specific dispatch queues, and a maximum count of iteratations.
    ///
    /// - Parameters:
    ///   - dispatchQueue: an optional DispatchQueue, which defaults to nil
    ///   - max: an optional Int, which defaults to nil.
    ///   - wait: a WaitStrategy value, which defaults to .immediate
    ///   - iterator: a generic IteratorProtocol type, with a T Element type
    public init<OperationIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, wait: WaitStrategy = .immediate, iterator: OperationIterator) where OperationIterator: IteratorProtocol, OperationIterator.Element == T {
        (_current, _iterator) = RepeatProcedure.create(withMax: max, andDelay: Delay.iterator(wait.iterator), andIterator: iterator)
        super.init(dispatchQueue: dispatchQueue, operations: [])
    }

    /// Initialize RepeatProcedure with a WaitStrategy and a closure. The closure returns
    /// an optional instance of T, i.e. the Operation subclass to be repeated.
    /// Other arguments allow for specific dispatch queues, and a maximum count of iteratations.
    ///
    /// This is the most convenient initializer, you can use it like this:
    /// ```swift
    ///    let procedure = RepeatProcedure { MyOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target) { MyOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target, max: 5) { MyOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target, max: 5, wait: .constant(10)) { MyOperation() }
    /// ```
    ///
    /// - Parameters:
    ///   - dispatchQueue: an optional DispatchQueue, which defaults to nil
    ///   - max: an optional Int, which defaults to nil.
    ///   - wait: a WaitStrategy value, which defaults to .immediate
    ///   - body: an espacing closure which returns an optional T
    public init(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, wait: WaitStrategy = .immediate, body: @escaping () -> T?) {
        (_current, _iterator) = RepeatProcedure.create(withMax: max, andDelay: Delay.iterator(wait.iterator), andIterator: AnyIterator(body))
        super.init(dispatchQueue: dispatchQueue, operations: [])
    }

    /// Public override of `execute()` which configures and adds the first operation
    ///
    /// - IMPORTANT: If subclassing `RepeatProcedure` and overriding this method, consider
    /// carefully whether / when / how you should call `super.execute()`.
    open override func execute() {
        let current = _repeatStateLock.withCriticalScope { () -> T in
            _configure(_current)
            return _current
        }
        addChild(current)
        super.execute()
    }

    /// Handle child willFinish event
    ///
    /// This is used by RepeatProcedure to trigger adding the next Procedure,
    /// and calls `super.child(_:willFinishWithErrors:)` to get the default
    /// GroupProcedure error-handling behavior.
    ///
    /// - IMPORTANT: If subclassing RepeatProcedure and overriding this method, consider
    /// carefully whether / when / how you should call `super.child(_:willFinishWithErrors:)`.
    open override func child(_ child: Procedure, willFinishWithError error: Error?) {
        eventQueue.debugAssertIsOnQueue()
        _addNextOperation(child === self.current)
        super.child(child, willFinishWithError: error) // default GroupProcedure error-handling
    }

    /// Adds the next payload from the iterator to the queue.
    ///
    /// - parameter shouldAddNext: must evaluate true to get the next payload. Defaults to true.
    ///
    /// - returns: whether or not there was a next payload added.
    @discardableResult
    final public func addNextOperation(_ shouldAddNext: @escaping @autoclosure () -> Bool = true) -> ProcedureFutureResult<Bool> {
        assert(!isFinished, "Cannot add next operation after the procedure has finished.")
        let promise = ProcedurePromiseResult<Bool>()
        dispatchEvent {
            let result = self._addNextOperation(shouldAddNext())
            promise.complete(withResult: result)
        }
        return promise.future
    }

    @discardableResult
    final internal func _addNextOperation(_ shouldAddNext: @escaping @autoclosure () -> Bool = true) -> Bool {
        eventQueue.debugAssertIsOnQueue() // Must always be called on the EventQueue.

        guard !isCancelled else { return false }

        guard shouldAddNext(), let payload = _next() else { return false }

        log.verbose.trace()
        log.info.message("Will add next operation.")

        _repeatStateLock.withCriticalScope {
            if let newConfigureBlock = payload.configure {
                _replace(configureBlock: newConfigureBlock)
            }

            _configure(payload.operation)

            _count += 1
            _previous = _current
            _current = payload.operation
        }

        if let delay = payload.delay.map({ DelayProcedure(delay: $0) }) {
            payload.operation.addDependency(delay)
            addChildren(delay, payload.operation)
        }
        else {
            addChild(payload.operation)
        }

        return true
    }

    /// Returns the next operation from the generator. This is here to
    /// allow subclasses to override and configure the operation
    /// further before it is added.
    ///
    /// - returns: an optional Payload future
    final public func next() -> ProcedureFutureResult<Payload?> {
        let promise = ProcedurePromiseResult<Payload?>()
        dispatchEvent {
            let next = self._next()
            promise.complete(withResult: next)
        }
        return promise.future
    }

    /// Appends a configuration block to the current block. This
    /// can be used to configure every instance of the operation
    /// before it is added to the queue.
    ///
    /// - NOTE: The configuration blocks are executed in FIFO order,
    /// so it is possible to overwrite previous configurations.
    ///
    /// - parameter block: a block which receives an instance of T
    final public func append(configureBlock block: @escaping Payload.ConfigureBlock) {
        _repeatStateLock.withCriticalScope {
            let config = _configure
            _configure = { operation in
                config(operation)
                block(operation)
            }
        }
    }

    /// - See: `append(configureBlock:)`
    final public func appendConfigureBlock(block: @escaping Payload.ConfigureBlock) {
        append(configureBlock: block)
    }

    /// Replaces the current configuration block
    ///
    /// If the payload returns a configure block, it replaces using
    /// this API, before configuring
    ///
    /// - parameter block: a block which receives an instance of T
    final public func replace(configureBlock block: @escaping Payload.ConfigureBlock) {
        _repeatStateLock.withCriticalScope {
            _replace(configureBlock: block)
        }
    }

    /// - See: `replace(configureBlock:)`
    final public func replaceConfigureBlock(block: @escaping Payload.ConfigureBlock) {
        replace(configureBlock: block)
    }

    // MARK: - Private Implementation

    // This method must be called on the Procedure's EventQueue.
    private func _next() -> Payload? {
        eventQueue.debugAssertIsOnQueue()
        return _iterator.next()
    }

    // This method is not thread-safe, and must be called within an aquisition
    // of the _repeatStateLock.
    private func _replace(configureBlock block: @escaping Payload.ConfigureBlock) {
        _configure = block
        log.verbose.trace()
        log.verbose.message("did replace configure block.")
    }
}

// MARK: - Repeatable

/// Repeatable protocol is a very simple protocol which allows
/// `Operation` subclasses to determine whether they should
/// trigger another repeated value. In other words, the current
/// just finished instance determines whether a new instance is
/// executed next, or the repeating finishes.
@available(*, deprecated, message: "Use RepeatProcedure or RetryProcedure instead")
public protocol Repeatable {

    /// Determines whether or not a subsequent instance of the
    /// receiver should be executed.
    ///
    /// - Parameter count: an Int, the number of instances executes thus far
    /// - Returns: a Bool, true to indicate that another instance should be executed.
    func shouldRepeat(count: Int) -> Bool
}

@available(*, deprecated, message: "Use RepeatProcedure or RetryProcedure instead")
extension RepeatProcedure where T: Repeatable {

    /// Initialize RepeatProcedure with a WaitStrategy and a closure. The closure returns
    /// an optional instance of T which conform to the `Repeatable` protocol.
    /// i.e. T is the Operation subclass to be repeated.
    /// Other arguments allow for specific dispatch queues, and a maximum count of iteratations.
    ///
    /// This is the most convenient initializer, you can use it like this:
    /// ```swift
    ///    let procedure = RepeatProcedure { MyRepeatableOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target) { MyRepeatableOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target, max: 5) { MyRepeatableOperation() }
    ///    let procedure = RepeatProcedure(dispatchQueue: target, max: 5, wait: .constant(10)) { MyRepeatableOperation() }
    /// ```
    ///
    /// - Parameters:
    ///   - dispatchQueue: an optional DispatchQueue, which defaults to nil
    ///   - max: an optional Int, which defaults to nil.
    ///   - wait: a WaitStrategy value, which defaults to .immediate
    ///   - body: an espacing closure which returns an optional T
    @available(*, deprecated, message: "Use RepeatProcedure or RetryProcedure instead")
    public convenience init(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, wait: WaitStrategy = .immediate, body: @escaping () -> T?) {
        self.init(dispatchQueue: dispatchQueue, max: max, wait: wait, iterator: RepeatableGenerator(AnyIterator(body)))
    }
}

// MARK: - Extensions

extension RepeatProcedure: InputProcedure where T: InputProcedure {

    public typealias Input = T.Input

    /// - returns: the pending input value where T conforms to InputProcedure
    public var input: Pending<T.Input> {
        get { return current.input }
        set {
            current.input = newValue
            appendConfigureBlock { $0.input = newValue }
        }
    }

    /// MARK: Result Injection APIs

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency, via block: @escaping (Dependency.Output) throws -> T.Input) -> Self {

        return injectResult(from: dependency) { (procedure, output) in
            do {
                procedure.input = .ready(try block(output))
            }
            catch {
                procedure.cancel(with: ProcedureKitError.dependency(finishedWithError: error))
            }
        }
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency) -> Self where Dependency.Output == T.Input {
        return injectResult(from: dependency, via: { $0 })
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency) -> Self where Dependency.Output == Optional<T.Input> {
        return injectResult(from: dependency) { output in
            guard let output = output else {
                throw ProcedureKitError.requirementNotSatisfied()
            }
            return output
        }
    }
}

extension RepeatProcedure: OutputProcedure where T: OutputProcedure {

    public typealias Output = T.Output

    /// - returns: the pending output result value where T conforms to OutputProcedure
    public var output: Pending<ProcedureResult<T.Output>> {
        get { return current.output }
        set {
            current.output = newValue
            appendConfigureBlock { $0.output = newValue }
        }
    }
}

// MARK: - Iterators

@available(*, deprecated, message: "Use RepeatProcedure or RetryProcedure instead")
internal struct RepeatableGenerator<Element: Repeatable>: IteratorProtocol {

    private var iterator: CountingIterator<Element>
    private var latest: Element?

    init<I: IteratorProtocol>(_ base: I) where I.Element == Element {
        let mutatingBaseIterator = AnyIterator(base)
        iterator = CountingIterator { _ in return mutatingBaseIterator.next() }
    }

    mutating func next() -> Element? {
        if let latest = latest {
            guard latest.shouldRepeat(count: iterator.count) else { return nil }
        }
        latest = iterator.next()
        return latest
    }
}

public struct CountingIterator<Element>: IteratorProtocol {

    private let body: (Int) -> Element?
    public private(set) var count: Int = 0

    public init(_ body: @escaping (Int) -> Element?) {
        self.body = body
    }

    public mutating func next() -> Element? {
        defer { count = count + 1 }
        return body(count)
    }
}

public func arc4random<T: ExpressibleByIntegerLiteral>(_ type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, Int(MemoryLayout<T>.size))
    return r
}

public struct RandomFailIterator<Element>: IteratorProtocol {

    private var iterator: AnyIterator<Element>
    private let shouldNotFail: () -> Bool

    public let probability: Double

    public init<I: IteratorProtocol>(_ iterator: I, probability prob: Double = 0.1) where I.Element == Element {
        self.iterator = AnyIterator(iterator)
        self.shouldNotFail = {
            let r = (Double(arc4random(UInt64.self)) / Double(UInt64.max))
            return r > prob
        }
        self.probability = prob
    }

    public mutating func next() -> Element? {
        guard shouldNotFail() else { return nil }
        return iterator.next()
    }
}

public struct FibonacciIterator: IteratorProtocol {
    var currentValue = 0, nextValue = 1

    public mutating func next() -> Int? {
        let result = currentValue
        currentValue = nextValue
        nextValue += result
        return result
    }
}

public struct FiniteIterator<Element>: IteratorProtocol {

    private var iterator: CountingIterator<Element>

    public init<I: IteratorProtocol>(_ iterator: I, limit: Int = 10) where I.Element == Element {
        var mutable = iterator
        self.iterator = CountingIterator { count in
            guard count < limit else { return nil }
            return mutable.next()
        }
    }

    public mutating func next() -> Element? {
        return iterator.next()
    }
}

public struct MapIterator<T, V>: IteratorProtocol {

    private let transform: (T) -> V
    private var iterator: AnyIterator<T>

    public init<I: IteratorProtocol>(_ iterator: I, transform: @escaping (T) -> V) where T == I.Element {
        self.iterator = AnyIterator(iterator)
        self.transform = transform
    }

    public mutating func next() -> V? {
        return iterator.next().map(transform)
    }
}

public struct PairIterator<T, V>: IteratorProtocol {

    private var primary: AnyIterator<T>
    private var secondary: AnyIterator<V>

    public init<Primary: IteratorProtocol, Secondary: IteratorProtocol>(primary: Primary, secondary: Secondary) where Primary.Element == T, Secondary.Element == V {
        self.primary = AnyIterator(primary)
        self.secondary = AnyIterator(secondary)
    }

    public mutating func next() -> (T, V?)? {
        return primary.next().map { ($0, secondary.next()) }
    }
}

// MARK: - IntervalIterator

public struct IntervalIterator {

    public static let immediate = AnyIterator { TimeInterval(0) }

    public static func constant(_ constant: TimeInterval = 1.0) -> AnyIterator<TimeInterval> {
        return AnyIterator { constant }
    }

    public static func random(withMinimum min: TimeInterval = 0.0, andMaximum max: TimeInterval = 10.0) -> AnyIterator<TimeInterval> {
        return AnyIterator {
            let r = (Double(arc4random(UInt64.self)) / Double(UInt64.max))
            return (r * (max - min)) + min
        }
    }

    public static func incrementing(from initial: TimeInterval = 0.0, by increment: TimeInterval = 1.0) -> AnyIterator<TimeInterval> {
        return AnyIterator(CountingIterator { count in
            let interval = initial + (increment * TimeInterval(count))
            return max(0, interval)
        })
    }

    public static func fibonacci(withPeriod period: TimeInterval = 1.0, andMaximum maximum: TimeInterval = TimeInterval(Int.max)) -> AnyIterator<TimeInterval> {
        return AnyIterator(MapIterator(FibonacciIterator()) { fib in
            let interval = period * TimeInterval(fib)
            return max(0, min(maximum, interval))
        })
    }

    public static func exponential(power: Double = 2.0, withPeriod period: TimeInterval = 1.0, andMaximum maximum: TimeInterval = TimeInterval(Int.max)) -> AnyIterator<TimeInterval> {
        return AnyIterator(CountingIterator { count in
            let interval = period * pow(power, Double(count))
            return max(0, min(maximum, interval))
        })
    }
}

public extension Delay {

    static func iterator(_ iterator: AnyIterator<TimeInterval>) -> AnyIterator<Delay> {
        return AnyIterator(MapIterator(iterator) { Delay.by($0) })
    }

    struct Iterator {

        static func iterator(_ iterator: AnyIterator<TimeInterval>) -> AnyIterator<Delay> {
            return Delay.iterator(iterator)
        }

        public static let immediate: AnyIterator<Delay> = iterator(IntervalIterator.immediate)

        public static func constant(_ constant: TimeInterval = 1.0) -> AnyIterator<Delay> {
            return iterator(IntervalIterator.constant(constant))
        }

        public static func random(withMinimum min: TimeInterval = 0.0, andMaximum max: TimeInterval = 10.0) -> AnyIterator<Delay> {
            return iterator(IntervalIterator.random(withMinimum: min, andMaximum: max))
        }

        public static func incrementing(from initial: TimeInterval = 0.0, by increment: TimeInterval = 1.0) -> AnyIterator<Delay> {
            return iterator(IntervalIterator.incrementing(from: initial, by: increment))
        }

        public static func fibonacci(withPeriod period: TimeInterval = 1.0, andMaximum maximum: TimeInterval = TimeInterval(Int.max)) -> AnyIterator<Delay> {
            return iterator(IntervalIterator.fibonacci(withPeriod: period, andMaximum: maximum))
        }

        public static func exponential(power: Double = 2.0, withPeriod period: TimeInterval = 1.0, andMaximum maximum: TimeInterval = TimeInterval(Int.max)) -> AnyIterator<Delay> {
            return iterator(IntervalIterator.exponential(power: power, withPeriod: period, andMaximum: maximum))
        }
    }
}

public enum WaitStrategy {
    case immediate
    case constant(TimeInterval)
    case random(minimum: TimeInterval, maximum: TimeInterval)
    case incrementing(initial: TimeInterval, increment: TimeInterval)
    case fibonacci(period: TimeInterval, maximum: TimeInterval)
    case exponential(power: Double, period: TimeInterval, maximum: TimeInterval)

    public var iterator: AnyIterator<TimeInterval> {
        switch self {
        case .immediate:
            return IntervalIterator.immediate
        case let .constant(constant):
            return IntervalIterator.constant(constant)
        case let .random(minimum: min, maximum: max):
            return IntervalIterator.random(withMinimum: min, andMaximum: max)
        case let .incrementing(initial: initial, increment: increment):
            return IntervalIterator.incrementing(from: initial, by: increment)
        case let .fibonacci(period: period, maximum: max):
            return IntervalIterator.fibonacci(withPeriod: period, andMaximum: max)
        case let .exponential(power: power, period: period, maximum: max):
            return IntervalIterator.exponential(power: power, withPeriod: period, andMaximum: max)
        }
    }
}
