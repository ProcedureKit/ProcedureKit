//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/**
 An observer which will automatically cancel (with an error) the `Procedure`
 to which it is attached if the `Procedure` doesn't finish executing before a
 time interval is expired.

 The timer starts right before the Procedure's `execute()` function is called
 (after the Procedure has been started).

 - IMPORTANT:
 This will cancel a `Procedure`. It is the responsibility of the `Procedure`
 subclass to handle cancellation as appropriate for it to rapidly finish after
 it is cancelled.

 - See: the documentation for `Procedure.cancel()`
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

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        switch delay.interval {
        case (let interval) where interval > 0.0:
            ProcedureTimeoutRegistrar.shared.createFinishTimeout(forProcedure: procedure, withDelay: delay)
            break
        default: break
        }
    }

    public func did(finish procedure: Procedure, with error: Error?) {
        ProcedureTimeoutRegistrar.shared.registerFinished(procedure: procedure)
    }
}

// A shared registrar of Procedure -> timeout timers.
// Used to cancel all outstanding timers for a Procedure if:
//      - that Procedure finishes
//      - one of the Procedure's timers fires
internal class ProcedureTimeoutRegistrar {

    static let shared = ProcedureTimeoutRegistrar()

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.ProcedureTimeouts", attributes: [.concurrent])
    private let protectedFinishTimers = Protector<[Procedure : [DispatchTimerWrapper]]>([:])

    func createFinishTimeout(forProcedure procedure: Procedure, withDelay delay: Delay) {
        let timer = DispatchTimerWrapper(queue: queue)
        timer.setEventHandler { [delay, weak procedure, weak registrar = self] in
            guard let strongProcedure = procedure else { return }
            guard !strongProcedure.isFinished && !strongProcedure.isCancelled else { return }
            strongProcedure.cancel(with: ProcedureKitError.timedOut(with: delay))
            registrar?.registerTimeoutProcessed(forProcedure: strongProcedure)
        }
        protectedFinishTimers.write {
            guard var procedureTimers = $0[procedure] else {
                $0.updateValue([timer], forKey: procedure)
                return
            }
            procedureTimers.append(timer)
            $0[procedure] = procedureTimers
        }
        timer.scheduleOneshot(deadline: .now() + delay.interval)
        timer.resume()
    }

    // Called when a Procedure will/did Finish.
    // Only the first call is processed, and removes all pending timers/timeouts for that Procedure.
    func registerFinished(procedure: Procedure) {
        registerTimeoutProcessed(forProcedure: procedure)
    }

    // Removes all DispatchTimers associated with a Procedure's registered timeouts.
    // Is called when a Procedure finishes and when a timeout fires.
    private func registerTimeoutProcessed(forProcedure procedure: Procedure) {
        guard let dispatchTimers = protectedFinishTimers.write({
            return $0.removeValue(forKey: procedure)
        })
        else {
            return
        }
        for timer in dispatchTimers {
            timer.cancel()
        }
    }
}

// A wrapper for a DispatchSourceTimer that ensures that the timer is cancelled
// and not suspended prior to deinitialization.
fileprivate class DispatchTimerWrapper {
    fileprivate typealias EventHandler = @convention(block) () -> Swift.Void
    private let timer: DispatchSourceTimer
    private let lock = NSLock()
    private var didResume = false

    init(queue: DispatchQueue) {
        timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
    }
    deinit {
        // ensure that the timer is cancelled and resumed before deiniting
        // (trying to deconstruct a suspended DispatchSource will fail)
        timer.cancel()
        lock.withCriticalScope {
            guard !didResume else { return }
            timer.resume()
        }
    }

    // MARK: - DispatchSourceTimer methods

    func setEventHandler(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], handler: @escaping EventHandler) {
        timer.setEventHandler(qos: qos, flags: flags, handler: handler)
    }
    func setEventHandler(handler: DispatchWorkItem) {
        timer.setEventHandler(handler: handler)
    }
    func scheduleOneshot(deadline: DispatchTime, leeway: DispatchTimeInterval = .nanoseconds(0)) {
        #if swift(>=4.0)
            timer.schedule(deadline: deadline, leeway: leeway)
        #else
            timer.scheduleOneshot(deadline: deadline, leeway: leeway)
        #endif
    }
    func resume() {
        lock.withCriticalScope {
            guard !didResume else { fatalError("Do not call resume() twice.") }
            timer.resume()
            didResume = true
        }
    }
    func cancel() {
        timer.cancel()
    }
}
