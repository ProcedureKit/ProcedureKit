//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
Allows a `NSOperation` to be composed inside an `Operation`. This
is very handy for applying `Operation` level features such as 
conditions and observers to `NSOperation` instances.
*/
public class ComposedOperation<O: NSOperation>: GatedOperation<O> {

    /**
    Designated initializer.
    
    - parameter operation: The composed operation, must be a `NSOperation` subclass.
    */
    public init(operation: O) {
        super.init(operation: operation, gate: { true })
    }
}




