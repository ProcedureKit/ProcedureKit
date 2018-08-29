# Mutual Exclusion

- Remark: Makes Procedures exclusive


A [`Condition`](Classes\/Condition.html) can assert whether its Procedure should be evaluated exclusively with respect to other Procedures. This can be very handy for preventing Procedures from executing at the same time.

For example, if our application presents a modal alert, by adding a mutually exclusive condition, it will prevent any other modal alert from being presented at the same time. Given the nature of event based applications this would otherwise be quite tricky. We would write this:

```swift
import ProcedureKitMobile

let alert = AlertProcedure(presentAlertFrom: viewController)
alert.title = NSLocalizedString("Hello World", comment: "Hello World")
queue.addOperation(alert)
```

`AlertProcedure` adds a mutually exclusive condition to itself during its initializer.

- Note: Mutual exclusion does not stop subsequent Procedures from ever running. The Procedure will run once the mutually-exclusive blocking Procedure in front of it finishes.

## Implementation

To add mutual exclusion to an operation, we attach a [`MutuallyExclusive<T>()`](Classes\/MutuallyExclusive.html) condition, in the case of `AlertProcedure` it is implemented like this:

```swift
procedure.add(condition: MutuallyExclusive<UIAlertController>())
```

which means that any subsequent procedure which is also mutually exclusive with `UIAlertController` will wait until the current one has finished.

This generic type, let call it the _mutual exclusion type_ has no constraints: it can be anything.

### How to choose the mutual exclusion type?

If it is only necessary to restrict the same type of Procedure from executing then use the Procedure's own class, or parent class, as the type.

To share mutual exclusion between a number of different Procedure, either create an empty `enum` which will be used to define the mutual exclusion. Name it based on the category of procedure, for example:

```swift
public enum CoreDataWork { }
```

Then in the procedure, add a condition for mutual exclusion:

```swift
procedure.add(condition: MutuallyExclusive<CoreDataWork>())
```

## Using the `category` string

The _mutual exclusion type_ is a convenience to add some strong typing to `MutualExclusion`. However if using `String` categories names is easier, that works too:

```swift
procedure.add(condition: MutuallyExclusive<Void>(category: "mutually exclusive key")
```

obviously we would recommend using static constants for these, or `String` backed `enum` types.
