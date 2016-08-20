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

    private let stateLock = NSRecursiveLock()
    private let disableAutomaticFinishing: Bool

//    private var _log = Protector<LoggerType>(Logger())
    private var _state = State.initialized
    private var _internalErrors = [Error]()
    private var _isTransitioningToExecuting = false
    private var _isHandlingFinish = false
    private var _isHandlingCancel = false
    private var _observers = Protector([ProcedureObserver]())
    private var _cancelled = false  // should always be set by .cancel()

    internal private(set) var directDependencies = Set<Operation>()
//    internal private(set) var conditions = Set<Condition>()
//    internal private(set) var evaluateConditionsOperation: GroupOperation? = .None

//    internal var indirectDependencies: Set<Operation> {
//        return Set(conditions
//            .flatMap { $0.directDependencies }
//            .filter { !directDependencies.contains($0) }
//        )
//    }




    // MARK: - Initialization

    public override init() {
        self.disableAutomaticFinishing = false
        super.init()
    }


    // MARK: - Add Observer

    /**
     Add an observer to the to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    public func add(observer: ProcedureObserver) {

        observer.didAttach(to: self)
    }

}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
