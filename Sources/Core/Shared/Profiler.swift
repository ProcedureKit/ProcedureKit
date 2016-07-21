//
//  Profiler.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

// swiftlint:disable nesting

import Foundation

public protocol Identifiable {
    var identifier: String { get }
}

public func ==<T: Identifiable> (lhs: T, rhs: T) -> Bool {
    return lhs.identifier == rhs.identifier
}

public struct OperationIdentity: Identifiable, Equatable {
    public let identifier: String
    public let name: String?
}

extension OperationIdentity: CustomStringConvertible {

    public var description: String {
        return name.map { "\($0) #\(identifier)" } ?? "Unnamed OldOperation #\(identifier)"
    }
}

public extension OldOperation {

    var identity: OperationIdentity {
        return OperationIdentity(identifier: identifier, name: name)
    }
}

public protocol OperationProfilerReporter {
    func finishedProfilingWithResult(_ result: ProfileResult)
}

enum PendingValue<T: Equatable>: Equatable {
    case Pending
    case Value(T)

    var pending: Bool {
        if case .Pending = self {
            return true
        }
        return false
    }

    var value: T? {
        if case .Value(let value) = self {
            return value
        }
        return .none
    }
}

func == <T: Equatable>(lhs: PendingValue<T>, rhs: PendingValue<T>) -> Bool {
    switch (lhs, rhs) {
    case (.Pending, .Pending):
        return true
    case let (.Value(lhsValue), .Value(rhsValue)):
        return lhsValue == rhsValue
    default:
        return false
    }
}

public struct ProfileResult {
    public let identity: OperationIdentity
    public let created: TimeInterval
    public let attached: TimeInterval
    public let started: TimeInterval
    public let cancelled: TimeInterval?
    public let finished: TimeInterval?
    public let children: [ProfileResult]
}

struct PendingResult {

    let created: TimeInterval
    let identity: PendingValue<OperationIdentity>
    let attached: PendingValue<TimeInterval>
    let started: PendingValue<TimeInterval>
    let cancelled: PendingValue<TimeInterval>
    let finished: PendingValue<TimeInterval>
    let children: [ProfileResult]

    var pending: Bool {
        return identity.pending || attached.pending || started.pending || (cancelled.pending && finished.pending)
    }

    func createResult() -> ProfileResult? {
        guard !pending, let
            identity = identity.value,
            attached = attached.value,
            started = started.value
        else { return .none }

        return ProfileResult(identity: identity, created: created, attached: attached, started: started, cancelled: cancelled.value, finished: finished.value, children: children)
    }

    func setIdentity(_ newIdentity: OperationIdentity) -> PendingResult {
        guard identity.pending else { return self }
        return PendingResult(created: created, identity: .Value(newIdentity), attached: attached, started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func attach(_ now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingResult {
        guard attached.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: .Value(now - created), started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func start(_ now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingResult {
        guard started.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: .Value(now - created), cancelled: cancelled, finished: finished, children: children)
    }

    func cancel(_ now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingResult {
        guard cancelled.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: .Value(now - created), finished: finished, children: children)
    }

    func finish(_ now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) -> PendingResult {
        guard finished.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: .Value(now - created), children: children)
    }

    func addChild(_ child: ProfileResult) -> PendingResult {
        var newChildren = children
        newChildren.append(child)
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: finished, children: newChildren)
    }
}

public final class OperationProfiler: Identifiable, Equatable {

    enum Reporter {
        case parent(OperationProfiler)
        case reporters([OperationProfilerReporter])
    }

    public let identifier = UUID().uuidString
    let queue = Queue.utility.serial("me.danthorpe.Operations.Profiler")
    let reporter: Reporter

    var result = PendingResult(created: CFAbsoluteTimeGetCurrent() as TimeInterval, identity: .Pending, attached: .Pending, started: .Pending, cancelled: .Pending, finished: .Pending, children: [])
    var children: [OperationIdentity] = []
    var finishedOrCancelled = false

    var pending: Bool {
        return result.pending || (children.count > 0)
    }

    public convenience init(reporters: [OperationProfilerReporter]) {
        self.init(reporter: .reporters(reporters))
    }

    convenience init(parent: OperationProfiler) {
        self.init(reporter: .parent(parent))
    }

    init(reporter: Reporter) {
        self.reporter = reporter
    }

    func addMetricNow(_ now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval, forEvent event: OperationEvent) {
        queue.sync { [unowned self] in
            switch event {
            case .attached:
                self.result = self.result.attach(now)
            case .started:
                self.result = self.result.start(now)
            case .cancelled:
                self.result = self.result.cancel(now)
                self.finishedOrCancelled = true
            case .finished:
                self.result = self.result.finish(now)
                self.finishedOrCancelled = true
            default:
                break
            }
        }
        finish()
    }

    func addChildOperation(_ operation: Operation, now: TimeInterval = CFAbsoluteTimeGetCurrent() as TimeInterval) {
        if let operation = operation as? OldOperation {
            let profiler = OperationProfiler(parent: self)
            operation.addObserver(profiler)
            queue.sync { [unowned self] in
                self.children.append(operation.identity)
            }
        }
    }

    func finish() {
        guard finishedOrCancelled && !pending, let result = result.createResult() else { return }
        reporter.finishedProfilingWithResult(result)
    }
}

extension OperationProfiler.Reporter: OperationProfilerReporter {

    func finishedProfilingWithResult(_ result: ProfileResult) {
        switch self {
        case .parent(let parent):
            parent.finishedProfilingWithResult(result)
        case .reporters(let reporters):
            reporters.forEach { $0.finishedProfilingWithResult(result)  }
        }
    }
}

extension OperationProfiler: OperationProfilerReporter {

    public func finishedProfilingWithResult(_ result: ProfileResult) {
        queue.sync { [unowned self] in
            if let index = self.children.index(of: result.identity) {
                self.result = self.result.addChild(result)
                self.children.remove(at: index)
            }
        }
        finish()
    }
}

extension OperationProfiler: OperationObserverType {

    public func didAttachToOperation(_ operation: OldOperation) {
        queue.sync { [unowned self] in
            self.result = self.result.setIdentity(operation.identity)
        }
        addMetricNow(forEvent: .attached)
    }
}

extension OperationProfiler: OperationWillExecuteObserver {

    public func willExecuteOperation(_ operation: OldOperation) {
        addMetricNow(forEvent: .started)
    }
}

extension OperationProfiler: OperationDidCancelObserver {

    public func didCancelOperation(_ operation: OldOperation) {
        addMetricNow(forEvent: .cancelled)
    }
}

extension OperationProfiler: OperationDidFinishObserver {

    public func didFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        addMetricNow(forEvent: .finished)
    }
}

extension OperationProfiler: OperationDidProduceOperationObserver {

    public func operation(_ operation: OldOperation, didProduceOperation newOperation: Operation) {
        addChildOperation(newOperation)
    }
}

extension OperationProfiler: GroupOperationWillAddChildObserver {

    public func groupOperation(_ group: GroupOperation, willAddChildOperation child: Operation) {
        addChildOperation(child)
    }
}

// MARK: - Reporters

struct PrintableProfileResult: CustomStringConvertible {
    let indentation: Int
    let spacing: Int
    let result: ProfileResult

    func addRowWithInterval(_ interval: TimeInterval, text: String) -> String {
        return "\(createIndentation())+\(interval)\(createSpacing())\(text)\n"
    }

    func addRowWithInterval(_ interval: TimeInterval, forEvent event: OperationEvent) -> String {
        return addRowWithInterval(interval, text: event.description)
    }

    var description: String {
        get {
            var output = ""
            output += addRowWithInterval(result.attached, forEvent: .attached)
            output += addRowWithInterval(result.started, forEvent: .started)

            for child in result.children {
                output += "\(createIndentation())-> Spawned \(child.identity) with profile results\n"
                output += "\(PrintableProfileResult(indentation: indentation + 2, spacing: spacing, result: child))"
            }

            if let cancelled = result.cancelled {
                output += addRowWithInterval(cancelled, forEvent: .cancelled)
            }

            if let finished = result.finished {
                output += addRowWithInterval(finished, forEvent: .finished)
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
        return String(repeating: " " as UnicodeScalar, count: indentation)
    }

    func createSpacing() -> String {
        return String(repeating: " " as UnicodeScalar, count: spacing)
    }
}

public class _OperationProfileLogger<Manager: LogManagerType>: _Logger<Manager>, OperationProfilerReporter {

    public required init(severity: LogSeverity = Manager.severity, enabled: Bool = Manager.enabled, logger: LoggerBlockType = Manager.logger) {
        super.init(severity: severity, enabled: enabled, logger: logger)
    }

    public func finishedProfilingWithResult(_ result: ProfileResult) {
        operationName = result.identity.description
        info("finished profiling with results:\n\(PrintableProfileResult(result: result))")
    }
}

public typealias OperationProfileLogger = _OperationProfileLogger<LogManager>

public extension OperationProfiler {

    convenience init(_ reporter: OperationProfilerReporter = OperationProfileLogger()) {
        self.init(reporters: [reporter])
    }
}

// swiftlint:enable nesting
