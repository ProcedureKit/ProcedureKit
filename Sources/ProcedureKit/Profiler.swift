//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

public enum ProcedureEvent: Int {
    case attached = 0, started, cancelled, produced, finished
}

extension ProcedureEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .attached: return "Attached"
        case .started: return "Started"
        case .cancelled: return "Cancelled"
        case .produced: return "Produced"
        case .finished: return "Finished"
        }
    }
}

// MARK: - ProcedureProfilerReporter
public protocol ProcedureProfilerReporter {
    func finishedProfiling(withResult result: ProfileResult)
}

// MARK: - ProfileResult
public struct ProfileResult {
    public let identity: Procedure.Identity
    public let created: TimeInterval
    public let attached: TimeInterval
    public let started: TimeInterval
    public let cancelled: TimeInterval?
    public let finished: TimeInterval?
    public let children: [ProfileResult]
}

// MARK: - PendingResult
struct PendingProfileResult {

    let created: TimeInterval
    let identity: Pending<Procedure.Identity>
    let attached: Pending<TimeInterval>
    let started: Pending<TimeInterval>
    let cancelled: Pending<TimeInterval>
    let finished: Pending<TimeInterval>
    let children: [ProfileResult]

    var isPending: Bool {
        return identity.isPending || attached.isPending || started.isPending || (cancelled.isPending && finished.isPending)
    }

    func createResult() -> ProfileResult? {
        guard !isPending, let
            identity = identity.value,
            let attached = attached.value,
            let started = started.value
        else { return nil }

        return ProfileResult(identity: identity, created: created, attached: attached, started: started, cancelled: cancelled.value, finished: finished.value, children: children)
    }

    func set(identity newIdentity: Procedure.Identity) -> PendingProfileResult {
        guard identity.isPending else { return self }
        return PendingProfileResult(created: created, identity: .ready(newIdentity), attached: attached, started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func attach(now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingProfileResult {
        guard attached.isPending else { return self }
        return PendingProfileResult(created: created, identity: identity, attached: .ready(now - created), started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func start(now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingProfileResult {
        guard started.isPending else { return self }
        return PendingProfileResult(created: created, identity: identity, attached: attached, started: .ready(now - created), cancelled: cancelled, finished: finished, children: children)
    }

    func cancel(now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingProfileResult {
        guard cancelled.isPending else { return self }
        return PendingProfileResult(created: created, identity: identity, attached: attached, started: started, cancelled: .ready(now - created), finished: finished, children: children)
    }

    func finish(now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingProfileResult {
        guard finished.isPending else { return self }
        return PendingProfileResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: .ready(now - created), children: children)
    }

    func add(child: ProfileResult) -> PendingProfileResult {
        var newChildren = children
        newChildren.append(child)
        return PendingProfileResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: finished, children: newChildren)
    }
}

// MARK: ProcedureProfiler

public final class ProcedureProfiler: Identifiable, Equatable {

    public let identity = UUID()

    enum Reporter {
        case parent(ProcedureProfiler)
        case reporters([ProcedureProfilerReporter])
    }

    let queue = DispatchQueue(label: "run.kit.ProcedureKit.Profiler")
    let reporter: Reporter

    var result = PendingProfileResult(created: CFAbsoluteTimeGetCurrent() as TimeInterval, identity: .pending, attached: .pending, started: .pending, cancelled: .pending, finished: .pending, children: [])
    var children: [Procedure.Identity] = []
    var finishedOrCancelled = false

    var pending: Bool {
        return result.isPending || (children.count > 0)
    }

    public convenience init(reporters: [ProcedureProfilerReporter]) {
        self.init(reporter: .reporters(reporters))
    }

    convenience init(parent: ProcedureProfiler) {
        self.init(reporter: .parent(parent))
    }

    init(reporter: Reporter) {
        self.reporter = reporter
    }

    func addMetric(now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval, forEvent event: ProcedureEvent) {
        queue.sync { [weak self] in
            guard let strongSelf = self else { return }
            switch event {
                case .attached:
                    strongSelf.result = strongSelf.result.attach(now: now)
                case .started:
                    strongSelf.result = strongSelf.result.start(now: now)
                case .cancelled:
                    strongSelf.result = strongSelf.result.cancel(now: now)
                    strongSelf.finishedOrCancelled = true
                case .finished:
                    strongSelf.result = strongSelf.result.finish(now: now)
                    strongSelf.finishedOrCancelled = true
                default:
                    break
            }
            strongSelf.finish()
        }
    }

    func addChild(operation: Operation, now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) {
        if let procedure = operation as? Procedure {
            let profiler = ProcedureProfiler(parent: self)
            procedure.addObserver(profiler)
            queue.sync { [weak self] in
                self?.children.append(procedure.identity)
            }
        }
    }

    func finish() {
        guard finishedOrCancelled && !pending, let result = result.createResult() else { return }
        reporter.finishedProfiling(withResult: result)
    }
}

extension ProcedureProfiler.Reporter: ProcedureProfilerReporter {

    func finishedProfiling(withResult result: ProfileResult) {
        switch self {
        case .parent(let parent):
            parent.finishedProfiling(withResult: result)
        case .reporters(let reporters):
            reporters.forEach { $0.finishedProfiling(withResult: result)  }
        }
    }
}

extension ProcedureProfiler: ProcedureProfilerReporter {

    public func finishedProfiling(withResult result: ProfileResult) {
        queue.sync { [weak self] in
            guard let strongSelf = self else { return }
            if let index = strongSelf.children.firstIndex(of: result.identity) {
                strongSelf.result = strongSelf.result.add(child: result)
                strongSelf.children.remove(at: index)
            }
            strongSelf.finish()
        }
    }
}

extension ProcedureProfiler: ProcedureObserver {

    public func didAttach(to procedure: Procedure) {
        queue.sync { [unowned self] in
            self.result = self.result.set(identity: procedure.identity)
        }
        addMetric(forEvent: .attached)
    }

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        addMetric(forEvent: .started)
    }

    public func did(cancel procedure: Procedure) {
        addMetric(forEvent: .cancelled)
    }

    public func did(finish procedure: Procedure, with error: Error?) {
        addMetric(forEvent: .finished)
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        addChild(operation: newOperation)
    }
}

// MARK: - Reporters
struct PrintableProfileResult: CustomStringConvertible {
    let indentation: Int
    let spacing: Int
    let result: ProfileResult

    func addRow(withInterval interval: TimeInterval, text: String) -> String {
        return "\(createIndentation())+\(interval)\(createSpacing())\(text)\n"
    }

    func addRow(withInterval interval: TimeInterval, forEvent event: ProcedureEvent) -> String {
        return addRow(withInterval: interval, text: event.description)
    }

    var description: String {
        get {
            var output = ""
            output += addRow(withInterval: result.attached, forEvent: .attached)
            output += addRow(withInterval: result.started, forEvent: .started)

            for child in result.children {
                output += "\(createIndentation())-> Spawned \(child.identity) with profile results\n"
                output += "\(PrintableProfileResult(indentation: indentation + 2, spacing: spacing, result: child))"
            }

            if let cancelled = result.cancelled {
                output += addRow(withInterval: cancelled, forEvent: .cancelled)
            }

            if let finished = result.finished {
                output += addRow(withInterval: finished, forEvent: .finished)
            }

            return output
        }
    }

    init(indentation: Int = 0, spacing: Int = 1, result: ProfileResult) {
        self.indentation = indentation
        self.spacing = spacing
        self.result = result
    }

    func createIndentation() -> String {
        return String(repeating: "", count: indentation)
    }

    func createSpacing() -> String {
        return String(repeating: "", count: spacing)
    }
}

public class _ProcedureProfileLogger<Settings: LogSettings>: Log.Channels<Settings>, ProcedureProfilerReporter {

    public func finishedProfiling(withResult result: ProfileResult) {
        formatter = Log.Formatters.makeProcedureLogFormatter(operationName: result.identity.description)
        current.message("finished profiling with results:\n\(PrintableProfileResult(result: result))")
    }
}

public typealias ProcedureProfileLogger = _ProcedureProfileLogger<Log>

public extension ProcedureProfiler {

    convenience init(_ reporter: ProcedureProfilerReporter = ProcedureProfileLogger()) {
        self.init(reporters: [reporter])
    }
}
