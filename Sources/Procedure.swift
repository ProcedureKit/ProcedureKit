//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length

import Foundation.NSOperation

// swiftlint:disable type_body_length

open class Procedure: Operation {

    private enum State: Int, Comparable {

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case initialized
        case pending
        case executing
        case finishing
        case finished

        func canTransitionToState(other: State, whenCancelled cancelled: Bool) -> Bool {
            switch (self, other) {
            case (.initialized, .pending),
                 (.pending, .executing),
                 (.executing, .finishing),
                 (.finishing, .finished):
                return true

            case (.pending, .finishing) where cancelled:
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

    // State

    private let stateLock = NSRecursiveLock()
    private let disableAutomaticFinishing: Bool
    private var _isTransitioningToExecuting = false
    private var _state = State.initialized
    private var _isHandlingFinish = false
    private var _isHandlingCancel = false
    private var _cancelled = false  // should always be set by .cancel()






    private var _internalErrors = [Error]()



    private var _observers = Protector([ProcedureObserver]())

    fileprivate(set) var observers: [ProcedureObserver] {
        get { return _observers.read { $0 } }
        set {
            _observers.write { (ward: inout [ProcedureObserver]) in
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
        self.disableAutomaticFinishing = false
        super.init()
    }

}


// MARK: Observers

public extension Procedure {

    /**
     Add an observer to the to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    func add(observer: ProcedureObserver) {

        observers.append(observer)

        observer.didAttach(to: self)
    }

    internal var willExecuteObservers: [WillExecuteProcedureObserver] {
        return observers.flatMap { $0 as? WillExecuteProcedureObserver }
    }

    internal var willCancelObservers: [WillCancelProcedureObserver] {
        return observers.flatMap { $0 as? WillCancelProcedureObserver }
    }

    internal var didCancelObservers: [DidCancelProcedureObserver] {
        return observers.flatMap { $0 as? DidCancelProcedureObserver }
    }

    internal var didProduceOperationObservers: [DidProduceOperationProcedureObserver] {
        return observers.flatMap { $0 as? DidProduceOperationProcedureObserver }
    }

    internal var willFinishObservers: [WillFinishProcedureObserver] {
        return observers.flatMap { $0 as? WillFinishProcedureObserver }
    }

    internal var didFinishObservers: [DidFinishProcedureObserver] {
        return observers.flatMap { $0 as? DidFinishProcedureObserver }
    }

}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
