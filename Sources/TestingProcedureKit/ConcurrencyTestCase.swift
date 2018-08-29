//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public protocol ConcurrencyTestResultProtocol {
    var procedures: [TestConcurrencyTrackingProcedure] { get }
    var duration: Double { get }
    var registrar: ConcurrencyRegistrar { get }
}

// MARK: - ConcurrencyTestCase

open class ConcurrencyTestCase: ProcedureKitTestCase {

    public typealias Registrar = ConcurrencyRegistrar
    public typealias TrackingProcedure = TestConcurrencyTrackingProcedure

    public var registrar: Registrar!

    public class TestResult: ConcurrencyTestResultProtocol {
        public let procedures: [TrackingProcedure]
        public let duration: TimeInterval
        public let registrar: Registrar

        public init(procedures: [TrackingProcedure], duration: TimeInterval, registrar: Registrar) {
            self.procedures = procedures
            self.duration = duration
            self.registrar = registrar
        }
    }

    public struct Expectations {
        public let checkMinimumDetected: Int?
        public let checkMaximumDetected: Int?
        public let checkAllProceduresFinished: Bool?
        public let checkMinimumDuration: TimeInterval?
        public let checkExactDetected: Int?

        public init(checkMinimumDetected: Int? = .none, checkMaximumDetected: Int? = .none, checkAllProceduresFinished: Bool? = .none, checkMinimumDuration: TimeInterval? = .none) {
            if let checkMinimumDetected = checkMinimumDetected,
                let checkMaximumDetected = checkMaximumDetected,
                checkMinimumDetected == checkMaximumDetected {
                self.checkExactDetected = checkMinimumDetected
            }
            else {
                self.checkExactDetected = .none
            }
            self.checkMinimumDetected = checkMinimumDetected
            self.checkMaximumDetected = checkMaximumDetected
            self.checkAllProceduresFinished = checkAllProceduresFinished
            self.checkMinimumDuration = checkMinimumDuration
        }
    }

    public func create(procedures count: Int = 3, delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withRegistrar registrar: Registrar) -> [TrackingProcedure] {
        return (0..<count).map { i in
            let name = "TestConcurrencyTrackingProcedure: \(i)"
            return TestConcurrencyTrackingProcedure(name: name, microsecondsToSleep: delayMicroseconds, registrar: registrar)
        }
    }

    public func concurrencyTest(operations: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TrackingProcedure) -> TrackingProcedure = { return $0 }, withExpectations expectations: Expectations) {

        concurrencyTest(operations: operations, withDelayMicroseconds: delayMicroseconds, withTimeout: timeout, withConfigureBlock: configure,
            completionBlock: { (results) in
                XCTAssertResults(results, matchExpectations: expectations)
            }
        )
    }

    public func concurrencyTest(operations: Int = 3, withDelayMicroseconds delayMicroseconds: useconds_t = 500000 /* 0.5 seconds */, withName name: String = #function, withTimeout timeout: TimeInterval = 3, withConfigureBlock configure: (TrackingProcedure) -> TrackingProcedure = { return $0 }, completionBlock completion: (TestResult) -> Void) {

        let registrar = Registrar()
        let procedures = create(procedures: operations, delayMicroseconds: delayMicroseconds, withRegistrar: registrar).map {
            return configure($0)
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        wait(forAll: procedures, withTimeout: timeout)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        completion(TestResult(procedures: procedures, duration: duration, registrar: registrar))
    }

    public func XCTAssertResults(_ results: TestResult, matchExpectations expectations: Expectations) {

        // checkAllProceduresFinished
        if let checkAllProceduresFinished = expectations.checkAllProceduresFinished, checkAllProceduresFinished {
            for i in results.procedures.enumerated() {
                XCTAssertTrue(i.element.isFinished, "Test procedure [\(i.offset)] did not finish")
            }
        }
        // exact test for registrar.maximumDetected
        if let checkExactDetected = expectations.checkExactDetected {
            XCTAssertEqual(results.registrar.maximumDetected, checkExactDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) does not equal expected: \(checkExactDetected)")
        }
        else {
            // checkMinimumDetected
            if let checkMinimumDetected = expectations.checkMinimumDetected {
                XCTAssertGreaterThanOrEqual(results.registrar.maximumDetected, checkMinimumDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) is less than expected minimum: \(checkMinimumDetected)")
            }
            // checkMaximumDetected
            if let checkMaximumDetected = expectations.checkMaximumDetected {
                XCTAssertLessThanOrEqual(results.registrar.maximumDetected, checkMaximumDetected, "maximumDetected concurrent operations (\(results.registrar.maximumDetected)) is greater than expected maximum: \(checkMaximumDetected)")
            }
        }
        // checkMinimumDuration
        if let checkMinimumDuration = expectations.checkMinimumDuration {
            XCTAssertGreaterThanOrEqual(results.duration, checkMinimumDuration, "Test duration exceeded minimum expected duration.")
        }
    }

    open override func setUp() {
        super.setUp()
        registrar = Registrar()
    }

    open override func tearDown() {
        registrar = nil
        super.tearDown()
    }
}

// MARK: - ConcurrencyRegistrar

open class ConcurrencyRegistrar {
    private struct State {
        var operations: [Operation] = []
        var maximumDetected: Int = 0
    }
    private let state = Protector(State())

    public var maximumDetected: Int {
        get {
            return state.read { $0.maximumDetected }
        }
    }
    public func registerRunning(_ operation: Operation) {
        state.write { ward in
            ward.operations.append(operation)
            ward.maximumDetected = max(ward.operations.count, ward.maximumDetected)
        }
    }
    public func deregisterRunning(_ operation: Operation) {
        state.write { ward in
            if let opIndex = ward.operations.index(of: operation) {
                ward.operations.remove(at: opIndex)
            }
        }
    }
}

// MARK: - TestConcurrencyTrackingProcedure

open class TestConcurrencyTrackingProcedure: Procedure {
    private(set) weak var concurrencyRegistrar: ConcurrencyRegistrar?
    let microsecondsToSleep: useconds_t

    init(name: String = "TestConcurrencyTrackingProcedure", microsecondsToSleep: useconds_t, registrar: ConcurrencyRegistrar) {
        self.concurrencyRegistrar = registrar
        self.microsecondsToSleep = microsecondsToSleep
        super.init()
        self.name = name
    }
    override open func execute() {
        concurrencyRegistrar?.registerRunning(self)
        usleep(microsecondsToSleep)
        concurrencyRegistrar?.deregisterRunning(self)
        finish()
    }
}

// MARK: - EventConcurrencyTrackingRegistrar

// Tracks Procedure Events and the Threads on which they occur.
// Detects concurrency issues if two events occur conccurently on two different threads.
// Use a unique EventConcurrencyTrackingRegistrar per Procedure instance.
public class EventConcurrencyTrackingRegistrar {
    public enum ProcedureEvent: Equatable, CustomStringConvertible {

        case do_Execute

        case observer_didAttach
        case observer_willExecute
        case observer_didExecute
        case observer_willCancel
        case observer_didCancel
        case observer_procedureWillAdd(String)
        case observer_procedureDidAdd(String)
        case observer_willFinish
        case observer_didFinish

        case override_procedureWillCancel
        case override_procedureDidCancel
        case override_procedureWillFinish
        case override_procedureDidFinish

        // GroupProcedure open functions
        case override_groupWillAdd_child(String)
        case override_child_willFinishWithErrors(String)

        // GroupProcedure handlers
        case group_transformChildErrorsBlock(String)

        public var description: String {
            switch self {
            case .do_Execute: return "execute()"
            case .observer_didAttach: return "observer_didAttach"
            case .observer_willExecute: return "observer_willExecute"
            case .observer_didExecute: return "observer_didExecute"
            case .observer_willCancel: return "observer_willCancel"
            case .observer_didCancel: return "observer_didCancel"
            case .observer_procedureWillAdd(let name): return "observer_procedureWillAdd [\(name)]"
            case .observer_procedureDidAdd(let name): return "observer_procedureDidAdd [\(name)]"
            case .observer_willFinish: return "observer_willFinish"
            case .observer_didFinish: return "observer_didFinish"
            case .override_procedureWillCancel: return "procedureWillCancel()"
            case .override_procedureDidCancel: return "procedureDidCancel()"
            case .override_procedureWillFinish: return "procedureWillFinish()"
            case .override_procedureDidFinish: return "procedureDidFinish()"
            // GroupProcedure open functions
            case .override_groupWillAdd_child(let child): return "groupWillAdd(child:) [\(child)]"
            case .override_child_willFinishWithErrors(let child): return "child(_:willFinishWithErrors:) [\(child)]"
            case .group_transformChildErrorsBlock(let child): return "group.transformChildErrorsBlock [\(child)]"
            }
        }
    }

    public struct DetectedConcurrentEventSet: CustomStringConvertible {
        private var array: [DetectedConcurrentEvent] = []

        public var description: String {
            var description: String = ""
            for concurrentEvent in array {
                guard !description.isEmpty else {
                    description.append("\(concurrentEvent)")
                    continue
                }
                description.append("\n\(concurrentEvent)")
            }
            return description
        }

        public var isEmpty: Bool {
            return array.isEmpty
        }

        public mutating func append(_ newElement: DetectedConcurrentEvent) {
            array.append(newElement)
        }
    }

    public struct DetectedConcurrentEvent: CustomStringConvertible {
        var newEvent: (event: ProcedureEvent, threadUUID: String)
        var currentEvents: [UUID: (event: ProcedureEvent, threadUUID: String)]

        private func truncateThreadID(_ uuidString: String) -> String {
            //let uuidString = threadUUID.uuidString
            #if swift(>=3.2)
            return String(uuidString[..<uuidString.index(uuidString.startIndex, offsetBy: 4)])
            #else
            return uuidString.substring(to: uuidString.index(uuidString.startIndex, offsetBy: 4))
            #endif
        }

        public var description: String {
            var description = "+ \(newEvent.event) (t: \(truncateThreadID(newEvent.threadUUID))) while: " /*+
             "while: \n"*/
            for (_, event) in currentEvents {
                description.append("\n\t- \(event.event) (t: \(truncateThreadID(event.threadUUID)))")
            }
            return description
        }
    }

    private struct State {
        // the current eventCallbacks
        var eventCallbacks: [UUID: (event: ProcedureEvent, threadUUID: String)] = [:]

        // maximum simultaneous eventCallbacks detected
        var maximumDetected: Int = 0

        // a list of detected concurrent events
        var detectedConcurrentEvents = DetectedConcurrentEventSet()

        // a history of all detected events (optional)
        var eventHistory: [ProcedureEvent] = []
    }

    private let state = Protector(State())

    public var maximumDetected: Int { return state.read { $0.maximumDetected } }
    public var detectedConcurrentEvents: DetectedConcurrentEventSet { return state.read { $0.detectedConcurrentEvents } }
    public var eventHistory: [ProcedureEvent]? { return (recordHistory) ? state.read { $0.eventHistory } : nil }

    private let recordHistory: Bool

    public init(recordHistory: Bool = false) {
        self.recordHistory = recordHistory
    }

    private let kThreadUUID: NSString = "run.kit.procedure.ProcedureKit.Testing.ThreadUUID"
    private func registerRunning(_ event: ProcedureEvent) -> UUID {
        // get current thread data
        let currentThread = Thread.current
        func getThreadUUID(_ thread: Thread) -> String {
            guard !thread.isMainThread else {
                return "main"
            }
            if let currentThreadUUID = currentThread.threadDictionary.object(forKey: kThreadUUID) as? UUID {
                return currentThreadUUID.uuidString
            }
            else {
                let newUUID = UUID()
                currentThread.threadDictionary.setObject(newUUID, forKey: kThreadUUID)
                return newUUID.uuidString
            }
        }

        let currentThreadUUID = getThreadUUID(currentThread)
        return state.write { ward -> UUID in
            var newUUID = UUID()
            while ward.eventCallbacks.keys.contains(newUUID) {
                newUUID = UUID()
            }
            if ward.eventCallbacks.count >= 1 {
                // determine if all existing event callbacks are on the same thread
                // as the new event callback
                if !ward.eventCallbacks.filter({ $0.1.threadUUID != currentThreadUUID }).isEmpty {
                    ward.detectedConcurrentEvents.append(DetectedConcurrentEvent(newEvent: (event: event, threadUUID: currentThreadUUID), currentEvents: ward.eventCallbacks))
                }
            }
            ward.eventCallbacks.updateValue((event, currentThreadUUID), forKey: newUUID)
            ward.maximumDetected = max(ward.eventCallbacks.count, ward.maximumDetected)
            if recordHistory {
                ward.eventHistory.append(event)
            }
            return newUUID
        }
    }

    private func deregisterRunning(_ uuid: UUID) {
        state.write { ward -> Bool in
            return ward.eventCallbacks.removeValue(forKey: uuid) != nil
        }
    }

    public func doRun(_ callback: ProcedureEvent, withDelay delay: TimeInterval = 0.0001, block: (ProcedureEvent) -> Void = { _ in }) {
        let id = registerRunning(callback)
        if delay > 0 {
            usleep(UInt32(delay * TimeInterval(1000000)))
        }
        block(callback)
        deregisterRunning(id)
    }
}

// MARK: - ConcurrencyTrackingObserver

open class ConcurrencyTrackingObserver: ProcedureObserver {

    private var registrar: EventConcurrencyTrackingRegistrar!
    public let eventQueue: DispatchQueueProtocol?
    let callbackBlock: (Procedure, EventConcurrencyTrackingRegistrar.ProcedureEvent) -> Void

    public init(registrar: EventConcurrencyTrackingRegistrar? = nil, eventQueue: DispatchQueueProtocol? = nil, callbackBlock: @escaping (Procedure, EventConcurrencyTrackingRegistrar.ProcedureEvent) -> Void = { _, _ in }) {
        if let registrar = registrar {
            self.registrar = registrar
        }
        self.eventQueue = eventQueue
        self.callbackBlock = callbackBlock
    }

    public func didAttach(to procedure: Procedure) {
        if let eventTrackingProcedure = procedure as? EventConcurrencyTrackingProcedureProtocol {
            if registrar == nil {
                registrar = eventTrackingProcedure.concurrencyRegistrar
            }
            doRun(.observer_didAttach, block: { callback in callbackBlock(procedure, callback) })
        }
    }

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        doRun(.observer_willExecute, block: { callback in callbackBlock(procedure, callback) })
    }

    public func did(execute procedure: Procedure) {
        doRun(.observer_didExecute, block: { callback in callbackBlock(procedure, callback) })
    }

    public func will(cancel procedure: Procedure, with: Error?) {
        doRun(.observer_willCancel, block: { callback in callbackBlock(procedure, callback) })
    }

    public func did(cancel procedure: Procedure, with: Error?) {
        doRun(.observer_didCancel, block: { callback in callbackBlock(procedure, callback) })
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        doRun(.observer_procedureWillAdd(newOperation.operationName), block: { callback in callbackBlock(procedure, callback) })
    }

    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        doRun(.observer_procedureDidAdd(newOperation.operationName), block: { callback in callbackBlock(procedure, callback) })
    }

    public func will(finish procedure: Procedure, with error: Error?, pendingFinish: PendingFinishEvent) {
        doRun(.observer_willFinish, block: { callback in callbackBlock(procedure, callback) })
    }

    public func did(finish procedure: Procedure, with error: Error?) {
        doRun(.observer_didFinish, block: { callback in callbackBlock(procedure, callback) })
    }

    public func doRun(_ callback: EventConcurrencyTrackingRegistrar.ProcedureEvent, withDelay delay: TimeInterval = 0.0001, block: (EventConcurrencyTrackingRegistrar.ProcedureEvent) -> Void = { _ in }) {
        registrar.doRun(callback, withDelay: delay, block: block)
    }
}

// MARK: - EventConcurrencyTrackingProcedure

public protocol EventConcurrencyTrackingProcedureProtocol {
    var concurrencyRegistrar: EventConcurrencyTrackingRegistrar { get }
}

// Tracks the concurrent execution of various user code
// (observers, `execute()` and other function overrides, etc.)
// automatically handles events triggered from within other events
// (as long as everything happens on the same thread)
open class EventConcurrencyTrackingProcedure: Procedure, EventConcurrencyTrackingProcedureProtocol {
    public private(set) var concurrencyRegistrar: EventConcurrencyTrackingRegistrar
    private let delay: TimeInterval
    private let executeBlock: (EventConcurrencyTrackingProcedure) -> Void
    public init(name: String = "EventConcurrencyTrackingProcedure", withDelay delay: TimeInterval = 0, registrar: EventConcurrencyTrackingRegistrar = EventConcurrencyTrackingRegistrar(), baseObserver: ConcurrencyTrackingObserver? = ConcurrencyTrackingObserver(), execute: @escaping (EventConcurrencyTrackingProcedure) -> Void) {
        self.concurrencyRegistrar = registrar
        self.delay = delay
        self.executeBlock = execute
        super.init()
        self.name = name
        if let baseObserver = baseObserver {
            addObserver(baseObserver)
        }
    }
    open override func execute() {
        concurrencyRegistrar.doRun(.do_Execute, withDelay: delay, block: { _ in
            executeBlock(self)
        })
    }
    // Cancellation Handler Overrides
    open override func procedureDidCancel(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureDidCancel)
        super.procedureDidCancel(with: error)
    }
    // Finish Handler Overrides
    open override func procedureWillFinish(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureWillFinish)
        super.procedureWillFinish(with: error)
    }
    open override func procedureDidFinish(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureDidFinish)
        super.procedureDidFinish(with: error)
    }
}

open class EventConcurrencyTrackingGroupProcedure: GroupProcedure, EventConcurrencyTrackingProcedureProtocol {
    public private(set) var concurrencyRegistrar: EventConcurrencyTrackingRegistrar
    private let delay: TimeInterval
    public init(dispatchQueue underlyingQueue: DispatchQueue? = nil, operations: [Operation], name: String = "EventConcurrencyTrackingGroupProcedure", withDelay delay: TimeInterval = 0, registrar: EventConcurrencyTrackingRegistrar = EventConcurrencyTrackingRegistrar(), baseObserver: ConcurrencyTrackingObserver? = ConcurrencyTrackingObserver()) {
        self.concurrencyRegistrar = registrar
        self.delay = delay
        super.init(dispatchQueue: underlyingQueue, operations: operations)
        self.name = name
        if let baseObserver = baseObserver {
            addObserver(baseObserver)
        }
        // GroupProcedure transformChildErrorsBlock
        transformChildErrorBlock = { [concurrencyRegistrar] (child, _) in
            concurrencyRegistrar.doRun(.group_transformChildErrorsBlock(child.operationName))
        }
    }
    open override func execute() {
        concurrencyRegistrar.doRun(.do_Execute, withDelay: delay, block: { _ in
            super.execute()
        })
    }
    // Cancellation Handler Overrides
    open override func procedureDidCancel(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureDidCancel)
        super.procedureDidCancel(with: error)
    }
    // Finish Handler Overrides
    open override func procedureWillFinish(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureWillFinish)
        super.procedureWillFinish(with: error)
    }
    open override func procedureDidFinish(with error: Error?) {
        concurrencyRegistrar.doRun(.override_procedureDidFinish)
        super.procedureDidFinish(with: error)
    }

    // GroupProcedure Overrides
    open override func groupWillAdd(child: Operation) {
        concurrencyRegistrar.doRun(.override_groupWillAdd_child(child.operationName))
        super.groupWillAdd(child: child)
    }
    open override func child(_ child: Procedure, willFinishWithError error: Error?) {
        concurrencyRegistrar.doRun(.override_child_willFinishWithErrors(child.operationName))
        return super.child(child, willFinishWithError: error)
    }
}
