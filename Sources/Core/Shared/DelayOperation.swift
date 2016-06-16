//
//  DelayOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public enum Delay {
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

    var timeInterval: TimeInterval {
        switch self {
        case .by(let _interval):
            return _interval
        case .until(let date):
            return date.timeIntervalSinceNow
        }
    }

    var dispatchTimeInterval: DispatchTimeInterval {
        return .nanoseconds(Int(timeInterval * Double(NSEC_PER_SEC)))
    }

}

/**
`DelayOperation` is an operation which waits until a given future
date, or a time interval. If the interval is negative, or the date
is in the past, the operation finishes.

Note that this operation efficiently uses `dispatch_after` so it
does not block the thread on which it is called.

Make an operation dependent on a `DelayOperation` in order to
make it execute after a timeout, or in a repeated fashion with a
time-out.
*/
public class DelayOperation: Operation {

    private let delay: Delay
    private let leeway: DispatchTimeInterval
    private let timer: DispatchSourceTimer

    internal init(delay: Delay, leeway: Int = 1_000_000) {
        self.delay = delay
        self.leeway = .nanoseconds(Int(UInt64(leeway) * NSEC_PER_SEC))
        self.timer = DispatchSource.timer()
        super.init()
        name = "Delay \(delay)"
        timer.setEventHandler { [unowned self] _ in
            if !self.isCancelled {
                self.finish()
            }
        }
        addObserver(DidCancelObserver { [unowned self] _ in
            self.timer.cancel()
        })
    }

    /**
    Initialize the `DelayOperation` with a time interval.

     - parameter interval: a `NSTimeInterval`.
     - parameter leeway: an `Int` representing leeway of
     nanoseconds for the timer. This defaults to 1_000_000
     meaning the timer is accurate to milli-second accuracy.
     This is partly from a energy standpoint as nanosecond
     accuracy is costly.
    */
    public convenience init(interval: TimeInterval, leeway: Int = 1_000_000) {
        self.init(delay: .by(interval), leeway: leeway)
    }

    /**
    Initialize the `DelayOperation` with a date.

     - parameter interval: a `NSDate`.
     - parameter leeway: an `Int` representing leeway of
     nanoseconds for the timer. This defaults to 1_000_000
     meaning the timer is accurate to milli-second accuracy.
     This is partly from a energy standpoint as nanosecond
     accuracy is costly.
    */
    public convenience init(date: Date, leeway: Int = 1_000_000) {
        self.init(delay: .until(date), leeway: leeway)
    }

    /**
    Executes the operation by using dispatch_after to finish the
    operation in the future, but only if the time interval is
    greater than zero.
    */
    public override func execute() {

        switch delay.timeInterval {

        case (let interval) where interval > 0.0:

            timer.scheduleRepeating(deadline: DispatchTime.now(), interval: delay.timeInterval, leeway: leeway)
            timer.resume()

        default:
            finish()
        }
    }
}
