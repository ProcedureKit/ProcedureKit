# Advanced Result Injection

- Remark: Functional state transform

In [Result Injection](result-injection.html) we introduced the basic concept of _transforming state_ by chaining procedures together. Each link in the change received an input, and is responsible for settings its output. This works very nicely at a simple level, but is a bit restrictive when it comes to real world usage.

## Binding

Typically, the scenario described above would be encapsulated in a [`GroupProcedure`](Classes\/GroupProcedure.html). However, the initial `Input` property, and final `Output` property should then be exposed at the group level. This requires the group's `input` property to be set on the first child procedure, and to observe the last procedure in the chain to extract it's `output` property.

This can be quite frustrating to write more than once, but luckily there is a helper API for this called `bind(to:)` and `bind(from:)`.

```swift
class MyGroup: TestGroupProcedure, InputProcedure, OutputProcedure {

    var input: Pending<Foo> = .pending
    var output: Pending<ProcedureResult<Bar>> = .pending

    init() {

        let stage1 = TransformProcedure<Foo,Baz> { /* etc */ }

		let stage2 = TransformProcedure<Baz,Bat> { /* etc */ }
		    .injectResult(from: stage1)

		let stage3 = TransformProcedure<Bat,Bar> { /* etc */ }
		    .injectResult(from: stage3)

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


