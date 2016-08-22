//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length

import Foundation.NSOperation

// swiftlint:disable type_body_length

open class Procedure: Operation, ProcedureProcotol {

    private enum State: Int, Comparable {

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case initialized
        case pending
        case executing
        case finishing
        case finished

        func canTransition(to other: State, whenCancelled isCancelled: Bool) -> Bool {
            switch (self, other) {
            case (.initialized, .pending),
                 (.pending, .executing),
                 (.executing, .finishing),
                 (.finishing, .finished):
                return true

            case (.pending, .finishing) where isCancelled:
                // When an operation is cancelled it can go from pending direct to finishing.
                return true

            default:
                return false
            }
        }
    }

    /**
     Type to express the intent of the user in regards to executing an Operation instance

     - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
     */
    @objc public enum UserIntent: Int {
        case none = 0, sideEffect, initiated

        internal var qos: QualityOfService {
            switch self {
            case .initiated, .sideEffect:
                return .userInitiated
            default:
                return .default
            }
        }
    }



    private var _isTransitioningToExecuting = false
    private var _isHandlingFinish = false
    private var _isHandlingCancel = false
    private var _isCancelled = false  // should always be set by .cancel()


    fileprivate let isAutomaticFinishingDisabled: Bool




    // State


    private var _state = State.initialized
    private let _stateLock = NSRecursiveLock()

    fileprivate var state: State {
        get {
            return _stateLock.withCriticalScope { _state }
        }
        set(newState) {
            _stateLock.withCriticalScope {
                assert(_state.canTransition(to: newState, whenCancelled: isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState).")
//                assert(_state.canTransition(to: newState, whenCancelled: isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity).")
//                log.verbose("\(_state) -> \(newState)")
                _state = newState
            }
        }
    }

    /// Boolean indicator for whether the Operation is currently executing or not
    final public override var isExecuting: Bool {
        return state == .executing
    }

    /// Boolean indicator for whether the Operation has finished or not
    final public override var isFinished: Bool {
        return state == .finished
    }

    /// Boolean indicator for whether the Operation has cancelled or not
    final public override var isCancelled: Bool {
        return _stateLock.withCriticalScope { _isCancelled }
    }

    private var shouldCancel: Bool {
        return _stateLock.withCriticalScope {
            // Do not cancel if already finished or finishing, or cancelled
            guard state <= .executing && !_isCancelled else { return false }
            // Only a single call to cancel should continue
            guard !_isHandlingCancel else { return false }
            _isHandlingCancel = true
            return true
        }
    }

    private var shouldFinish: Bool {
        return _stateLock.withCriticalScope {
            let shouldFinish = isExecuting && !isAutomaticFinishingDisabled && !_isHandlingFinish
            if shouldFinish {
                _isHandlingFinish = true
            }
            return shouldFinish
        }
    }


    // Errors

    private var _errors = [Error]()

    public var errors: [Error] {
        return _stateLock.withCriticalScope { _errors }
    }

    public var failed: Bool {
        return errors.count > 0
    }


    // Observers

    private var _observers = Protector([AnyObserver<Procedure>]())

    fileprivate(set) var observers: [AnyObserver<Procedure>] {
        get { return _observers.read { $0 } }
        set {
            _observers.write { (ward: inout [AnyObserver<Procedure>]) in
                ward = newValue
            }
        }
    }





    internal private(set) var directDependencies = Set<Operation>()
//    internal private(set) var conditions = Set<Condition>()
//    internal private(set) var evaluateConditionsOperation: GroupOperation? = .None

//    internal var indirectDependencies: Set<Operation> {
//        return Set(conditions
//            .flatMap { $0.directDependencies }
//            .filter { !directDependencies.contains($0) }
//        )
//    }



//    private var _log = Protector<LoggerType>(Logger())

    // MARK: - Initialization

    public override init() {
        self.isAutomaticFinishingDisabled = false
        super.init()
    }

    // MARK: - Execution

    public func willEnqueue() {
        state = .pending
    }

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    public final override func start() {
        // Don't call super.start

        guard !isCancelled || isAutomaticFinishingDisabled else {
            finish()
            return
        }

        main()
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    public final override func main() {

        // Prevent concurrent execution
        func getNextState() -> State? {
            return _stateLock.withCriticalScope {

                // Check to see if the procedure is already attempting to execute
                assert(!isExecuting, "Procedure is attempting to execute, but is already executing.")
                guard !_isTransitioningToExecuting else {
                    assertionFailure("Procedure is attempting to execute twice, concurrently.")
                    return nil
                }

                // Check to see if the procedure has now been finished
                // by an observer (or anything else)
                guard state <= .pending else { return nil }

                // Check to see if the procedure has now been cancelled
                // by an observer
                guard (_errors.isEmpty && !isCancelled) || isAutomaticFinishingDisabled else {
                    _isHandlingFinish = true
                    return .finishing
                }

                // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
                _isTransitioningToExecuting = true
                return .executing
            }
        }

        // Check the state again, as it could have changed in another queue via finish
        func getNextStateAgain() -> State? {
            return _stateLock.withCriticalScope {
                guard state <= .pending else { return nil }

                state = .executing
                _isTransitioningToExecuting = false

                if isCancelled && !isAutomaticFinishingDisabled && !_isHandlingFinish {
                    // Procedure was cancelled, automatic finishing is enabled,
                    // but cancel is not (yet/ever?) handling the finish.
                    // Because cancel could have already passed the check for executing,
                    // handle calling finish here.
                    _isHandlingFinish = true
                    return .finishing
                }
                return .executing
            }
        }

        observers.forEach { $0.will(execute: self) }

        let nextState = getNextState()

        guard nextState != .finishing else {
            // TODO - finish from cancel true
            return
        }

        guard nextState == .executing else { return }

        willChangeValue(forKey: .executing)

        let nextState2 = getNextStateAgain()

        didChangeValue(forKey: .executing)

        guard nextState2 != .finishing else {
            // TODO - finish from cancel true
            return
        }

        guard nextState2 == .executing else { return }

        // TODO - log

        execute()
    }

    public func execute() {
        print("\(self) must override `execute()`.")
        finish()
    }



    // MARK: Cancellation


    public func cancel(withError error: Error?) {
        cancel(withErrors: error.map { [$0] } ?? [])
    }

    public func cancel(withErrors errors: [Error]) {
        _stateLock.withCriticalScope {
            if !errors.isEmpty {
                // TODO
            }
            _errors += errors
        }
        cancel()
    }

    public final override func cancel() {

        guard shouldCancel else { return }

        procedureWillCancel(withErrors: errors)
        willChangeValue(forKey: .cancelled)
        observers.forEach { $0.will(cancel: self, withErrors: errors) }

        _stateLock.withCriticalScope { _isCancelled = true }

        procedureDidCancel(withErrors: errors)
        observers.forEach { $0.did(cancel: self, withErrors: errors) }
        // TODO - log
        didChangeValue(forKey: .cancelled)

        // Call super to trigger .isReady state change on cancel
        // as well as isReady KVO notification
        super.cancel()

        if shouldFinish {
            // TODO - finish from cancel
        }
    }



    // Observers


}


// MARK: - Finishing

public extension Procedure {

    /**
     Finish method which must be called eventually after an operation has
     begun executing, unless it is cancelled.

     - parameter errors: an array of `Error`, which defaults to empty.
     */
    final func finish(withErrors errors: [Error] = []) {
        // TODO
    }
}

// MARK: Observers

public extension Procedure {

    /**
     Add an observer to the to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Procedure {

        observers.append(AnyObserver(base: observer))

        observer.didAttach(to: self)
    }


}

// swiftlint:enable type_body_length

fileprivate extension Operation {

    enum KeyPath: String {
        case cancelled = "isCancelled"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    fileprivate func willChangeValue(forKey key: KeyPath) {
        willChangeValue(forKey: key.rawValue)
    }

    fileprivate func didChangeValue(forKey key: KeyPath) {
        didChangeValue(forKey: key.rawValue)
    }
}


// swiftlint:enable file_length
