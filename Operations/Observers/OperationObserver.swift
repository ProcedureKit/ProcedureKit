//
//  OperationObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/// A protocol which operation observers must conform to.
public protocol OperationObserver {
    
    func operationDidStart(operation: Operation)
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation)
    
    func operationDidFinish(operation: Operation, errors: [ErrorType])
}
