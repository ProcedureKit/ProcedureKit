//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ComposedOperation<O: NSOperation>: GatedOperation<O> {

    /**
    Designated initializer.
    
    - parameter o: The operation to compose.
    */
    public init(operation: O) {
        super.init(operation: operation, gate: { true })
    }
}




