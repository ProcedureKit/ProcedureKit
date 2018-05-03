# Advanced Result Injection

- Remark: Functional state transformation

In [Result Injection](result-injection.html) we introduced the basic concept of _transforming state_ by chaining procedures together. Each link in the chain received an input, and is responsible for settings its output. The `injectResult(from:)` API then glues everything together. 

This works very nicely at a simple level, however it is a bit restrictive when it comes to real world usage. While we firmly advocate writing small single purpose procedures, chaining these together can result in code which is a little _ungaily_. What to do...

## Binding

Typically, the scenario described above would be encapsulated in a [`GroupProcedure`](Classes\/GroupProcedure.html). However, the initial `Input` property, and final `Output` property should then be exposed at the group level. This requires the group's `input` property to be set on the first child procedure, and to observe the last procedure in the chain to extract it's `output` property.

This can be quite frustrating to write more than once, but luckily there are helper APIs for this called `bind(to:)` and `bind(from:)`.

```swift
class MyGroup: TestGroupProcedure, InputProcedure, OutputProcedure {

    var input: Pending<Foo> = .pending
    
    var output: Pending<ProcedureResult<Bar>> = .pending

    init() {

        let stage1 = TransformProcedure<Foo,Baz> { /* etc */ }

		let stage2 = TransformProcedure<Baz,Bat> { /* etc */ }
		    .injectResult(from: stage1)

		let stage3 = TransformProcedure<Bat,Bar> { /* etc */ }
		    .injectResult(from: stage2)

		super.init(operations: [stage1, stage2, stage3])

		// Bind the group's input property to the first procedure
		bind(to: stage1)

		// Bind the group's output property from the last procedure		
		bind(from: stage3)
	}
}
```

These two APIs will automatically add appropriate observers to the procedures to ensure that the `input` property is set when the receiver's `input` property is set via the `injectResult(from:)` API.

Note that if the `input` property is set manually, the observers will not fire and so the binding will not work. Consider the above class:

```swift
let foo = ResultProcedure { Foo() } // This is a procedure which creates a Foo output

let myGroup = MyGroup() // This expects to be injected with a Foo value

myGroup.injectResult(from: foo) // This does the injection, and triggers the binding.

queue.add(operations: foo, myGroup)

myGroup.addDidFinishBlockObserver { (group, _, _) in 
    // group output will now be set
}
```


