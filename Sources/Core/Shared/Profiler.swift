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
        return name.map { "\($0) #\(identifier)" } ?? "Unnamed Operation #\(identifier)"
    }
}

public extension Operation {

    var identity: OperationIdentity {
        return OperationIdentity(identifier: identifier, name: name)
    }
}

public protocol OperationProfilerReporter {
    func finishedProfilingWithResult(result: ProfileResult)
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
        return .None
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
    public let created: NSTimeInterval
    public let attached: NSTimeInterval
    public let started: NSTimeInterval
    public let cancelled: NSTimeInterval?
    public let finished: NSTimeInterval?
    public let children: [ProfileResult]
}

struct PendingResult {

    let created: NSTimeInterval
    let identity: PendingValue<OperationIdentity>
    let attached: PendingValue<NSTimeInterval>
    let started: PendingValue<NSTimeInterval>
    let cancelled: PendingValue<NSTimeInterval>
    let finished: PendingValue<NSTimeInterval>
    let children: [ProfileResult]

    var pending: Bool {
        return identity.pending || attached.pending || started.pending || (cancelled.pending && finished.pending)
    }

    func createResult() -> ProfileResult? {
        guard !pending, let
            identity = identity.value,
            attached = attached.value,
            started = started.value
        else { return .None }

        return ProfileResult(identity: identity, created: created, attached: attached, started: started, cancelled: cancelled.value, finished: finished.value, children: children)
    }

    func setIdentity(newIdentity: OperationIdentity) -> PendingResult {
        guard identity.pending else { return self }
        return PendingResult(created: created, identity: .Value(newIdentity), attached: attached, started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func attach(now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval) -> PendingResult {
        guard attached.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: .Value(now - created), started: started, cancelled: cancelled, finished: finished, children: children)
    }

    func start(now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval) -> PendingResult {
        guard started.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: .Value(now - created), cancelled: cancelled, finished: finished, children: children)
    }

    func cancel(now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval) -> PendingResult {
        guard cancelled.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: .Value(now - created), finished: finished, children: children)
    }

    func finish(now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval) -> PendingResult {
        guard finished.pending else { return self }
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: .Value(now - created), children: children)
    }

    func addChild(child: ProfileResult) -> PendingResult {
        var newChildren = children
        newChildren.append(child)
        return PendingResult(created: created, identity: identity, attached: attached, started: started, cancelled: cancelled, finished: finished, children: newChildren)
    }
}

public final class OperationProfiler: Identifiable, Equatable {

    enum Reporter {
        case Parent(OperationProfiler)
        case Reporters([OperationProfilerReporter])
    }

    public let identifier = NSUUID().UUIDString
    let queue = Queue.Utility.serial("me.danthorpe.Operations.Profiler")
    let reporter: Reporter

    var result = PendingResult(created: CFAbsoluteTimeGetCurrent() as NSTimeInterval, identity: .Pending, attached: .Pending, started: .Pending, cancelled: .Pending, finished: .Pending, children: [])
    var children: [OperationIdentity] = []
    var finishedOrCancelled = false

    var pending: Bool {
        return result.pending || (children.count > 0)
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

    func addMetricNow(now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval, forEvent event: OperationEvent) {
        dispatch_sync(queue) { [unowned self] in
            switch event {
            case .Attached:
                self.result = self.result.attach(now)
            case .Started:
                self.result = self.result.start(now)
            case .Cancelled:
                self.result = self.result.cancel(now)
                self.finishedOrCancelled = true
            case .Finished:
                self.result = self.result.finish(now)
                self.finishedOrCancelled = true
            default:
                break
            }
        }
        finish()
    }

    func addChildOperation(operation: NSOperation, now: NSTimeInterval = CFAbsoluteTimeGetCurrent() as NSTimeInterval) {
        if let operation = operation as? Operation {
            let profiler = OperationProfiler(parent: self)
            operation.addObserver(profiler)
            dispatch_sync(queue) { [unowned self] in
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

    func finishedProfilingWithResult(result: ProfileResult) {
        switch self {
        case .Parent(let parent):
            parent.finishedProfilingWithResult(result)
        case .Reporters(let reporters):
            reporters.forEach { $0.finishedProfilingWithResult(result)  }
        }
    }
}

extension OperationProfiler: OperationProfilerReporter {

    public func finishedProfilingWithResult(result: ProfileResult) {
        dispatch_sync(queue) { [unowned self] in
            if let index = self.children.indexOf(result.identity) {
                self.result = self.result.addChild(result)
                self.children.removeAtIndex(index)
            }
        }
        finish()
    }
}

extension OperationProfiler: OperationObserverType {

    public func didAttachToOperation(operation: Operation) {
        dispatch_sync(queue) { [unowned self] in
            self.result = self.result.setIdentity(operation.identity)
        }
        addMetricNow(forEvent: .Attached)
    }
}

extension OperationProfiler: OperationDidStartObserver {

    public func didStartOperation(operation: Operation) {
        addMetricNow(forEvent: .Started)
    }
}

extension OperationProfiler: OperationDidCancelObserver {

    public func didCancelOperation(operation: Operation) {
        addMetricNow(forEvent: .Cancelled)
    }
}

extension OperationProfiler: OperationDidFinishObserver {

    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        addMetricNow(forEvent: .Finished)
    }
}

extension OperationProfiler: OperationDidProduceOperationObserver {

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        addChildOperation(newOperation)
    }
}

extension OperationProfiler: GroupOperationWillAddChildObserver {

    public func groupOperation(group: GroupOperation, willAddChildOperation child: NSOperation) {
        addChildOperation(child)
    }
}

// MARK: - Reporters

struct PrintableProfileResult: CustomStringConvertible {
    let indentation: Int
    let spacing: Int
    let result: ProfileResult

    func addRowWithInterval(interval: NSTimeInterval, text: String) -> String {
        return "\(createIndentation())+\(interval)\(createSpacing())\(text)\n"
    }

    func addRowWithInterval(interval: NSTimeInterval, forEvent event: OperationEvent) -> String {
        return addRowWithInterval(interval, text: event.description)
    }

    var description: String {
        get {
            var output = ""
            output += addRowWithInterval(result.attached, forEvent: .Attached)
            output += addRowWithInterval(result.started, forEvent: .Started)

            for child in result.children {
                output += "\(createIndentation())-> Spawned \(child.identity) with profile results\n"
                output += "\(PrintableProfileResult(indentation: indentation + 2, spacing: spacing, result: child))"
            }

            if let cancelled = result.cancelled {
                output += addRowWithInterval(cancelled, forEvent: .Cancelled)
            }

            if let finished = result.finished {
                output += addRowWithInterval(finished, forEvent: .Finished)
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

    public func finishedProfilingWithResult(result: ProfileResult) {
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
