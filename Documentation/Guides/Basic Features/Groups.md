# Groups

- Remark: Groups encapsulate Procedures into a single logic unit


_ProcedureKit_ makes it easy to decompose significant work into smaller chunks of work which can be combined together. This is always a good architectural practice, as it will reduce the impact of each component and increase their re-use and testability. However, it can be unwieldy and diminish code readability.

Therefore we can create more abstract notions of _work_ by using a [`GroupProcedure`](Classes\/GroupProcedure.html).

## Direct usage

[`GroupProcedure`](Classes\/GroupProcedure.html) can be used directly.

```swift
let group = GroupProcedure(operations: opOne, opTwo, opThree)
group.addDidFinishBlockObserver { (group, errors)  in
    // The group has finished, meaning all child operations 
    // have finished. From here you can access them.
    print("children: \(group.children)")
}
queue.add(operation: group)
```

There are a couple of key points here.

1. Child operations need only be [`Foundation.Operation`](https://developer.apple.com/documentation/foundation/operation) instances, not necessarily [`Procedure`](Classes\/Procedure.html) subclasses. So, a group can be used with Apple's `Operation` subclasses or from elsewhere.

2. The operation instances added to the group are referred to as its children, and can be accessed via its [`.children`](Classes\/GroupProcedure.html#\/s:vC12ProcedureKit14GroupProcedure8childrenGSaCSo9Operation_) property.

3. A [`GroupProcedure`](Classes\/GroupProcedure.html) runs until its last child finishes. This means, that it is possible to add additional children while it is running.
    ```swift
    group.add(child: opFour)
    group.add(children: [opFive, opSix])
    ```
    This is also a crucial detail, and is used for a host of features which `GroupProcedure` enables.

## Custom `GroupProcedure`

While using a [`GroupProcedure`](Classes\/GroupProcedure.html) directly is convenient, it doesn't really help to create a larger abstraction of work around the children. For example, consider authenticating a user with a webservice - it is likely that we will need: network requests, possibly some data parsing and mapping, and possibly writing to disks or caches. All of these tasks should be [`Procedure`](Classes\/Procedure.html) subclasses, but when encapsulated together, its just a `LoginProcedure`. The group _hides_ all the detail. Therefore, most of the time, we want to subclass [`GroupProcedure`](Classes\/GroupProcedure.html), which is the focus of this guide.  

## The initialiser

If all the child operations are known at compile time they can be configured during initialization. Configuration would be things such as setting dependencies, observers, conditions.

```swift
class LoginProcedure: GroupProcedure {

    // Nested class definitions to help componentize Login
    class PersistLoginInfo: Operation { /* etc */ }
    class LoginSessionTask: NSURLSessionTask { /* etc */ }
    
    init(credentials: Credentials /* etc, inject known dependencies */) {

        // Create the child operations
        let persist = PersistLoginInfo(credentials)
        let login = URLSessionTaskOperation(task: LoginSessionTask(credentials))
        
        // Do any configuration or setup
        persist.addDependency(login)
        
        // Call the super initializer with the operations
        super.init(operations: [persist, login])
        
        // Configure any properties, such as name.
        name = "Login"
        
        // Add observers, conditions etc to the group
        add(observer: NetworkObserver())
        add(condition: MutualExclusive<LoginProcedure>())
    }
}
```

The initialization strategy shown above is relatively simple but shows some good practices. Creating and configuring child operations before calling the `LoginProcedure` initialiser reduces the complexity and increases the readability of the class. Adding observers and conditions to the group inside its initialiser sets the default and expected behaviour which makes using the class easier. Remember that these can always be nullified by using [`ComposedProcedure`](Classes\/ComposedProcedure.html).

## Adding child operations later

In some cases, the results of one child are needed by a subsequent child. We cover techniques to achieve this in [Result Injection](result-injection.html) which still applies here. However, this doesn't cover a critical scenario which is branching. A common usage might be to perform either operation `Bar` or `Baz` depending on `Foo`, which cannot be setup during initialisation.

```swift
class FooBarBazProcedure: GroupProcedure {
    /* etc */

    override func child(_ child: Procedure, willFinishWithErrors errors: [ErrorType]) {
        super.child(child: willFinishWithErrors: errors)    
        guard !isCancelled else { return }
        if errors.isEmpty, let foo = child as? FooProcedure {
           if foo.doBaz {
              add(child: BazProcedure())
           }
           else {
              add(child: BarProcedure())
           }
        }
    }
}
```

The above function exists primarily to allow subclasses to perform actions when each child operation finishes.  Therefore a standard operation should:

1. Call the `super` implementation.
2. Check that the group has not been cancelled
3. Inspect and handle any errors
4. Test the received operation to check that it is the expected instance. For example, optionally cast it to the expected type, and if possible check if it is equal to a stored property of the group.
5. Call `add(child:)` or `add(children:)` to add more operations to the queue.

Using this technique the group will keep executing and only finish until all children, including ones added after the group started, have finished.

## Cancelling

[`GroupProcedure`](Classes\/GroupProcedure.html) itself already responds to cancellation correctly: Its behaviour is to call `cancel()` on all of its children and wait for them to finish before it finishes.

However, sometimes additional behavior is warranted. Consider operations that are injected into a [`GroupProcedure`](Classes\/GroupProcedure.html). By definition, these are exposed outside the group, and in some scenarios may be cancelled by external factors. For example, a network procedure that is injected may be cancelled by the user or system. In a scenario such as this, it often makes sense for a cancelled child to result in the entire group being cancelled.

Therefore, a good practice when subclassing [`GroupProcedure`](Classes\/GroupProcedure.html) is to add *DidCancel* observers to injected operations. Lets modify our `LoginProcedure` to inject the network session task:

```swift
// Lets assume we have a network procedure
class LoginSessionTask: MyNetworkingProcedure { /* etc */ }

class LoginProcedure: GroupProcedure {

    class PersistLoginInfo: Procedure { /* etc */ }
    
    let task: MyNetworkingProcedure
    
    init(credentials: Credentials, task: MyNetworkingProcedure) {
        self.task = task
        
        // Create the child operations
        let persist = PersistLoginInfo(credentials)

        // Do any configuration or setup
        persist.add(dependency: task)

        // Call the super initializer with the operations
        super.init(operations: [persist, login])
        
        // Configure any properties, such as name.
        name = "Login"
        
        // Add observers, conditions etc to the group
        add(observer: NetworkObserver())
        add(condition: MutualExclusive<LoginProcedure>())
 
        // Add cancellation observer to injected procedures
        task.addDidCancelBlockObserver { [weak self] (task, errors) in 
            self?.cancel()
        }
    }       
}
``` 

- Important:
Sometimes it is necessary to perform such configuration (which references `self`) after the initializer has finished. For these situations, override `execute` but *always* call `super.execute()`. This is because the [`GroupProcedure`](Classes\/GroupProcedure.html) has critical functionality in its `execute` implementation (such as starting the queue).

We will cover move advanced usage of [`GroupProcedure`](Classes\/GroupProcedure.html) in [Advanced Groups](advanced-groups.html). Also, see [`ComposedProcedure`](Classes\/ComposedProcedure.html) on how to wrap an `Operation` class, to be able to add observers.
