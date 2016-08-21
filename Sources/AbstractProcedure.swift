//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length

import Foundation.NSOperation

// swiftlint:disable type_body_length

open class AbstractProcedure: Operation, ProcedureProcotol {

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

    private let _stateLock = NSRecursiveLock()
    private var _state = State.initialized

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



    // Errors

    private var _errors = [Error]()

    public var errors: [Error] {
        return _stateLock.withCriticalScope { _errors }
    }

    public var failed: Bool {
        return errors.count > 0
    }


    // Observers

    private var _observers = Protector([AnyObserver<AbstractProcedure>]())

    fileprivate(set) var observers: [AnyObserver<AbstractProcedure>] {
        get { return _observers.read { $0 } }
        set {
            _observers.write { (ward: inout [AnyObserver<AbstractProcedure>]) in
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

    public func execute() {
        print("\(self) must override `execute()`.")
        finish()
    }







}


// MARK: - Execution

public extension AbstractProcedure {


    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    final override func start() {
        // Don't call super.start

        guard !isCancelled || isAutomaticFinishingDisabled else {
            finish()
            return
        }

        main()
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    final override func main() {
        // TODO
        execute()
    }
}

// MARK: - Finishing

public extension AbstractProcedure {

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

public extension AbstractProcedure {

    /**
     Add an observer to the to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == AbstractProcedure {

        observers.append(AnyObserver(base: observer))

        observer.didAttach(to: self)
    }


}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
