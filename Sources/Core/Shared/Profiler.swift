//
//  Profiler.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

import Foundation

/**
 - We will want to be able to track produced & grouped operations

public typealias TimeIntervalToEvent = (interval: NSTimeInterval, event: OperationEvent)

public enum PerformanceMetric {
    case ElapsedTimeToEvent(TimeIntervalToEvent)
    case Produced([PerformanceMetric])
}

*/

public struct PerformanceMetric {
    let interval: NSTimeInterval
    let event: OperationEvent
}

extension PerformanceMetric: CustomStringConvertible {
    public var description: String {
        return "\(interval) \(event)"
    }
}

public protocol OperationProfilerReporter: class {
    func operation(operation: Operation, profiled: OperationProfiler, withPerformanceMetrics: [PerformanceMetric])
}

public class OperationProfiler {

    let now: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    let queue = Queue.Utility.serial("me.danthorpe.Operations.Profiler")
    var metrics: [PerformanceMetric] = []

    let reporters: [OperationProfilerReporter]

    public init(reporters: [OperationProfilerReporter]) {
        self.reporters = reporters
    }

    func addMetricNow(time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent(), forOperation operation: Operation, event: OperationEvent) {
        dispatch_sync(queue) {
            self.metrics.append(PerformanceMetric(interval: (time - self.now) as NSTimeInterval, event: event))
        }
    }

    func finishOperation(operation: Operation) {
        let report = reportOperation(operation, withMetrics: metrics)
        dispatch_sync(queue) {
            self.reporters.forEach(report)
        }
    }

    func reportOperation(operation: Operation, withMetrics metrics: [PerformanceMetric]) -> OperationProfilerReporter -> Void {
        return { $0.operation(operation, profiled: self, withPerformanceMetrics: metrics)  }
    }
}

extension OperationProfiler: OperationObserverType {

    public func didAttachToOperation(operation: Operation) {
        addMetricNow(forOperation: operation, event: .Attached)
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
        finishOperation(operation)
    }
}

extension OperationProfiler: OperationDidFinishObserver {

    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        addMetricNow(forOperation: operation, event: .Finished)
        finishOperation(operation)
    }
}

struct PrintablePerformanceMetric: CustomStringConvertible {
    let indentation: Int
    let spacing: Int
    let metric: PerformanceMetric

    var description: String {
        return "\(createIndentation())+\(metric.interval)\(createSpacing())\(metric.event)"
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

    public func operation(operation: Operation, profiled: OperationProfiler, withPerformanceMetrics metrics: [PerformanceMetric]) {
        operationName = operation.operationName
        var output = ""
        let printableMetrics = metrics.map { PrintablePerformanceMetric(metric: $0) }
        for metric in printableMetrics {
            output = "\(output)\n\t\(metric)"
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
