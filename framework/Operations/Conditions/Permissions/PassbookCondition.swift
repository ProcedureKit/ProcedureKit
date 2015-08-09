//
//  PassbookCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import Foundation
import PassKit

public protocol PassLibraryType {
    func isPassLibraryAvailable() -> Bool
}

public struct PassLibrary: PassLibraryType {

    public func isPassLibraryAvailable() -> Bool {
        return PKPassLibrary.isPassLibraryAvailable()
    }
}

public struct PassbookCondition: OperationCondition {

    public enum Error: ErrorType {
        case LibraryNotAvailable
    }

    public let name = "Passbook"
    public let isMutuallyExclusive = false

    private let library: PassLibraryType

    public init() {
        self.init(library: PassLibrary())
    }

    /**
        Testing Interface only, use

            init()
    */
    public init(library: PassLibraryType) {
        self.library = library
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if library.isPassLibraryAvailable() {
            completion(.Satisfied)
        }
        else {
            completion(.Failed(Error.LibraryNotAvailable))
        }
    }
}

public func ==(a: PassbookCondition.Error, b: PassbookCondition.Error) -> Bool {
    switch (a, b) {
    case (.LibraryNotAvailable, .LibraryNotAvailable): return true
    default: return false
    }
}

#endif
