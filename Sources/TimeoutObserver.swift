//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

/**
 An observer which will automatically cancel (with an error)
 if it doesn't finish before a time interval is expired.
 */
public struct TimeoutObserver: ProcedureObserver {

    private let delay: Delay

    /**
     Initialize the `TimeoutObserver` with a time interval.

     - parameter by: a `TimeInterval`.
     */
    public init(by interval: TimeInterval) {
        delay = .by(interval)
    }

    /**
     Initialize the `TimeoutObserver` with a date.

     - parameter until: a `Date`.
     */
    public init(until date: Date) {
        delay = .until(date)
    }

    public func will(execute procedure: Procedure) {
        switch delay.interval {
        case (let interval) where interval > 0.0:
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [delay = self.delay] in
                guard !procedure.isFinished && !procedure.isCancelled else { return }
                procedure.cancel(withError: ProcedureKitError.timedOut(with: delay))
            }
        default: break
        }
    }
}
