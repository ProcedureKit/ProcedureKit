//
//  Profiler.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

// swiftlint:disable nesting

import Foundation

public struct OperationIdentity {
    let identifier: String
    let name: String?
}

extension OperationIdentity: CustomStringConvertible {

    public var description: String {
        return name.map { "\($0) #\(identifier)" } ?? "Unnamed Operation #\(identifier)"
    }
}

public extension Operation {

    var identity: OperationIdentity {
        return OperationIdentity(identifier: identifier, name: name)
    }
}

public enum PerformanceMetric {

    public struct TimeToEvent {
        let interval: NSTimeInterval
    }

    public struct Child {

        public enum Status {
            case Pending(String)
            case Finished([PerformanceMetric])
        }

        let interval: NSTimeInterval
        let identity: OperationIdentity
        let status: Status

        var pending: Bool {
            switch status {
            case .Pending(_):
                return true
            case .Finished(let metrics):
                return metrics.filter { $0.pending }.count > 0
            }
        }

        var metrics: [PerformanceMetric]? {
            switch status {
            case .Finished(let metrics):
                return metrics
            default:
                return .None
            }
        }

        func finishWithMetrics(metrics: [PerformanceMetric]) -> Child {
            return Child(interval: interval, identity: identity, status: .Finished(metrics))
        }
    }

    case Attached(TimeToEvent)
    case Started(TimeToEvent)
    case Cancelled(TimeToEvent)
    case Produced(Child)
    case Finished(TimeToEvent)

    var interval: NSTimeInterval {
        switch self {
        case .Attached(let timeToEvent):
            return timeToEvent.interval
        case .Started(let timeToEvent):
            return timeToEvent.interval
        case .Cancelled(let timeToEvent):
            return timeToEvent.interval
        case .Produced(let child):
            return child.interval
        case .Finished(let timeToEvent):
            return timeToEvent.interval
        }
    }

    var event: OperationEvent {
        switch self {
        case .Attached(_):  return .Attached
        case .Started(_):   return .Started
        case .Cancelled(_): return .Cancelled
        case .Produced(_):  return .Produced
        case .Finished(_):  return .Finished
        }
    }

    var pending: Bool {
        switch self {
        case .Produced(let child):
            if case .Pending = child.status {
                return true
            }
        default:
            break
        }
        return false
    }

    init?(event: OperationEvent, interval: NSTimeInterval) {
        let timeToEvent = TimeToEvent(interval: interval)
        switch event {
        case .Attached:
            self = .Attached(timeToEvent)
        case .Started:
            self = .Started(timeToEvent)
        case .Cancelled:
            self = .Cancelled(timeToEvent)
        case .Finished:
            self = .Finished(timeToEvent)
        default:
            return nil
        }
    }
}

public protocol OperationProfilerReporter {
    func profiler(profiler: OperationProfiler, finishedWithPerformanceMetrics: [PerformanceMetric])
}

public final class OperationProfiler {

    enum Reporter {
        case Parent(OperationProfiler)
        case Reporters([OperationProfilerReporter])
    }

    let identifier = NSUUID().UUIDString
    let now: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    let queue = Queue.Utility.serial("me.danthorpe.Operations.Profiler")

    let reporter: Reporter
    var identity: OperationIdentity? = .None
    var metrics: [PerformanceMetric] = []

    var finishedOrCancelled = false

    var pending: Bool {
        return metrics.filter { $0.pending }.count > 0
    }

    public convenience init(reporters: [OperationProfilerReporter]) {
        self.init(reporter: .Reporters(reporters))
    }

    convenience init(parent: OperationProfiler) {
        self.init(reporter: .Parent(parent))
    }

    init(reporter: Reporter) {
        self.reporter = reporter
    }

    func addMetricNow(time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent(), forOperation operation: Operation, event: OperationEvent) {
        dispatch_sync(queue) {
            if let metric = PerformanceMetric(event: event, interval: (time - self.now) as NSTimeInterval) {
                self.metrics.append(metric)
            }
        }
    }

    func startProfiling(time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent(), operation: Operation, fromOperation from: Operation, withProfilerIdentifier identifier: String) {
        dispatch_sync(queue) {
            let child = PerformanceMetric.Child(interval: (time - self.now) as NSTimeInterval, identity: operation.identity, status: .Pending(identifier))
            self.metrics.append(.Produced(child))
        }
    }

    func finish() {
        guard finishedOrCancelled && !pending else { return }
        reporter.profiler(self, finishedWithPerformanceMetrics: metrics)
    }
}

extension OperationProfiler.Reporter: OperationProfilerReporter {

    func profiler(profiler: OperationProfiler, finishedWithPerformanceMetrics metrics: [PerformanceMetric]) {
        switch self {
        case .Parent(let parent):
            parent.profiler(profiler, finishedWithPerformanceMetrics: metrics)
        case .Reporters(let reporters):
            reporters.forEach { $0.profiler(profiler, finishedWithPerformanceMetrics: metrics)  }
        }
    }
}

extension OperationProfiler: OperationProfilerReporter {

    public func profiler(profiler: OperationProfiler, finishedWithPerformanceMetrics performanceMetrics: [PerformanceMetric]) {
        let childIdentifier = profiler.identifier

        dispatch_sync(queue) {
            if let (index, child) = self.indexOfProducedChildPendingWithIdentifier(childIdentifier, metrics: self.metrics) {
                self.metrics[index] = .Produced(child.finishWithMetrics(performanceMetrics))
                self.finish()
            }
        }
    }

    func indexOfProducedChildPendingWithIdentifier(identifier: String, metrics: [PerformanceMetric]) -> (Int, PerformanceMetric.Child)? {
        for (index, metric) in metrics.enumerate() {
            switch metric {
            case .Produced(let child):
                if case .Pending(identifier) = child.status {
                    return (index, child)
                }
            default:
                break
            }
        }
        return .None
    }
}

extension OperationProfiler: OperationObserverType {

    public func didAttachToOperation(operation: Operation) {
        addMetricNow(forOperation: operation, event: .Attached)
        identity = operation.identity
    }
}

extension OperationProfiler: OperationDidStartObserver {

    public func didStartOperation(operation: Operation) {
        addMetricNow(forOperation: operation, event: .Started)
    }
}

extension OperationProfiler: OperationDidCancelObserver {

    public func didCancelOperation(operation: Operation) {
        addMetricNow(forOperation: operation, event: .Cancelled)
        finishedOrCancelled = true
        finish()
    }
}

extension OperationProfiler: OperationDidFinishObserver {

    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        addMetricNow(forOperation: operation, event: .Finished)
        finishedOrCancelled = true
        finish()
    }
}

extension OperationProfiler: OperationDidProduceOperationObserver {

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        if let newOperation = newOperation as? Operation {
            let profiler = OperationProfiler(parent: self)
            startProfiling(operation: newOperation, fromOperation: operation, withProfilerIdentifier: profiler.identifier)
            newOperation.addObserver(profiler)
        }
    }
}

extension OperationProfiler: Equatable, Hashable {

    public var hashValue: Int {
        return identifier.hashValue
    }
}

public func == (lhs: OperationProfiler, rhs: OperationProfiler) -> Bool {
    return lhs.identifier == rhs.identifier
}

// MARK: - Reporters

struct PrintablePerformanceMetric: CustomStringConvertible {
    let indentation: Int
    let spacing: Int
    let metric: PerformanceMetric

    var description: String {
        get {
            var output = "\(createIndentation())+\(metric.interval)\(createSpacing())\(metric.event)"
            switch metric {
            case .Produced(let child):
                if let metrics = child.metrics {
                    output = "\(output) \(child.identity)"
                    let printableMetrics = metrics.map { PrintablePerformanceMetric(indentation: indentation+2, spacing: spacing, metric: $0) }
                    for metric in printableMetrics {
                        output = "\(output)\n\(metric)"
                    }
                }
            default:
                break
            }
            return output
        }
    }

    init(indentation: Int = 0, spacing: Int = 1, metric: PerformanceMetric) {
        self.indentation = indentation
        self.spacing = spacing
        self.metric = metric
    }

    func createIndentation() -> String {
        return String(count: indentation, repeatedValue: " " as UnicodeScalar)
    }

    func createSpacing() -> String {
        return String(count: spacing, repeatedValue: " " as UnicodeScalar)
    }
}

public class _OperationProfileLogger<Manager: LogManagerType>: _Logger<Manager>, OperationProfilerReporter {

    public required init(severity: LogSeverity = Manager.severity, enabled: Bool = Manager.enabled, logger: LoggerBlockType = Manager.logger) {
        super.init(severity: severity, enabled: enabled, logger: logger)
    }

    public func profiler(profiler: OperationProfiler, finishedWithPerformanceMetrics metrics: [PerformanceMetric]) {

        operationName = profiler.identity?.description
        var output = ""
        let printableMetrics = metrics.map { PrintablePerformanceMetric(metric: $0) }
        for metric in printableMetrics {
            output = "\(output)\n\(metric)"
        }

        info("finished with perfomance metrics:\(output)")
    }
}

public typealias OperationProfileLogger = _OperationProfileLogger<LogManager>

public extension OperationProfiler {

    convenience init(_ reporter: OperationProfilerReporter = OperationProfileLogger()) {
        self.init(reporters: [reporter])
    }
}

// swiftlint:enable nesting
