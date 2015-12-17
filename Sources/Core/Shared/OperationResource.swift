//
//  OperationResource.swift
//  Operations
//
//  Created by di, frank (CHE-LPR) on 12/17/15.
//
//

import Foundation

public protocol OperationResourceProvider {
    
    func dependencyForOperation(operation: Operation) -> NSOperation?
    
    func collectResourceForOperation(operation: Operation, completion: Any? -> Void)
}

struct OperationResourceCollector {
    
    static func collect(providers: [OperationResourceProvider], operation: Operation, completion: [String: Any] -> Void) {
        
        let group = dispatch_group_create()
        
        var collected = [Any?](count: providers.count, repeatedValue: nil)
        
        for (index, provider) in providers.enumerate() {
            dispatch_group_enter(group)
            provider.collectResourceForOperation(operation) { result in
                collected[index] = result
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, Queue.Default.queue) {
            let resources = collected.flatMap { $0 }
            let namedResources = resources.reduce([String: Any]()) {
                dict, result in
                var merge = dict
                let name = String(result.dynamicType)
                merge[name] = result
                return merge
            }
            completion(namedResources)
        }
    }
}