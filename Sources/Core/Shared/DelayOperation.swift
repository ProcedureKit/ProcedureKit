//
//  DelayOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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

    internal enum Delay: CustomStringConvertible {

        case Interval(NSTimeInterval)
        case Date(NSDate)

        var interval: NSTimeInterval {
            switch self {
            case .Interval(let _interval): return _interval
            case .Date(let date): return date.timeIntervalSinceNow
            }
        }

        var description: String {
            switch self {
            case .Interval(let _interval):
                return "for \(_interval) seconds"
            case .Date(let date):
                return "until \(NSDateFormatter().stringFromDate(date))"
            }
        }
    }

    private let delay: Delay
    private let leeway: UInt64
    private let timer: dispatch_source_t

    internal init(delay: Delay, leeway: Int = 1_000_000) {
        self.delay = delay
        self.leeway = UInt64(leeway)
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, Queue.Default.queue)
        super.init()
        name = "Delay \(delay)"
        dispatch_source_set_event_handler(timer) {
            if !self.cancelled {
                self.finish()
            }
        }
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
    public convenience init(interval: NSTimeInterval, leeway: Int = 1_000_000) {
        self.init(delay: .Interval(interval), leeway: leeway)
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
    public convenience init(date: NSDate, leeway: Int = 1_000_000) {
        self.init(delay: .Date(date), leeway: leeway)
    }

    /**
    Executes the operation by using dispatch_after to finish the
    operation in the future, but only if the time interval is 
    greater than zero.
    */
    public override func execute() {

        switch delay.interval {

        case (let interval) where interval > 0.0:
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC))), DISPATCH_TIME_FOREVER, leeway)
            dispatch_resume(timer)

        default:
            finish()
        }
    }

    public override func cancel() {
        dispatch_source_cancel(timer)
        super.cancel()
    }
}

