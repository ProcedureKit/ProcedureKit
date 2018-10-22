//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/// `Delay` encapsulates different ways of specifying a delay.
///
/// - by: a `TimeInterval`
/// - until: a `Date`
public enum Delay: Comparable {

    public static func < (lhs: Delay, rhs: Delay) -> Bool {
        switch (lhs, rhs) {
        case let (.by(lhsBy), .by(rhsBy)):
            return lhsBy < rhsBy
        case let (.until(lhsUntil), .until(rhsUntil)):
            return lhsUntil < rhsUntil
        default: return false
        }
    }

    case by(TimeInterval)
    case until(Date)
}

extension Delay: CustomStringConvertible {

    public var description: String {
        switch self {
        case .by(let _interval):
            return "for \(_interval) seconds"
        case .until(let date):
            return "until \(DateFormatter().string(from: date))"
        }
    }
}

internal extension Delay {

    var interval: TimeInterval {
        switch self {
        case .by(let _interval):
            return _interval
        case .until(let date):
            return date.timeIntervalSinceNow
        }
    }
}

/**
 `DelayProcedure` is a `Procedure` which waits until a given future
 date, or a time interval. If the interval is negative, or the date
 is in the past, the procedure finishes.

 - Note: This procedure efficiently uses
 [GCD](https://developer.apple.com/documentation/dispatch) so it does
 not block the thread on which it is called (i.e. it is asynchronous).

 Make an operation dependent on a `DelayProcedure` in order to
 make it execute after a timeout, or in a repeated fashion with a
 time-out.
 */
public class DelayProcedure: Procedure, InputProcedure {

    public var input: Pending<Delay> = .pending

    private let leeway: DispatchTimeInterval
    private var _timer: DispatchSourceTimer?

    /**
     Initialize the `DelayProcedure` with a `Delay?` value.

     - parameter delay: an optional `Delay`, defaults to nil. Use if
         injecting the delay value after initilization.
     - parameter leeway: an `DispatchTimeInterval` representing leeway
     for the timer. This defaults to 1 milli-second accuracy.
     This is partly from a energy standpoint as nanosecond
     accuracy is costly.
     */

    public init(delay: Delay? = nil, leeway: DispatchTimeInterval = .milliseconds(1)) {
        self.leeway = leeway
        super.init()
        if let delay = delay {
            name = "Delay \(delay)"
            input = .ready(delay)
        }
        else {
            name = "Delay"
        }
        addDidCancelBlockObserver { procedure, _ in
            procedure._timer?.cancel()
            procedure.finish()
        }
    }

    /**
     Initialize the `DelayProcedure` with a time interval.

     - parameter by: a `TimeInterval`.
     - parameter leeway: an `DispatchTimeInterval` representing leeway
     for the timer. This defaults to 1 milli-second accuracy.
     This is partly from a energy standpoint as nanosecond
     accuracy is costly.
     */
    public convenience init(by interval: TimeInterval, leeway: DispatchTimeInterval = .milliseconds(1)) {
        self.init(delay: .by(interval), leeway: leeway)
    }

    /**
     Initialize the `DelayProcedure` with a date.

     - parameter until: a `Date`.
     - parameter leeway: an `DispatchTimeInterval` representing leeway
     for the timer. This defaults to 1 milli-second accuracy.
     This is partly from a energy standpoint as nanosecond
     accuracy is costly.
     */
    public convenience init(until date: Date, leeway: DispatchTimeInterval = .milliseconds(1)) {
        self.init(delay: .until(date), leeway: leeway)
    }

    /**
     Executes the operation by using a DispatchSourceTimer to finish
     the operation in the future, but only if the time interval is
     greater than zero. (Otherwise it finishes immediately.)
     */
    public override func execute() {
        guard let delay = input.value else {
            cancel(with: ProcedureKitError.requirementNotSatisfied())
            return
        }
        switch delay.interval {
        case (let interval) where interval > 0.0:
            guard !isCancelled else { return }
            _timer = eventQueue.makeTimerSource()
            _timer?.setEventHandler { [weak self] in
                guard let strongSelf = self else { return }
                if !strongSelf.isCancelled { strongSelf.finish() }
            }
            #if swift(>=4.0)
                _timer?.schedule(deadline: .now() + interval, leeway: self.leeway)
            #else
                _timer?.scheduleOneshot(deadline: .now() + interval, leeway: self.leeway)
            #endif
            _timer?.resume()
        default:
            finish()
        }
    }
}


// MARK: - InputProcedure convenience methods

extension InputProcedure where Self.Input == Delay {

    @discardableResult
    func injectDelay<Dependency: OutputProcedure>(from dependency: Dependency, by makeIntervalFrom: @escaping (Dependency.Output) throws -> TimeInterval) -> Self {
        return injectResult(from: dependency) { try .by(makeIntervalFrom($0)) }
    }

    @discardableResult
    func injectDelay<Dependency: OutputProcedure>(from dependency: Dependency, until makeDateFrom: @escaping (Dependency.Output) throws -> Date) -> Self {
        return injectResult(from: dependency) { try .until(makeDateFrom($0)) }
    }
}
