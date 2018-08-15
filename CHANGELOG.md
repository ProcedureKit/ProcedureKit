# 5.0.0
This is a _rather long-awaited_ next major version of ProcedureKit.

## Headline Changes
1. Networking procedures no longer use an associated type for the `URLSession`. Instead `Session` is a free-floating protocol. This makes general usage, subclassing and composing much simpler.
2. There is now a Core Data module
3. `BlockProcedure` API has changed.
4. `Procedure` only supports a single `Error` value, instead of `[Error]` - this has had some fairly wide reaching changes to APIs.
5. New built-in logger, which uses `os_log` by default.
6. Changes to `UIProcedure` in _ProcedureKitMobile_ module.

## Breaking Changes
1. [[823](https://github.com/ProcedureKit/ProcedureKit/pull/823)]: Removes associated types from Network

    Originally raised as an [issue](https://github.com/ProcedureKit/ProcedureKit/issues/814) by [@ericyanush](https://github.com/ericyanush) in which I totally missed the point initially. But, after thinking about it more, made so much sense. Instead of having a generic `URLSessionTaskFactory` protocol, where the various types of tasks were associated types, we now just have a non-generic `NetworkSession` protocol, to which `URLSession` conforms. The impact of this subtle change, is that what was once: `NetworkDataProcedure<Session: URLSessionTaskFactory>` is now `NetworkDataProcedure`. In otherwords, no longer generic, and now super easy to use as that generic `Session` doesn't leak all over the place.
    
2. [[#875](https://github.com/ProcedureKit/ProcedureKit/pull/875)]: Refactored `BlockProcedure`

    There has been a long-standing wish for `BlockProcedure` instances to "receive themselves" in their block to allow for access to its logger etc. In v5, the following is all possible, see this [comment](https://github.com/ProcedureKit/ProcedureKit/pull/875#issuecomment-410502324):
    
    1. Simple synchronous block (existing functionality):
        ```swift
        let block = BlockProcedure { 
            print("Hello World")
        }
        ```

    2. Synchonous block, accessing the procedure inside the block:
        ```swift
        let block = BlockProcedure { this in
            this.log.debug.message("Hello World")
            this.finish()
        }
        ```
        Note that here, the block is responsible for finishing itself - i.e. call `.finish()` or `.finish(with:)` to finish the Procedure. Using this initializer, by default, `BlockProcedure` will add a `TimeoutObserver` to itself, using `defaultTimeoutInterval` which is set to 3 seconds. This can be modified if needed.
        ```swift
        BlockProcedure.defaultTimeoutInterval = 5
        ```

    3. Asynchronous block with cancellation check, `AsyncBlockProcedure` and `CancellableBlockProcedure` get deprecated warnings.
        ```swift
        let block = BlockProcedure { this in
            guard !this.isCancelled else { this.finish() }
            DispatchQueue.default.async {
               print("Hello world")
               this.finish()
            }
        }
        ```

    4. `ResultProcedure` as been re-written as a subclass of `BlockProcedure` (previously, it was the superclass). Existing functionality has been maintained:
        ```swift
        let hello = ResultProcedure { "Hello World" }
        ```
3. [[#851](https://github.com/ProcedureKit/ProcedureKit/pull/851)]: Errors
    
    At WWDC18 I spent some time with some Swift engineers from Apple talking about framework design and error handling. The key take-away from these discussions was to _increase clarity_ which reduces confusion, and makes _intent_ clear. 
    
    This theme drove some significant changes. To increase clarity, each Procedure can only have a single `Error`, because ultimately, how can a framework consumer "handle" an array of `Error` values over just a single one? I realised that the only reason `Procedure` has an `[Error]` property at all was from `GroupProcedure` collecting all of the errors from its children, yet the impact of this is felt throughout the codebase. 
    
    This means, to finish a procedure with an error, use:    
    ```swift
    finish(with: .downloadFailedError) // this is a made up error type
    ```
    
    Observers only receive a single error now:
    ```swift
    procedure.addDidFinishBlockObserver { (this, error) in
        guard let error = error else {
            // there is an error, the block argument is Error? type
	    return
        }
	
	// etc
    }
    ```
    
    Plus more API changes in `Procedure` and `GroupProcedure` which will result in deprecation warnings for framework consumers.
    
    For `GroupProcedure` itself, it will now only set its own error to the first error received. However, to access the errors from child procedures, use the `.children` property. Something like:
    ```swift
    let errors = group.children.operationsAndProcedures.1.compactMap { $0.error }
    ```
    
4. [[#861](https://github.com/ProcedureKit/ProcedureKit/pull/861), [#870](https://github.com/ProcedureKit/ProcedureKit/pull/870)]: Logger

    _ProcedureKit_ has its own logging system, which has received an overhawl in v5. The changes are:
    
        1. Now uses `os_log` instead of `print()` where available.
	2. Dedicated severity levels for caveman debugging & user event. See this [comment](https://github.com/ProcedureKit/ProcedureKit/pull/861#issuecomment-404058717).
	3. Slight API change:
	    ```swift
   	    procedure.log.info.message("This is my debug message")
	    ```
	    previously, it was:
	    ```swift
	    procedure.log.info("This is my debug message")
	    ```
	    For module-wide settings:
	    ```swift
	    Log.enabled = true
	    Log.severity = .debug // default is .warning
	    Log.writer = CustomLogWriter() // See LogWriter protocol
	    Log.formatter = CustomLogFormatter() // See LogFormatter protocol
	    ```
5. [[#860](https://github.com/ProcedureKit/ProcedureKit/pull/860)]: Swift 3/4 API naming & conventions

    [@lukeredpath](https://github.com/lukeredpath) initially raised the issue in [#796](https://github.com/ProcedureKit/ProcedureKit/issues/796), that some APIs such as `add(condition: aCondition)` did not Swift 3/4 API guidelines, and contributed to inconsistency within the framework. These have now been tidied up.

## New Features & Improvements
1. [[#830](https://github.com/ProcedureKit/ProcedureKit/pull/830), [#837](https://github.com/ProcedureKit/ProcedureKit/pull/837)]: Swift 4.1 & Xcode 9.3 support, (Xcode 10 is ready to go).
    
    These changes take advantage of Swift 4.1 capabilities, such as synthesized `Equatable` and conditional conformance.

2. [[#828](https://github.com/ProcedureKit/ProcedureKit/pull/828), [#833](https://github.com/ProcedureKit/ProcedureKit/pull/833)]: Result Injection & Binding
    
    Result Injection conformance is added to `RepeatProcedure` (and subclasses such as `RetryProcedure` & `NetworkProcedure`). This means the input can be set on the out `RepeatProcedure`, and this value will be set on every instance of the target procedure (assuming it also conforms to `InputProcedure`). This avoids having to jump through hoops like [this](https://github.com/ProcedureKit/ProcedureKit/issues/876).
    
    Additionally, a new _binding_ API can be used, particularly with `GroupProcedure` subclasses, so that the input of a child procedure is "bound" to that of the group itself, likewise, the output of the group is bound to a child. This makes it very easy to encapsulate a chain of procedures which use result injection into a `GroupProcedure` subclass. See [the docs](http://procedure.kit.run/development/advanced-result-injection.html).

3. [[#834](https://github.com/ProcedureKit/ProcedureKit/pull/834)]: Adds `BatchProcedure`
    
    `BatchProcedure` is a `GroupProcedure` subclass which can be used to batch process a homogeneous array of objects, so that we get `[T] -> [V]` via a procedure which does `T -> V`. We already have `MapProcedure` which does this via a closure, and so is synchronous, and useful for simple data transforms. `BatchProcedure` allows asynchronous processing via a custom procedure. This is actually a pretty common situation in production apps. For example, consider an API response for a gallery of images, we can use `BatchProcedure` to get all the images in the gallery.

4. [[#838](https://github.com/ProcedureKit/ProcedureKit/pull/838)]: Adds `IgnoreErrorsProcedure`
    
    `IgnoreErrorsProcedure` will safely wrap another procedure to execute it and suppress any errors. This can be useful for _fire, forget and ignore_ type behavior.

5. [[#843](https://github.com/ProcedureKit/ProcedureKit/pull/843), [#844](https://github.com/ProcedureKit/ProcedureKit/pull/844), [#847](https://github.com/ProcedureKit/ProcedureKit/pull/847), [#849](https://github.com/ProcedureKit/ProcedureKit/pull/849)]: Adds _ProcedureKitCoreData_.

    - [x] `LoadCoreDataProcedure` - intended to be subclassed by framework consumers for their project, see the docs.
    - [x] `MakeFetchedResultControllerProcedure`
    - [x] `SaveManagedObjectContext`
    - [x] `InsertManagedObjectsProcedure`
    - [x] `MakesBackgroundManagedObjectContext` - a protocol to allow mixed usage of `NSPersistentContainer`, `NSManagedObjectContext` and `NSPersistentStoreCoordinator`.

6. [[#840](https://github.com/ProcedureKit/ProcedureKit/pull/840), [#858](https://github.com/ProcedureKit/ProcedureKit/pull/858), [#868](https://github.com/ProcedureKit/ProcedureKit/pull/868)]: Adds `UIBlockProcedure`

    `UIBlockProcedure` replaces `UIProcedure`, and it essentially is a block which will always run on the main queue. It is the basis for other UI procedures.

7. [[#841](https://github.com/ProcedureKit/ProcedureKit/pull/841), [#873](https://github.com/ProcedureKit/ProcedureKit/pull/873), [#874](https://github.com/ProcedureKit/ProcedureKit/pull/874)]: Adds `UIViewController` containment procedures

    - [x] `AddChildViewControllerProcedure`
    - [x] `RemoveChildViewControllerProcedure`
    - [x] `SetChildViewControllerProcedure`
    
    All of these procedures provide configurable auto-layout options. By default the child view controller's view is "pinned" to the bounds of the parent view. However, it is possible to use custom auto-layout behaviour.

## Notes

Thanks to everyone who has contributed to _ProcedureKit_ - v5 has been quite a while in development. There is still quite a bit left to do on the documentation effort - but that will be ongoing for evermore.


# 4.5.0

## Swift 4.0

1. [#816](https://github.com/ProcedureKit/ProcedureKit/pull/816) Updates for Xcode 9.2 and Swift 4.0. Thanks to [@jshier](https://github.com/jshier) for making the updates. Included here are updates to the Travis config too.

## Improvements
1. [#781](https://github.com/ProcedureKit/ProcedureKit/pull/781) Some significant performance and reliability improvements for `BackgroundObserver` by [@swiftlyfalling](https://github.com/swiftlyfalling).

## Deprecations
1. [#818](https://github.com/ProcedureKit/ProcedureKit/pull/818) `UserIntent` property on `Procedure` has been deprecated. Suggestion is to set the underlying queue priority. 


# 4.4.0

## Breaking Change
1. [#787](https://github.com/ProcedureKit/ProcedureKit/pull/787) Updates to a minimum version of watchOS 3. Technically, this is a breaking change, but, realistically, anyone building for  Watch will be at least on watchOS 3 now. 

## Others
1. [#802](https://github.com/ProcedureKit/ProcedureKit/pull/802) Updates iOS Simulators to iOS 11 in Fastlane
2. [#801](https://github.com/ProcedureKit/ProcedureKit/pull/801) Removes SwiftLint
3. [#795](https://github.com/ProcedureKit/ProcedureKit/pull/795) Fixes an issue with Conditions and suspended ProcedureQueues



# 4.3.2

1. [#790](https://github.com/ProcedureKit/ProcedureKit/issues/790),[#791](https://github.com/ProcedureKit/ProcedureKit/pull/791) Fixes a mistake which hid the initialiser of `ReverseGeocodeUserLocation` which renders it un-usable 🙄. Thanks to [Anatoliy](https://github.com/eastsss) for raising the issue. There really aught to be some way of having autogenerated tests for this type of bug.
2. [#793](https://github.com/ProcedureKit/ProcedureKit/pull/793) Migrates _ProcedureKit_'s CI to a complementary account on [BuildKite](http://buildkite.com/procedurekit). You will still need an account to view this, however, it means that open source contributors can be added to the BK account without cost. Please get in touch if you want an invite. Thanks to [@keithpitt](https://github.com/keithpitt) and [@ticky](https://github.com/ticky) for migrating our pipeline & history between orgs.

    In addition to this, I have setup a Mac in MacStadium, in addition to my own build server. This means that we should have effectively got _constant_ uptime of agents to build CI.
    
    In light of these changes, I've disabled the Travis service, which has proved to be slow and un-reliable. The `travis.yml` will stay and remain working for anyone who maintains their own fork. 

# 4.3.1

1. [#785](https://github.com/ProcedureKit/ProcedureKit/pull/785) To get round an error with Xcode 9 betas archiving applications. 

# 4.3.0

## Documentation

1. [#750](https://github.com/ProcedureKit/ProcedureKit/pull/750), [#762](https://github.com/ProcedureKit/ProcedureKit/pull/762), [#763](https://github.com/ProcedureKit/ProcedureKit/pull/763), [#751](https://github.com/ProcedureKit/ProcedureKit/pull/751), [#766](https://github.com/ProcedureKit/ProcedureKit/pull/766), [#767](https://github.com/ProcedureKit/ProcedureKit/pull/767), [#768](https://github.com/ProcedureKit/ProcedureKit/pull/768), [#771](https://github.com/ProcedureKit/ProcedureKit/pull/771), [#772](https://github.com/ProcedureKit/ProcedureKit/pull/772), [#773](https://github.com/ProcedureKit/ProcedureKit/pull/773), [#775](https://github.com/ProcedureKit/ProcedureKit/pull/775), [#779](https://github.com/ProcedureKit/ProcedureKit/pull/779) Numerous improvements to project documentation.
2. Docs are a combination of source code documentation and a programming guide. It is built as the code changes as part of the CI system, and published on [procedure.kit.run](http://procedure.kit.run) with a path matching the branch. Therefore, the most up-to-date documentation is: [procedure.kit.run/development](http://procedure.kit.run/development).
3. The programming guide is written in Markdown, and stored in the repo under `Documentation/Guides`
4. Documentation is generated using [jazzy](http://github.com/realm/jazzy) and organised via `.jazzy.json` file. It can be generated locally by running `jazzy --config .jazzy.json` from the project root.
5. Because documentation is built as part of CI, it should evolve with the code, and the documentation for WIP branches can be built, published and viewed.
6. Eventually the documentation site will allow framework consumers to browse versions of the programming guide.
7. Current documentation coverage is 53%. This is reported in a shield on the project page.
    
## Other Improvements

1. [#757](https://github.com/ProcedureKit/ProcedureKit/pull/757) Improves the `QualityOfService` tests.
2. [#756](https://github.com/ProcedureKit/ProcedureKit/pull/756) Fixes a rare race condition involving `Condition`.
3. [#752](https://github.com/ProcedureKit/ProcedureKit/pull/752), [#754](https://github.com/ProcedureKit/ProcedureKit/pull/754) Resolves `ProcedureObserver` errors in Xcode 9 Beta 3 onwards.
4. [#769](https://github.com/ProcedureKit/ProcedureKit/pull/769) Fixes a race condition in `TestProcedure`.
5. [#770](https://github.com/ProcedureKit/ProcedureKit/pull/770), [#774](https://github.com/ProcedureKit/ProcedureKit/pull/774) Fixes unstable tests related to producing operations.
6. [#777](https://github.com/ProcedureKit/ProcedureKit/pull/777) Simplifies `Procedure.ConditionEvaluator` state management.

## Other Notes

- I ([@danthorpe](https://github.com/danthorpe)) changed the _code of conduct_ to comply with GitHub's notion of what a code of conduct is. Quite frankly, this is annoying, please feel free to contact me if you find the [changes](https://github.com/ProcedureKit/ProcedureKit/commit/6a15f80da6fdf6ffaf918a8f21f984212502e0e1) disagreeable.

# 4.2.0

## Breaking Changes
1. [#717](https://github.com/ProcedureKit/ProcedureKit/pull/717) Termination status & termination reason provided to handler (full details in PR).
2. [#737](https://github.com/ProcedureKit/ProcedureKit/pull/737) Simplifies `GroupProcedure` child error handling, so that it is now centralised in a single, better named method: `child(_:willFinishWithErrors:)`

## Swift 4
1. [@swiftlyfalling](https://github.com/swiftlyfalling) has gone through the entire project and fixes Swift 4 released issues so that _ProcedureKit_ will work in Xcode 9 beta without issue. Critically, we have not yet changed the build settings for Swift 4 - but this is the last release for Swift 3.
2. [#739](https://github.com/ProcedureKit/ProcedureKit/pull/739) Fixes complication of `ProcedureEventQueue` in Xcode 9, when in Swift 3 mode.

## Tweaks & Improvements
1. [#715](https://github.com/ProcedureKit/ProcedureKit/pull/715) Improves the `.then { }` API so that _all_ operations in the receiver are added as dependents of the argument.
2. [#717](https://github.com/ProcedureKit/ProcedureKit/pull/717) Improves `ProcessProcedure` so that can be used with result injection and dispatches using its internal queue.
3. [#738](https://github.com/ProcedureKit/ProcedureKit/pull/738) Adds `transformChildErrorsBlock` to `GroupProcedure`. This will enable customisation of the errors with `GroupProcedure` without subclassing.


## Stability & Bug Fixes
1. [#710](https://github.com/ProcedureKit/ProcedureKit/pull/710), [#711](https://github.com/ProcedureKit/ProcedureKit/pull/711), [#712](https://github.com/ProcedureKit/ProcedureKit/pull/712) Lots of robustness fixes for tests.
2. [#714](https://github.com/ProcedureKit/ProcedureKit/pull/714) Fixes a (rare) data race in DelayProcedure.
3. [#721](https://github.com/ProcedureKit/ProcedureKit/pull/721) Adds missing `tearDown` overrides to `CloudKitProcedure` tests.
4. [#722](https://github.com/ProcedureKit/ProcedureKit/pull/722) Fixes a memory cycle in `makeFinishingProcedure` in the testing framework helpers.
5. [#724](https://github.com/ProcedureKit/ProcedureKit/pull/724) Reduces dependencies on BuildKite agents by adding Travis CI.  

# 4.1.0

1. Swift 3.1 fixes for Xcode 8.3

# 4.0.1

Same as Beta 7 😀

# 4.0.0 Beta 7

## Breaking Changes
1. [#668](https://github.com/ProcedureKit/ProcedureKit/pull/668) Adds Procedure event queue. Procedure now utilises an internal serial FIFO queue which dispatched user "events". Procedure events include anything that calls user code, like overridden methods, observer callbacks, injecting results from a dependency. See the PR for more details, there are some breaking changes here, which is very well documented in the PR description.
2. [#681](https://github.com/ProcedureKit/ProcedureKit/pull/681) [@swiftlyfalling](https://github.com/swiftlyfalling) Refactors how Condition is implemented. There are breaking changes here which are well documented in PR description.

## New APIs & Enhancements
1. [#662](https://github.com/ProcedureKit/ProcedureKit/pull/662), [#673](https://github.com/ProcedureKit/ProcedureKit/pull/673) Improves the TimeoutObserver implementation by utilising a registrar to handle the lifetime of timers. By [@swiftlyfalling](https://github.com/swiftlyfalling).
2. [#658](https://github.com/ProcedureKit/ProcedureKit/issues/658), [#659](https://github.com/ProcedureKit/ProcedureKit/pull/659) Adds Repeatable type.
3. [#663](https://github.com/ProcedureKit/ProcedureKit/pull/663) Fixes building when using Swift Package Manager.
4. [#664](https://github.com/ProcedureKit/ProcedureKit/pull/664) Improves Swift 3 URLError handling in Network procedures.
5. [#690](https://github.com/ProcedureKit/ProcedureKit/pull/690) Adds `UserConfirmationCondition` as in _Operations_.
6. [#676](https://github.com/ProcedureKit/ProcedureKit/pull/676) Enhances `AnyProcedure` to allow for `AnyOutputProcedure`. Thanks to [@sviatoslav](https://github.com/sviatoslav).

## Bug Fixes
1. [#660](https://github.com/ProcedureKit/ProcedureKit/issues/660), [#661](https://github.com/ProcedureKit/ProcedureKit/pull/661) Fixes a string conversion memory leak, which is actually a bug in Swift itself.
2. [#666](https://github.com/ProcedureKit/ProcedureKit/pull/666) Fixes code signing issues that prevents compiling release configuration builds.
3. [#669](https://github.com/ProcedureKit/ProcedureKit/pull/669) Fixes a type to Dan's GitHub profile.
4. [#677](https://github.com/ProcedureKit/ProcedureKit/pull/677) Restricts `RetryProcedure` to only allow `Procedure` subclasses.
5. [#679](https://github.com/ProcedureKit/ProcedureKit/pull/679) `AuthorizedFor` condition now ensures that the produced `AuthorizedCapabilityProcedure` is mutually exclusive, rather than the procedure it gets attached to.
6. [#689](https://github.com/ProcedureKit/ProcedureKit/pull/689) Updates SwiftLint ruleset.
7. [#687](https://github.com/ProcedureKit/ProcedureKit/pull/687) Uses `dependencyCancelledWithErrors` error context.

# 4.0.0 Beta 6
_ProcedureKit_ is nearing a final v4 release. Beta 6 sees all functionality that will be added for v4 in place. Some breaking changes around cancellation are currently being discussed, and will come in the next (and hopefully last) beta.

In this release, [@swiftlyfalling](https://github.com/swiftlyfalling) has been doing amazing work finding, fixing and adding tests for race-conditions, memory leaks, general thread-safety and cancellation. It really has been fantastic. Currently, over 83% for all components on average. 

## New APIs
1. [#631](https://github.com/ProcedureKit/ProcedureKit/issues/631), [#632](https://github.com/ProcedureKit/ProcedureKit/pull/632) Result injection is now supported for `NetworkDataProcedure` et. al. This API is called `injectPayload(fromNetwork:)` and will support functionality like this:
    ```swift
    // Procedure to get a network request
    let getRequest = GetRequest()
    // Procedure to get the Data payload
    let network = NetworkDataProcedure()
        // Inject the URLRequest
        .injectResult(from: getRequest)
    // Procedure to decode the data payload
    let decode = DecodeNetworkPayload()
        // Inject the network payload
        .injectPayload(fromNetwork: network)
    ```
    Thanks to [@robfeldmann](https://github.com/robfeldmann) for raising the initial issue.
2. [#592](https://github.com/ProcedureKit/ProcedureKit/pull/592) Adds `UIProcedure` and `AlertProcedure` as part of _ProcedureKitMobile_ framework. Usage is like this:
    ```swift
    let alert = AlertProcedure(presentAlertFrom: self)
    alert.add(actionWithTitle: "Sweet") { alert, action in
        alert.log.info(message: "Running the handler!")
    }
    alert.title = "Hello World"
    alert.message = "This is a message in an alert"
    queue.add(operation: alert)
    ```

1. [#623](https://github.com/ProcedureKit/ProcedureKit/issues/623) Adds `ProcedureKit/All` CocoaPod sub-spec which corresponds to all the cross platform components.
2. [#625](https://github.com/ProcedureKit/ProcedureKit/issues/625) Tweaks for _TestingProcedureKit_ imports.
3. [#626](https://github.com/ProcedureKit/ProcedureKit/issues/626),  [#627](https://github.com/ProcedureKit/ProcedureKit/issues/627),[#640](https://github.com/ProcedureKit/ProcedureKit/pull/640), [#646](https://github.com/ProcedureKit/ProcedureKit/pull/646) Tweaks Network procedures so that cancellation is thread safe, avoids a potential race condition, and testing enhancements.
4. [#624](https://github.com/ProcedureKit/ProcedureKit/issues/624) Some minor fixes after a through investigation with the visual memory debugger - which can produce erroneous leak indicators.
6. [#630](https://github.com/ProcedureKit/ProcedureKit/issues/630) Adds a build step to CI to perform integration testing using CocoaPods works with the current changes on a feature branch. Currently this does not work for 3rd party contributions.
7. [#634](https://github.com/ProcedureKit/ProcedureKit/issues/634) Fixes some copy/paste typos from a merge conflict.
8. [#635](https://github.com/ProcedureKit/ProcedureKit/pull/635) Removes the fatal override of `waitUntilFinished()`.
9. [#639](https://github.com/ProcedureKit/ProcedureKit/pull/639) Thread safety improvements to `ProcedureProcedure` in _ProcedureKitMac_.
10. [#643](https://github.com/ProcedureKit/ProcedureKit/pull/643) Further testing of `DidExecute` observers. Adds `checkAfterDidExecute` API to `ProcedureKitTestCase`.
11. [#649](https://github.com/ProcedureKit/ProcedureKit/pull/649) Removes all code signing settings.
12. [#644](https://github.com/ProcedureKit/ProcedureKit/pull/644) Fixes issues for _ProcedureKitCloud_ in Xcode 8.2 - as they've changed some APIs here.
13. [#647](https://github.com/ProcedureKit/ProcedureKit/pull/647) Marks non-open properties/methods as `final`.
14. [#650](https://github.com/ProcedureKit/ProcedureKit/pull/650) Adds more tests for cancelling `Condition` subclasses.
15. [#655](https://github.com/ProcedureKit/ProcedureKit/pull/655) Removes the beta tag from the internal framework versioning.

# 4.0.0 Beta 5
Beta 5 is primarily about refinements and bug fixes.

## Breaking API Changes
1. [#574](https://github.com/ProcedureKit/ProcedureKit/issues/574), [#583](https://github.com/ProcedureKit/ProcedureKit/pull/583) Removal of `GroupObserverProtocol`
    This protocol was to allow observer to be attached to a group, and be informed when children are added to the group. Instead, this functionality has been rolled into `ProcedureObserver`.
2. [#601](https://github.com/ProcedureKit/ProcedureKit/pull/601), [#605](https://github.com/ProcedureKit/ProcedureKit/pull/605) Refactor of `ResultInjection`.
    The `ResultInjection` protocol has been overhauled, again. The major changes here, are:
    - Change to a pair of protocols, `InputProcedure` and  `OutputProcedure`, with associated type `Input` and `Output` respectively. This change is to avoid overloading the "result" concept.
    - Renames `PendingValue<T>` to just `Pending`. Both protocols have properties which are `Pending`, which in turn maintains  the `.pending` and `.ready` cases.
    - `ProcedureResult<T>` which is an _either_ enum type, which is either `.success(value)` or `.failure(error)`. The error is not an associated type - so any `Error` will do.
    - `OutputProcedure`'s `output` property is `Pending<ProcedureResult<Output>>` which means that it can now capture the procedure finishing with an error instead of just a value.

    In addition, `Procedure` subclasses which conform to `OutputProcedure` can use the following API:
    
    ```swift
    /// Finish the procedure with a successful result.
    finish(withResult: .success(outputValue))

    /// Finish the procedure with an error.
    finish(withResult: .failure(anError))    
    ``` 
    
    To support `OutputProcedure` with a `Void` output value, there is also a public constant called `success` which represents `.success(())`.
    
    All other APIs have been changed to reflect this change, e.g. `injectResult(from: dependency)` works as before if your receiver is updated to conform to `OutputProcedure`.
3. [#561](https://github.com/ProcedureKit/ProcedureKit/pull/561) Rename & refactor of `ResilientNetworkProcedure`
    `NetworkProcedure` now performs the functionality of network resiliency, in addition to automatic handling of client reachability errors.


## New Features
1. [#565](https://github.com/ProcedureKit/ProcedureKit/pull/565) `NetworkDownloadProcedure`
    Thanks to [@yageek](https://github.com/yageek) for adding support for network file downloads.
2. [#567](https://github.com/ProcedureKit/ProcedureKit/pull/567) `NetworkUploadProcedure`
    Thanks to [@yageek](https://github.com/yageek) for adding support for network file uploads.
3. [#570](https://github.com/ProcedureKit/ProcedureKit/pull/570) `ProcessProcedure`
    Thanks to [@yageek](https://github.com/yageek) for adding support for wrapping `Process` (previously `NSTask`) to _ProcedureKitMac_.
4. [#542](https://github.com/ProcedureKit/ProcedureKit/pull/542), [#599](https://github.com/ProcedureKit/ProcedureKit/pull/599) `CloudKitProcedure`
    This is a wrapper class for running Apple's `CKOperation` subclasses.
5. [#587](https://github.com/ProcedureKit/ProcedureKit/pull/587) Mutual Exclusion categories
    Mutually exclusive conditions now support arbitrary category names, which means that a condition can be used to add mutual exclusion to any number of disparate procedures.
6. [#563](https://github.com/ProcedureKit/ProcedureKit/pull/563) `NetworkProcedure` (called `NetworkReachableProcedure` here)
    `NetworkProcedure` is a wrapper procedure for executing network procedures. It has full support for handling client reachability issues, and resilient handling of client and server errors.  
7. [#569](https://github.com/ProcedureKit/ProcedureKit/issues/569) `Profiler`
    Thanks to [@yageek](https://github.com/yageek) for implementing the `Profiler` which is a `ProcedureObserver` and can be used to report timing profiles of procedures.
8. [#593](https://github.com/ProcedureKit/ProcedureKit/pull/593) Supports the merging of collections of `Procedure` subclasses which all conform to `ResultInjection`.
    These APIs `flatMap`, `reduce` and `gathered()` each return another procedure which will depend on all other procedures in the collection, and then perform synchronous processing of the results. For example, either just gather the results into a single array, or flat map the resultant array into an array of different types, or reduce the resultant array into a single type.
9. [#606](https://github.com/ProcedureKit/ProcedureKit/pull/606), [#607](https://github.com/ProcedureKit/ProcedureKit/pull/607) `AsyncResultProcedure` etc.
    `AsyncResultProcedure`, `AsyncBlockProcedure` and `AsyncTransformProcedure` support asynchronous blocks. Each procedure's initialiser receives a _finishWithResult_ closure, which must be called to finish the procedure. For example:
    
    ```swift
    let procedure = AsyncBlockProcedure { finishWithResult in
        asyncTask {
            finishWithResult(success)
        }
    }
    ```



## Bug Fixes etc
1. [#562](https://github.com/ProcedureKit/ProcedureKit/pull/562) Fixes a typo in `LocationServicesRegistrarProtocol`
2. [#566](https://github.com/ProcedureKit/ProcedureKit/pull/566) Fixes `Condition` so that it can support result injection.
3. [#575](https://github.com/ProcedureKit/ProcedureKit/pull/575) Improves the performance of `add(observer: )`.
4. [#568](https://github.com/ProcedureKit/ProcedureKit/pull/578) Opens up `add(operation: Operation)` for overriding by subclasses. Thanks to [@bizz84](https://github.com/bizz84).
6. [#579](https://github.com/ProcedureKit/ProcedureKit/pull/579) Adds more test coverage to `GroupProcedure`.
7. [#586](https://github.com/ProcedureKit/ProcedureKit/issues/586) Fixes `HTTPRequirement` initializers. Thanks to [@yageek](https://github.com/yageek) for this one.
8. [#588](https://github.com/ProcedureKit/ProcedureKit/pull/588) Fixes bug where using the `produce(operation:)` from a `GroupProcedure` subclass was failing. This was actually introduced by other changes since Beta 4.
9. [#591](https://github.com/ProcedureKit/ProcedureKit/pull/591) Adds some missing equality checks in `ProcedureKitError.Context`.
10. [#600](https://github.com/ProcedureKit/ProcedureKit/pull/600) Minor changes to remove @testable imports.
11. [#602](https://github.com/ProcedureKit/ProcedureKit/pull/602) Adds stress tests for cancelling `RepeatProcedure`.
12. [#603](https://github.com/ProcedureKit/ProcedureKit/pull/603) Adds more `GroupProcedure` tests.
13. [#608](https://github.com/ProcedureKit/ProcedureKit/pull/608) Uses the internal queue for the `DispatchAfter` delayed functionality in `NetworkActivityController` instead of the main queue.
14. [#611](https://github.com/ProcedureKit/ProcedureKit/pull/611) Restores `import Foundation` etc where needed in all classes, which makes Xcode 8 a little happier - although not strictly necessary.
15. [#615](https://github.com/ProcedureKit/ProcedureKit/pull/615) Fixes issues where `BackgroundObserver` was not removing notification observers.
16. [#619](https://github.com/ProcedureKit/ProcedureKit/pull/619) Fixes some issues with location related procedures.

## Thread Safety bug fixes
Recently, [@swiftlyfalling](https://github.com/swiftlyfalling) has been fixing a number of thread safety issues highlighted either from our own stress tests, or from the Thread Sanitizer. 
1. `NetworkObserver` - [#577](https://github.com/ProcedureKit/ProcedureKit/pull/577)
2. `StressTestCase` - [#596](https://github.com/ProcedureKit/ProcedureKit/pull/596) 
3. `RepeatProcedure` - [#597](https://github.com/ProcedureKit/ProcedureKit/pull/597)
4. `Procedure` - [#598](https://github.com/ProcedureKit/ProcedureKit/pull/598)
5. `NetworkDataProcedure` etc - [#609](https://github.com/ProcedureKit/ProcedureKit/pull/609)
6. `BackgroundObserver` - [#614](https://github.com/ProcedureKit/ProcedureKit/pull/614)
7. `DelayProcedure` - [#616](https://github.com/ProcedureKit/ProcedureKit/pull/616)

# 4.0.0 Beta 4
Beta 4 is a significant maturation over Beta 3. There are a couple of breaking changes here which I will call out explicitly. Overall however, the APIs have been refined, adjusted and extended, bugs have been fixed, and tests have been stabilised.

Additionally, Beta 4 now supports integration via Carthage _and CocoaPods_ including full support for _TestingProcedureKit_ and CocoaPod subspecs.

## Breaking API Changes
1. [#519](https://github.com/ProcedureKit/ProcedureKit/pull/519) Renames 
    - `AuthorizationStatusProtocol` to `AuthorizationStatus`. 
    Thanks to [@martnst](https://github.com/martnst).
2. [#520](https://github.com/ProcedureKit/ProcedureKit/pull/520) Renames:
    - `GetAuthorizationStatus` to `GetAuthorizationStatusProcedure`, 
    - `Authorize` to `AuthorizeCapabilityProcedure`
    Thanks to [@martnst](https://github.com/martnst) again.
3. [#527](https://github.com/ProcedureKit/ProcedureKit/pull/527), [#528](https://github.com/ProcedureKit/ProcedureKit/pull/528), [#541](https://github.com/ProcedureKit/ProcedureKit/pull/541), [#546](https://github.com/ProcedureKit/ProcedureKit/pull/546) ResultInjection 

    ResultInjection, which is what we call the methodology of automatically injecting the result from one procedure as the requirement of a dependency, has been revamped in Beta 4.
    - It is now an extension on `ProcedureProctocol`.
    - The API now support injection via a transform block. For example, lets assume that we are using `NetworkDataProcedure` which requires a `URLRequest`, and we have a procedure which results in a `URL`, we might do this:
        ```swift
        download.injectResult(from: getURL) { url in
            return URLRequest(url: $0) 
        }
        ```
    - Refactors `ResultInjection` protocol to use `PendingValue<T>`. Now the `requirement` and `result` properties are `PendingValue<Requrement>` and `PendingValue<Result>` respectively. This avoids the need to use explicitly unwrapped optionals for the `Requirement`. For example:
        ```swift
        class MyProcedure: Procedure, ResultInjection {
            var requirement: PendingValue<Foo> = .pending
            var result: PendingValue<Bar> = .pending
        }
        ```
    - Extension APIs automatically unwrap optionals. This means that where a `Result? == Requirement` the result will be automatically unwrapped. 

## New Features
1. [#516](https://github.com/ProcedureKit/ProcedureKit/pull/516), [#534](https://github.com/ProcedureKit/ProcedureKit/pull/534): `AnyProcedure` 

    This is a new procedure which supports composition of any `Procedure` subclass conforming to `ResultInjection` APIs with complete type erasure. This makes the following usage possible: 
    - Inject / store generic `Procedure` subclasses into other types.
    - Store many different types of `Procedure` subclasses in a homogenous storage container, so long as they have the same sub-type `Requirement` and `Result`.

    An example of where this is useful would be with a strategy design pattern, where each strategies likely has a different `Procedure` subclass, but the `Requirement` (i.e. input) and `Result` (i.e. output) of each is the same. Given this, any strategy can be injected into a `GroupProcedure` or other structure type-erased using `AnyProcedure<Requirement,Result>`.
2. [#523](https://github.com/ProcedureKit/ProcedureKit/pull/523) _ProcedureKitCloud_

    Added a _ProcedureKitCloud_ framework, which currently just
includes `Capability.CloudKit`. Unfortunately the full `CloudKitProcedure` class did not get finished in time for this beta. However, it is very close to being finished, see PR: [#542](https://github.com/ProcedureKit/ProcedureKit/pull/542).
3. [#524](https://github.com/ProcedureKit/ProcedureKit/pull/524), [#525](https://github.com/ProcedureKit/ProcedureKit/pull/525), [#526](https://github.com/ProcedureKit/ProcedureKit/pull/526), [#538](https://github.com/ProcedureKit/ProcedureKit/pull/538),[#547](https://github.com/ProcedureKit/ProcedureKit/pull/547) _ProcedureKitNetwork_
    
    _ProcedureKitNetwork_ is a framework which offers a very simple wrapper around `URLSession` **completion based** APIs. Currently only for `NetworkDataProcedure` which uses the `URLSessionDataTask` based APIs. If you need to use the delegate based APIs you cannot use this `Procedure` subclass.
    
    Additionally, there is full support in _TestingProcedureKit_ for using `TestableURLSession` which allows framework consumers to check that the session receives the correct request etc.
4. [#536](https://github.com/ProcedureKit/ProcedureKit/pull/536) `.then { }` API

    Added an alternative way of adding dependencies on `Operation` in a chain. For example:
    ```swift
    let operations = foo.then(do: bar).then { Baz() }
    ```
    Thanks to [@jshier](https://github.com/jshier) for initial idea and suggestion - sorry it took so long to get done!
5. [#508](https://github.com/ProcedureKit/ProcedureKit/pull/508), [#553](https://github.com/ProcedureKit/ProcedureKit/pull/553) CocoaPods

    Note here that the standard pod is just the core framework. This is Extension API compatible with support for all 4 platforms. To get iOS related classes, such as `BackgroundObserver` which are not Extension API compatible use `ProcedureKit/Mobile`, likewise for `ProcedureKit/Location`, `ProcedureKit/Network`, `ProcedureKit/Cloud` etc.
    _TestingProcedureKit_, has its own podspec.
6. [#537](https://github.com/ProcedureKit/ProcedureKit/pull/537) `ResilientNetworkProcedure` Beta

    This is a `RetryProcedure` subclass which is designed to add network resiliency around network request based `Procedure` subclasses. This procedure works by providing a value which corresponds to `ResilientNetworkBehavior` protocol, and a closure which returns a new network request procedure. The protocol allows the framework consumer to decide how to interpret status/error codes, and trigger retries.
7. [#550](https://github.com/ProcedureKit/ProcedureKit/pull/550) `ConcurrencyTestCase`

    This is a new `ProcedureKitTestCase` subclass in _TestingProcedureKit_ which has methods to help test concurrency issues in _ProcedureKit_ itself, but also in your applications. Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for adding it.
8. [#552](https://github.com/ProcedureKit/ProcedureKit/pull/552) `wait(forAll: [Procedure])` API 

    This is added to `ProcedureKitTestCase`. Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for adding this.
9. [#554](https://github.com/ProcedureKit/ProcedureKit/pull/554) Adds `did(execute: Procedure)` observer callback.

    Use this with great caution, as it may not always do what you expect depending on the behavior of the `execute` method of the procedure. From the discussion:
    > all that's currently guaranteed is that didExecuteObservers will be called after execute() returns. The rest is up to the specifics of the Procedure subclass implementation.
    This will likely be improved before 4.0.0 is final. 
    
## Bug Fixes etc
1. [#518](https://github.com/ProcedureKit/ProcedureKit/pull/518) Fixes failing release build regression.
2. [#531](https://github.com/ProcedureKit/ProcedureKit/pull/531) Adds default empty implementation to some of the Queue Delegate methods. Feedback welcome here!
3. [#533](https://github.com/ProcedureKit/ProcedureKit/pull/533) Adds an area in the repo for talks and presentations which have been given about _Operations_ or _ProcedureKit_. Watch out for [@jshier](https://github.com/jshier) who will be speaking at [Swift Summit](https://www.swiftsummit.com) _ProcedureKit and you_ on Nov 7th. 😀😀😀
4. [#532](https://github.com/ProcedureKit/ProcedureKit/pull/532) Fixes a bug where `GroupProcedure` would collect errors from its children after it had been cancelled. This is a bit annoying, if  a group is cancelled, it will cancel all of its children with an error (`ProcedureKitError.parentDidCancel(error)`), but it would then receive in its delegate all of those errors from the children.
5. [#539](https://github.com/ProcedureKit/ProcedureKit/pull/539) Tweaks to cancel `BlockProcedure` stress tests.
6. [#540](https://github.com/ProcedureKit/ProcedureKit/pull/540) Moves `import ProcedureKit` into umbrella headers.
7. [#544](https://github.com/ProcedureKit/ProcedureKit/pull/544) Fixes `BlockProcedure` stress tests - thanks to [@swiftlyfalling](https://github.com/swiftlyfalling).
8. [#545](https://github.com/ProcedureKit/ProcedureKit/pull/545) Fixes a bug where `ExclusivityManager` was not thread safe. Thanks to [@myexec](https://github.com/myexec) for reporting the bug, and [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing it.
9. [#549](https://github.com/ProcedureKit/ProcedureKit/pull/549) Fixes random crashed in `QueueTestDelegate` - thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing this, and generally being awesome at identifying where code paths are not thread safe 💚.
10. [#557](https://github.com/ProcedureKit/ProcedureKit/pull/557) Fixes some CI errors in Fastfile.
11. [#558](https://github.com/ProcedureKit/ProcedureKit/pull/558) [#559](https://github.com/ProcedureKit/ProcedureKit/pull/559) Fixes issue with Xcode 8.1 release builds, thanks so much to [@pomozoff](https://github.com/pomozoff) for figuring out the issue here!
12. [#556](https://github.com/ProcedureKit/ProcedureKit/pull/556) Adds group concurrency tests using the new `ConcurrencyTestCase`. Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for their awesome contributions!

# 4.0.0 Beta 3

Beta 3 adds _ProcedureKitMobile_, _ProcedureKitLocation_ and _TestingProcedureKit_ frameworks. The mobile framework is suitable for use in iOS applications, although it does not yet have `AlertProcedure` which will come in a future beta.

To integrate these frameworks, use:
```swift
import ProcedureKit
```
which can be done anywhere, such as internal frameworks and extensions, and on any platform.

```swift
import ProcedureKitMobile
```
which can only be done in an iOS application target, as it’s not extension compatible.

```swift
import ProcedureKitLocation
```
which can be used on any platform.

_TestingProcedureKit_ is a framework is for adding to test bundle targets. It links with XCTest, so cannot be added to an application target. While documentation is sorely lacking here, this is very useful for writing unit tests for `Procedure` subclasses. It has APIs to support waiting for procedures to run, and asserting their end state.

## New Features

1. [#476](https://github.com/ProcedureKit/ProcedureKit/pull/476) Adds `BackgroundObserver`
2. [#496](https://github.com/ProcedureKit/ProcedureKit/pull/496) Adds `FilterProcedure`
3. [#497](https://github.com/ProcedureKit/ProcedureKit/pull/497) Adds `ReduceProcedure`
4. [#498](https://github.com/ProcedureKit/ProcedureKit/pull/498) Adds `NetworkObserver`
5. [#499](https://github.com/ProcedureKit/ProcedureKit/pull/499) Adds `Capability.Location`
6. [#500](https://github.com/ProcedureKit/ProcedureKit/pull/500) Adds `UserLocationProcedure`
7. [#502](https://github.com/ProcedureKit/ProcedureKit/pull/502) Adds `ReverseGeocodeUserLocationProcedure`
8. [#503](https://github.com/ProcedureKit/ProcedureKit/pull/503) Adds `ReverseGeocodeUserLocationProcedure`

## Bug fixes etc

9. [#503](https://github.com/ProcedureKit/ProcedureKit/pull/503) Fixes an issue where the minimum deployment target was incorrect for iOS.
10. [#510](https://github.com/ProcedureKit/ProcedureKit/pull/510) Makes procedures which were `public` and therefore not override-able by a framework consumer `open`. Got to watch out for these.
11. [#511](https://github.com/ProcedureKit/ProcedureKit/pull/511) Refactors `BlockProcedure` to no longer be a subclass of `TransformProcedure`. I did like the simplicity of this, however, I want to be able to automatically throw an error if the requirement of `TransformProcedure` is not set.

# 4.0.0 Beta 2

Beta 2 is all about rounding out the majority of the missing functionality from _ProcedureKit_, and additionally fixing integration issues.

1. [#471](https://github.com/ProcedureKit/ProcedureKit/pull/471) NegatedCondition
2. [#472](https://github.com/ProcedureKit/ProcedureKit/pull/472) SilentCondition 
3. [#474](https://github.com/ProcedureKit/ProcedureKit/pull/471) Fixes for how Procedure finishes - thanks [@swiftlyfalling](https://github.com/swiftlyfalling)
4. [#473](https://github.com/ProcedureKit/ProcedureKit/pull/471) BlockCondition
5. [#470](https://github.com/ProcedureKit/ProcedureKit/pull/471) NoFailedDependenciesCondition
6. [#475](https://github.com/ProcedureKit/ProcedureKit/pull/471) TimeoutObserver
7. [#478](https://github.com/ProcedureKit/ProcedureKit/pull/471) Procedure name and identity
8. [#480](https://github.com/ProcedureKit/ProcedureKit/pull/471) BlockObserver - thanks to [@jshier](https://github.com/jshier) for his input on this.
9. [#487](https://github.com/ProcedureKit/ProcedureKit/pull/471) Adds ComposedProcedure & GatedProcedure
10. [#488](https://github.com/ProcedureKit/ProcedureKit/pull/471) RepeatProcedure
11. [#491](https://github.com/ProcedureKit/ProcedureKit/pull/471) RetryProcedure
12. [#492](https://github.com/ProcedureKit/ProcedureKit/pull/492) Capabilities

In addition to the above additions, fixes have been made to fix Release builds correctly compile, despite some Swift 3 compiler bugs in Xcode 8 and 8.1. See the release notes for more instructions.

# 4.0.0 Beta 1

Well, it’s time to say goodbye to _Operations_ and hello to _ProcedureKit_. _ProcedureKit_ is a complete re-write of _Operations_ in Swift 3.0, and has the following key changes.

1. _ProcedureKit_
    _Operations_ has been lucky to have many contributors, and for _ProcedureKit_ I wanted to be able to recognise the fantastic contributions of this little community properly. So the repository has been transferred into an organization. At the moment, the only additional member is [@swiftlyfalling](https://github.com/swiftlyfalling) however I hope that more will join soon. In addition to moving to an org, there are now contribution guidelines and code of conduct documents.
    
2. Naming changes
    Because Swift 3.0 has dropped the `NS` prefix from many classes, including `NSOperation`, `NSOperationQueue` and `NSBlockOperation`, _Operations_ had some pretty significant issues in Swift 3.0. At WWDC this year, I was able to discuss _Operations_ with Dave DeLong and Philippe Hausler. We brainstormed some alternatives, and came up with “Procedure”, which I’ve sort of grown accustomed to now. The name changes are  widespread, and essentially, what was once `Operation` is now `Procedure`.
    
3. Project structure
    For a long time, we’ve had an issue where some classes are not extension API compatible. This has resulted in having two projects in the repository, which in turn leads to problems with Carthage not being able to build desired frameworks. With ProcedureKit, this problem is entirely resolved. The core framework, which is the focus of this beta, is entirely extension API compatible. It should be imported like this:
    ```swift
    import ProcedureKit
    ```
    
    Functionality which depends on UIKit, such as `AlertProcedure` will be exposed in a framework called `ProcedureKitMobile`, and imported like this:
    ```swift
    import ProcedureKit
    import ProcedureKitMobile
    ```
    
    Similarly for other non-core functionality like CloudKit wrappers etc.
    
    In addition to types which should be used in applications, I wanted to expose types to aid writing unit tests. This is called `TestingProcedureKit`, which itself links against `XCTest`. *It can only be used inside test bundle targets*. This framework includes `ProcedureKitTestCase` and `StressTestCase` which are suitable for subclassing. The former then exposes simple APIs to wait for procedures to run using `XCTestExpectation`. Additionally, there are `XCTAssertProcedure*` style macros which can assert that a `Procedure` ran as expected. To use it in your own application’s unit test target:
    ```swift
    import ProcedureKit
    import TestingProcedureKit
    @testable import MyApplication
    ```    
4. Beta 1 Functionality
    This beta is focused on the minimum. It has `Procedure`, `ProcedureQueue`, `GroupProcedure`, `MapProcedure`, `BlockProcedure` and `DelayProcedure`. In addition, there is support for the following features:
    1. Attaching conditions which may support mutual exclusion
    2. Adding observers - see notes below.
    3. Result injection has been simplified to a single protocol.
    4. Full logging support
    5. Errors are consolidated into a single `ProcedureKitError` type.

5. Observers
    An annoying element of the observers in _Operations_ is that the received `Operation` does not retain full type fidelity. It’s just `Operation`, not `MyOperationSubclass`. With `ProcedureKit` this has been fixed as now the underlying protocol `ProcedureObserver` is generic over the `Procedure` which is possible as there is now a `ProcedureProtocol`. This means, that the block observers are now generic too. Additionally, an extension on `ProcedureProtocol` provides convenience methods for adding block observers. This means that adding block observers should now be done like this:    
    ```swift 
    let foo = FooProcedure()
    foo.addDidFinishBlockObserver { foo, errors in
        // No need to cast argument to FooProcedure
        foo.doFooMethod()
    }
    ```
6. `BlockProcedure`
    The API for `BlockProcedure` has changed somewhat. The block type is now `() throws -> Void`. In some regards this is a reduction in capability over `BlockOperation` from _Operations_ which received a finishing block. The finishing block meant that the block could have an asynchronous callback to it.
    
    While this functionality might return, I think that it is far better to have a simple abstraction around synchronous work which will be enqueued and can throw errors. For asynchronous work, it would be best to make a proper `Procedure` subclass.
    
    Having said that, potentially we will add `AsyncBlockProcedure` to support this use case. Please raise an issue if this is something you care about!
    
Anyway, I think that is about it - thanks to all the contributors who have supported _Operations_ and _ProcedureKit_ while this has been written. Stay tuned for Beta 2 in a week or so.

# 3.4.0

This is a release suitable for submission for iOS 10, but built using Swift 2.3 & Xcode 8.

# 3.3.0
This is a release suitable for submission for iOS 10, but built using Swift 2.2 & Xcode 7.

1. [OPR-452](https://github.com/ProcedureKit/ProcedureKit/pull/452)  Resolves the warning related to CFErrorRef.
2. [OPR-453](https://github.com/ProcedureKit/ProcedureKit/issues/453), [OPR-454](https://github.com/ProcedureKit/ProcedureKit/pull/454) Fixes an issue where the Mac OS X deployment target was incorrect.
3. [OPR-456](https://github.com/ProcedureKit/ProcedureKit/pull/456)  Modifies the podspec to remove Calendar, Passbook, Photos, CloudKit, Location, AddressBook etc from the standard spec. This  is to prevent linking/importing OS frameworks which consumers might not have explanations in their info.plist. This is following reports that  are being more restrictive for iOS 10 submissions.

# 3.2.0
This is a pretty special release! All the important changes have been provided by contributors! 🚀😀💚

Additionally, [@swiftlyfalling](https://github.com/swiftlyfalling) has become a _ProcedureKit_ core contributor 😀 

1. [OPR-416](https://github.com/ProcedureKit/ProcedureKit/issues/416), [OPR-417](https://github.com/ProcedureKit/ProcedureKit/issues/417) Thanks to [@pomozoff](https://github.com/pomozoff) for reporting and fixing a bug which could cause a crash in an edge case where operation with conditions is previously cancelled. Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling).
2. [OPR-420](https://github.com/ProcedureKit/ProcedureKit/pull/420) Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for replacing an assertion failure, and adding some more stress tests in `Condition`’s `execute` method.
3. [OPR-344](https://github.com/ProcedureKit/ProcedureKit/issues/344), [OPR-344](https://github.com/ProcedureKit/ProcedureKit/pull/421) Thanks to [@ryanjm](https://github.com/ryanjm) for reporting (_a while ago_, sorry!) a bug in `NetworkObserver`, and thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing the bug!
4. [OPR-422](https://github.com/ProcedureKit/ProcedureKit/pull/422)  Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for adding some robustness to `NetworkObserver` and its tests.
5. [OPR-419](https://github.com/ProcedureKit/ProcedureKit/pull/419) Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing a bug which improves the performance of a whole number of tests. Mostly the changes here are to ensure that `XCTestExpectation`s get their `fulfill()` methods called on the main queue.
6. [OPR-423](https://github.com/ProcedureKit/ProcedureKit/pull/423) Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing a bug where `cancelWithError()` could result in an assertion due to an illegal state transition. They even added some stress tests around this 💚
7. [OPR-425](https://github.com/ProcedureKit/ProcedureKit/pull/425)  Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for refactoring some unit tests to use a dispatch group instead of multiple `XCTestExpectation` instances.
8. [OPR-427](https://github.com/ProcedureKit/ProcedureKit/pull/427) I made some changes to the CI pipeline for Swift 2.2 branch so that [@swiftlyfalling](https://github.com/swiftlyfalling) didn’t have to wait too long to merge their pull requests.
9. [OPR-434](https://github.com/ProcedureKit/ProcedureKit/pull/434) Thanks to [@pomozoff](https://github.com/pomozoff) for raising a configuration issue where a file was added to the Xcode project twice, causing a warning when running Carthage.
10. [OPR-435](https://github.com/ProcedureKit/ProcedureKit/pull/435) Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for making some improvements to avoid a Swift 2.2 bug which causes a memory leak when using string interpolation.

# 3.1.1

1. [OPR-410](https://github.com/danthorpe/Operations/pull/410) Thanks to [@paulpires](https://github.com/paulpires) for fixing a bug in the `ReachabilityManager`.
2. [OPR-412](https://github.com/danthorpe/Operations/pull/412) Makes the `condition` property of `Operation` publicly accessible.

# 3.1.0

## Improvements to Result Injection

I’ve made some changes to make working with _result injection_ easier.

1. [OPR-362](https://github.com/danthorpe/Operations/pull/362), [OPR-363](https://github.com/danthorpe/Operations/pull/363), [OPR-378](https://github.com/danthorpe/Operations/pull/378)
    These changes simplify the core implementation of how result injection works, no longer using any closure capture. Additionally, if the `Requirement` is equal to `Result?`, the framework provides a new API, for _requiring_ that the result is available. For example:
    
    ```swift
    class Foo: Operation, ResultOperationType {
        var result: String?
        // etc
    }
    
    class Bar: Operation, AutomaticInjectionOperationType {
        var requirement: String = “default value”
        // etc
    }
    
    let foo = Foo()
    let bar = Bar()
    bar.requireResultFromDependency(foo)
    ```
    
    Now, if `foo` finishes with a nil `result` value, `bar` will be automatically cancelled with an `AutomaticInjectionError.RequirementNotSatisfied` error. And it’s no longer necessary to `guard let` unwrap the requirement in the `execute()` method.
    
    This works well in situations where the `requirement` property is not an optional, but can be set with a default value.
   
## Improvements to Conditions

I’ve made some changes to improve working with `Condition`s. The focus here has been to support more subtle/complex dependency graphs, and suppressing errors resulting from failed conditions. 

2. [OPR-379](https://github.com/danthorpe/Operations/pull/379), [OPR-386](https://github.com/danthorpe/Operations/pull/386) Fixes some unexpected behaviour where indirect dependencies (i.e. dependencies of a condition) which are also direct dependencies got added to the queue more than once. This was fixed more generally to avoid adding operations which are already enqueued.
3. [OPR-385](https://github.com/danthorpe/Operations/pull/385), [OPR-390](https://github.com/danthorpe/Operations/pull/390), [OPR-397](https://github.com/danthorpe/Operations/pull/397) Adds support for ignoring condition failures

    In some situations, it can be beneficial for an operation to not collect an error if an attached condition fails. To support this, `ConditionResult` now has an `.Ignored` case, which can be used to just cancel the attached `Operation` but without an error.
    
    To make this easier, a new condition, `IgnoredCondition` is provided which composes another condition. It will ignore any failures of the composed condition.
    
    In addition, `NoFailedDependenciesCondition` now supports an initialiser where it will ignore any dependencies which are also ignored, rather than failing for cancelations. This can be used like this:
    
    ```swift
    dependency.addCondition(IgnoredCondition(myCondition))
    operation.addDependency(dependency)
    operation.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))
    ``` 
    
    Note that the `ignoreCancellations` argument defaults to false to maintain previous behaviour. Thanks to [@aurelcobb](https://github.com/aurelcobb) for raising this issue.

## API Changes

2. [OPR-361](https://github.com/danthorpe/Operations/pull/361) `GroupOperation`’s queue is now private.

    Given the way that `GroupOperation` works, critically that it acts as its queue’s delegate, this change restricts the ability for that contract to be broken. Specifically, the queue is now private, but its properties are exposed via properties of the group.

    Additionally, the default initialiser of `GroupOperation` now takes an optional `dispatch_queue_t` argument. This dispatch queue is set as the `NSOperationQueue`’s `underlyingQueue` property, and effectively allows the class user to set a target dispatch queue. By default this is `nil`.

    This change will require changes to subclasses which override the default initialiser.

    Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for these changes.
	
   
## Bug Fixes

3. [OPR-377](https://github.com/danthorpe/Operations/pull/377) GatedOperation will now cancel its composed operation if the gate is closed.
4. [OPR-365](https://github.com/danthorpe/Operations/pull/365) Fixes a log message error. Thanks to [@DeFrenZ](https://github.com/DeFrenZ) for this one.
5. [OPR-382](https://github.com/danthorpe/Operations/pull/382) Fixes an issue where `TaskOperation` was included in non-macOS platforms via CocoaPods.


# 3.0.0

🚀🙌 After a significant period of testing, Version 3.0.0 is finally here! Checkout the details below:

## Conditions
The protocol `OperationCondition` is not deprecated. Instead, conditions should be refactored as subclasses of `Condition` or `ComposedCondition`. Condition itself is an `Operation` subclass, and there is now support in `Operation` for adding conditions like this. Internally `Operation` manages a group operation which is added as a dependency. This group evaluates all of the conditions.

1. [[OPR-286](https://github.com/danthorpe/Operations/pull/286)]: Conditions are now subclasses of `Condition` and `Operation` subclass.
2. [[OPR-309](https://github.com/danthorpe/Operations/pull/309)]: Fixes a bug with `ComposedCondition`.

## Operation & OperationQueue

3. [[OPR-293](https://github.com/danthorpe/Operations/pull/293)]: Adds `WillCancelObserver` - use will/did cancel observer to handle cancellation.
4. [[OPR-319](https://github.com/danthorpe/Operations/pull/319)]: Improvements to invoking observers in `Operation`.
5. [[OPR-353](https://github.com/danthorpe/Operations/pull/353)]: Fixes a bug with Swift 2.* where weak properties are not thread safe when reading. [@swiftlyfalling](https://github.com/swiftlyfalling) for fixing this one!
6. [[OPR-330](https://github.com/danthorpe/Operations/pull/330)]: Ensures that `NSOperationQueue.mainQueue()` returns an `OperationQueue` instance. Thanks to [@gtchance](https://github.com/gtchance) for this - great spot!
7. [[OPR-359](https://github.com/danthorpe/Operations/pull/359)]: `Operation.cancel()` is now final, which means that it cannot be overridden. To support effective cancelling in `Operation` subclasses, attach `WillCancelObserver` and `DidCancelObserver` observers to the operation before it is added to a queue. Thanks to [@swiftlyfalling](https://github.com/swiftlyfalling) for adding this.
8. [[OPR-358](https://github.com/danthorpe/Operations/pull/358)]: [@swiftlyfalling](https://github.com/swiftlyfalling) has done a fantastic job fixing an assortment of thread safety issues in `Operation` and `GroupOperation`. Now cancellation, finishing, logs, and adding operations to groups is a lot safer.

## Features
9. [[OPR-305](https://github.com/danthorpe/Operations/pull/305), [OPR-306](https://github.com/danthorpe/Operations/pull/306)]: Fixes a bug where `CLLocationManager` would respond with a status of not determined prematurely in some cases. Thanks to [@J-Swift](https://github.com/J-Swift) for the fix!
10. [[OPR-321](https://github.com/danthorpe/Operations/pull/321)]: Adds support for checking if the current queue is the main queue, without using `NSThread.isMainThread()` API. This technique is used to ensure that `CLLocationManager` is always created on the main queue, regardless of the calling queue. This allows for location operations to be run inside `GroupOperation`s for example. Thanks again to [@J-Swift](https://github.com/J-Swift) for reporting this one!
11. [[OPR-304](https://github.com/danthorpe/Operations/pull/304)]: Vastly improved support for CloudKit errors. Each `CKOperation` defines its own CloudKit error type which provides direct support for managing its subtypes. For example, `CKMarkNotificationsReadOperation` uses an `ErrorType` of `MarkNotificationsReadError<NotificationID>` which stores the marked notification IDs. These error types allow framework consumers to provide effective error handling for `CKPartialError` for example.
12. [[OPR-327](https://github.com/danthorpe/Operations/pull/327)]: Removes reachability from `CLoudKitOperation`, now, network reachability will be handled as recommended by Apple, which is to retry using the error information provided. This is in contrast to waiting for the network to be reachable.
13. [[OPR-312](https://github.com/danthorpe/Operations/pull/312)]: Supports the `enterReaderIfAvailable` configuration of `SFSafariViewController` with `WebpageOperation`. This defaults to false. Thanks to [@blg-andreasbraun](https://github.com/blg-andreasbraun) for adding this!
14. [[OPR-315](https://github.com/danthorpe/Operations/pull/315)]: Refactors `WebpageOperation` to subclass `ComposedOperation`. Thanks to [@blg-andreasbraun](https://github.com/blg-andreasbraun) for tidying this up!
15. [[OPR-317](https://github.com/danthorpe/Operations/pull/317)]: Adds an `OpenInSafariOperation`. Thanks to [@blg-andreasbraun](https://github.com/blg-andreasbraun) for adding this!
16. [[OPR-334](https://github.com/danthorpe/Operations/pull/334), [OPR-351](https://github.com/danthorpe/Operations/pull/351)]: Updates `AlertController` to support action sheets with `UIAletController`. Thanks, again, to [@blg-andreasbraun](https://github.com/blg-andreasbraun), for fixing this!
17. [[OPR-329](https://github.com/danthorpe/Operations/pull/326)]: Added support for `GroupOperation` subclasses to recover from errors. Thanks to [@gsimmons](https://github.com/gsimmons) for reporting this issue!
18. [[OPR-348](https://github.com/danthorpe/Operations/pull/348)]: Added the ability for `RepeatedOperation` to reset its configuration block.
19. [[OPR-294](https://github.com/danthorpe/Operations/pull/294)]: Adds very simplistic support to `CloudKitOperation` to handle `CKLimitExceeded`. Framework consumers should bear in mind however, that this is quite simplistic, and if your object graph uses many (or any) `CKReferences` be careful here. It is generally advised to update `CKReferences` first.

## Miscellaneous issues & bug fixes
20. [[OPR-302](https://github.com/danthorpe/Operations/pull/302)]: Fixes a incorrect Fix-It hint
21. [[OPR-303](https://github.com/danthorpe/Operations/pull/303)]: Fixes `.Notice` severity logs.
22. [[OPR-310](https://github.com/danthorpe/Operations/pull/310)]: Removes an unnecessary `let` statement. Thanks to [@pomozoff](https://github.com/pomozoff) for this one!
23. [[OPR-324](https://github.com/danthorpe/Operations/pull/324)]: Exposes the `LogSeverity` value to Objective-C. Thanks to [@J-Swift](https://github.com/J-Swift) for this one!
24. [[OPR-341](https://github.com/danthorpe/Operations/pull/341)]: Makes `UserIntent` accessible from Objective-C. Thanks [@ryanjm](https://github.com/ryanjm) for this one!
25. [[OPR-338](https://github.com/danthorpe/Operations/pull/338)]: Thanks to [@ryanjm](https://github.com/ryanjm) for fixing an issue which caused the `NetworkObserver` to flicker.
26. [[OPR-350](https://github.com/danthorpe/Operations/pull/350)]: Turns on Whole Module Optimization for Release configuration builds. Whoops! Sorry!

This is a pretty big release. Thanks so much to all the contributors. I promise that 3.1 will not be too far behind.

# 2.10.1

1. [[OPR-305](https://github.com/danthorpe/Operations/pull/305)]: Resolves an issue where `Capability.Location` can finish early. This can happen on subsequent permission challenges if the app is closed while the permission alert is on screen. It appears to be some slightly unexpected behavior of `CLLocationManager` informing its delegate immediately that the status is `.NotDetermined`. Lots of thanks to [J-Swift](https://github.com/J-Swift) for finding, explaining to me, and providing a fix for this issue!  

# 2.10.0

1. [[OPR-256](https://github.com/danthorpe/Operations/pull/256)]: When a `GroupOperation` is cancelled with errors, the child operations in the group are also cancelled with those errors wrapped inside an `OperationError.ParentOperationCancelledWithErrors` error. Thanks to [@felix-dumit](https://github.com/felix-dumit) and [@jshier](https://github.com/jshier) for contributing.
2. [[OPR-257, OPR-259](https://github.com/danthorpe/Operations/pull/259)]: Improves the README to give much clearer documentation regarding the need for an `OperationQueue` instance, instead of just a regular `NSOperationQueue`. Thanks to [@DavidNix](https://github.com/DavidNix) for raising the initial issue.
3. [[OPR-265](https://github.com/danthorpe/Operations/pull/265)]: Defines `Operation.UserIntent`. This is a simple type which can be used express the intent of the operation. It allows for explicit user action (`.Initiated`), a side effect of user actions (`.SideEffect`), and `.None` for anything else, which is the default. `Operation` will use this value to set the quality of service (QoS) of the operation. The reason for separating `UserIntent` from the QoS, is that it is not possible to accurately determine the intent from the QoS because an `NSOperation`'s QoS can be modified when it is added to a queue which has a different QoS, or even if it is already on a queue, which has another `NSOperation` with a different QoS added to the same queue. See [the documentation on Quality of Service classes](https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html).
4. [[OPR-266](https://github.com/danthorpe/Operations/pull/266/commits/dc19369828d5bf555ab9eee4603e73c2b6eedb6b)]: Thanks for [@estromlund](https://github.com/estromlund) for fixing this bug - now network errors are passed into the errors of the network operation.
5. [[OPR-273](https://github.com/danthorpe/Operations/pull/273)]: `AlertOperation` can now be customized to display action sheet style alerts. Thanks to [@felix-dumit](https://github.com/felix-dumit) for writing this one!
6. [[OPR-281](https://github.com/danthorpe/Operations/pull/281)]: `BlockOperation` now supports blocks which throw errors. The errors are caught and processed by `Operation` correctly. Thanks to [@ryanjm](https://github.com/ryanjm) for reporting and contributing!
7. [[OPR-292](https://github.com/danthorpe/Operations/pull/282)]: Fixes a bug accessing `PHPhotoLibrary`. Thanks to [@ffittschen](https://github.com/ffittschen) for reporting this bug!
8. [[OPR-285](https://github.com/danthorpe/Operations/pull/285)]: Fixes the watchOS target which had CloudKit references in it. Thanks to [@vibrazy](https://github.com/vibrazy) and the ASOS team for this one!
9. [[OPR-290](https://github.com/danthorpe/Operations/pull/289)]: Fixes a typo - thanks [@waywalker](https://github.com/waywalker)!
10. [[OPR-296](https://github.com/danthorpe/Operations/pull/296)]: Updates the `.gitignore` for Swift Package Manager. Thanks to [@abizern](https://github.com/abizern) for contributing.
11. [[OPR-269](https://github.com/danthorpe/Operations/pull/269)]: Fixes a bug with `NSURLSessionTaskOperation` where it could crash if it is not safely finished. Please report any bugs with this class, as at the moment it is not very well tested.

This is an interim release before some significant breaking changes get merged, for version 3.0.

Thanks a lot for everyone who has contributed!

# 2.9.1

1. [[OPR-282](https://github.com/danthorpe/Operations/pull/282)]: Fixes a bug accessing `PHPhotoLibrary` through `Capability.Photos`.
2. [[OPR-285](https://github.com/danthorpe/Operations/pull/285)]: Removes CloudKit files from the watchOS target.

This is a patch release to get these fixes released.

# 2.9.0

1. [[OPR-241](https://github.com/danthorpe/Operations/pull/241)]: Makes change for Xcode 7.3 and Swift 2.2.
2. [[OPR-251](https://github.com/danthorpe/Operations/pull/252)]: Refactors how Capabilities work with their generic registrars.

Got there in the end! Thanks everyone for helping out during the change to Swift 2.2 - by the time Swift 3.0 comes around, I’ll hopefully have a fully automated CI system in place for switching up toolchains/build.

# 2.8.2

1. [[OPR-250](https://github.com/danthorpe/Operations/pull/250)]: Thanks to [@felix-dumit](https://github.com/felix-dumit) for making the cancellation of `GroupOperation` more sensible and consistent. Essentially now the group will cancel after all of its children have cancelled.

This should be the last bug release before v2.9.0 and Swift 2.2 is released.

Also, before v2.10 is released, if you happen to use Operations framework in your app or team, and would agree to having a logo displayed in the README - please [get in touch](https://github.com/danthorpe/Operations/issues/new)!

# 2.8.1

1. [[OPR-245](https://github.com/danthorpe/Operations/pull/247)]: Thanks to [@difujia](https://github.com/difujia) for spotting and fixing a really clear retain cycle in `ComposedOperation`. Good tip - is to remember that an operation will retain its observers, meaning that if an operation owns another operation, *and* acts as its observer, then it will create a retain cycle. The easy fix is to use block based observers, with a capture list of `[unowned self]`.
2. [[OPR-246](https://github.com/danthorpe/Operations/pull/248)]: Another bug fix from [@difujia](https://github.com/difujia) for a race condition when adding operation which have mutual exclusive dependencies. My bad! Thanks Frank!

Just a quick note - these bug fixes are both being released now as 2.8.1 for Swift 2.1 & Xcode 7.2. The same fixes will be pulled into the `development` branch which is shortly going to become Swift 2.2, although it isn't yet. Bear with me - as that should happen over the weekend. 

# 2.8.0
🚀 This will be the last minor release for Swift 2.1.1. From here on development of new features will be in Swift 2.2 😀.

Yet again, this release features more contributors - thanks a lot to [@estromlund](https://github.com/estromlund), [@itsthejb](https://github.com/itsthejb), [@MrAlek](https://github.com/MrAlek) and [@felix-dumit](https://github.com/felix-dumit) for finding bugs and fixing them!

Also, I’m pretty happy to report that adoption and usage of this framework has been seeing somewhat of an uptick! According to the stats on CocoaPods, we’re seeing almost 2,500 downloads/week and over used by over 120 applications 🎉! The support from the Swift community on this has been pretty amazing so far - thanks everyone 😀🙌!

1. [[OPR-233](https://github.com/danthorpe/Operations/pull/223)]: Thanks to [@estromlund](https://github.com/estromlund) & [@itsthejb](https://github.com/itsthejb) for fixing a bug which would have caused retain cycles when using result injection.
2. [[OPR-225](https://github.com/danthorpe/Operations/pull/225)]: Adds a unit test to check that `Operation` calls `finished()`. This was a bit of a followup to the fixes in 2.7.1.
3. [[OPR-208,OPR-209](https://github.com/danthorpe/Operations/pull/209)]: Thanks to [@itsthejb](https://github.com/itsthejb) who remove the `HostReachabilityType` from the arguments of `ReachabilityCondition` which allows it to be more easily consumed. It’s now access via a property in unit tests.
4. [[OPR-210](https://github.com/danthorpe/Operations/pull/210)]: Thanks to [@itsthejb](https://github.com/itsthejb) (again!) for improving the logic for ReachabilityCondition.
5. [[OPR-226](https://github.com/danthorpe/Operations/pull/226)]: Some improvements to the unit tests to fix some failures on development.
6. [[OPR-224](https://github.com/danthorpe/Operations/pull/224)]: Use `.Warning` log severity when logging errors in `Operation`. Thanks again to [@itsthejb](https://github.com/itsthejb) for this one.
7. [[OPR-227](https://github.com/danthorpe/Operations/pull/227)]: Sets the log severity to `.Fatal` for the unit tests.
8. [[OPR-229](https://github.com/danthorpe/Operations/pull/229)]: Thanks to [@estromlund](https://github.com/estromlund) for fixing a bug from 2.7.0 where the automatic result injection was done using a `DidFinishObserver` instead of `WillFinishObserver` which was causing some race conditions.
9. [[OPR-231](https://github.com/danthorpe/Operations/pull/231)]: Removes `self` from the default operation name - which due to the `@autoclosure` nature of the log message could cause locking issues.
10. [[OPR-234](https://github.com/danthorpe/Operations/pull/234)]: Thanks to [@MrAlek](https://github.com/MrAlek) for fixing a bug (causing a race condition) when cancelling a `GroupOperation`.
11. [[OPR-236](https://github.com/danthorpe/Operations/pull/236)]: Thanks to [@felix-dumit](https://github.com/felix-dumit) for fixing a bug where an `AlertOperation` would finish before its handler is called.
12. [[OPR-239](https://github.com/danthorpe/Operations/pull/239)]: Adds `GroupOperationWillAddChildObserver` observer protocol. This is only used by `GroupOperation` and can be use to observer when child operations are about to be added to the group’s queue.
13. [[OPR-235](https://github.com/danthorpe/Operations/pull/235)]: New Observer: `OperationProfiler`.

    An `OperationProfiler` can be added as an observer to an `Operation` instance. It will report a profile result which contains the timings for the lifecycle events of the operation, from created through attached, started to cancelled or finished.
    
    By default, a logging reporter is added, which will print the profile information to the `LogManager`’s logger. This is done like this:
    
    ```swift
    let operation = MyBigNumberCrunchingOperation()
    operation.addObserver(OperationProfiler())
    queue.addOperation(operation)
    ```
    
    However, for customized reporting and analysis of profile results, create the profiler with an array of reporters, which are types conforming to the `OperationProfilerReporter` protocol.
    
    **In most cases doing any kind of profiling of applications in production is unnecessary and should be avoided.**
    
    However, in some circumstances, especially with applications which have very high active global users, it is necessary to gain a holistic view of an applications performance. Typically these measurements should be tied to networking operations and profiling in back end systems. The `OperationProfiler` has deliberately designed with a view of using custom reporters. The built in logging reporter should only really be used as debugging tool during development.
    
    In addition to profiling regular “basic” `Operation` instances. The profiler will also measure spawned operations, and keep track of them from the parent operation’s profiler. Operations can be spawned by calling `produceOperation()` or by using a `GroupOperation`. Regardless, the profiler’s results will reference both as “children” in the same way.
    
    WARNING: Use this feature carefully. *If you have not* written a custom reporter class, **there is no need** to add profilers to operations in production.

# 2.7.1

1. [[OPR-219](https://github.com/danthorpe/Operations/issues/220)]: Fixes an issue after refactoring Operation which would prevent subclasses from overriding `finished(errors: [ErrorType])`.

# 2.7.0
🚀 This release continues the refinement of the framework. Thanks again to everyone who has contributed!

1. [[OPR-152](https://github.com/danthorpe/Operations/issues/152), [OPR-193](https://github.com/danthorpe/Operations/pull/193), [OPR-195](https://github.com/danthorpe/Operations/pull/195), [OPR-201](https://github.com/danthorpe/Operations/pull/201)]: This is a breaking change which significantly improves Operation observers.
    1. Observers can be safely added to an Operation at any point in its lifecycle.
    2. Observers can implement a callback which is executed when there are attached to the operation.
    3. All the block based observers have labels on their arguments.

    Thanks to [@jshier](https://github.com/jshier) for reporting this one.
2. [[OPR-193](https://github.com/danthorpe/Operations/pull/196)]: Thanks to [@seancatkinson](https://github.com/seancatkinson) who made improvements to `UIOperation` making it possible to specify whether the controller should be wrapped in a `UINavigationController`.
3. [[OPR-199](https://github.com/danthorpe/Operations/pull/203)]: Refactored the initializers of `RepeatedOperation` to make it far easier for framework consumers to subclass it - thanks [@jshier](https://github.com/jshier) for reporting this one.
4. [[OPR-197](https://github.com/danthorpe/Operations/pull/198)]: Fixes a bug where errors from nested `GroupOperation`s were not propagating correctly - thanks to [@bastianschilbe](https://github.com/bastianschilbe) for reporting this one.
5. [[OPR-204](https://github.com/danthorpe/Operations/pull/204)]: Fixes a typo in the README - thanks to [@Augustyniak](https://github.com/Augustyniak).
6. [[OPR-214](https://github.com/danthorpe/Operations/pull/214)]: Moves code coverage reporting from Codecov.io to [Coveralls](https://coveralls.io/github/danthorpe/Operations).
7. [[OPR-164](https://github.com/danthorpe/Operations/pull/164)]: Adds initial support for Swift Package Manager - no idea if this actually works yet though.
8. [[OPR-212](https://github.com/danthorpe/Operations/pull/212)]: Removes the example projects from the repo. They are now in the [@danthorpe/Examples](https://github.com/danthorpe/Examples) repo. This was done as a safer/better fix for the issue which was resolved in v2.6.1. Essentially because Carthage now builds *all* Xcode projects that it can finds, it will attempt to build any example projects in the repo, and because Carthage does not have the concept of “local dependencies” these example projects are setup using CocoaPods. And I really don’t like to include the `Pods` folder of dependencies in repositories as it just take longer to checkout. So, this was causing Carthage to exit because it couldn’t build these exampled. So, I’ve moved them to a new repo.
9. [[OPR-216](https://github.com/danthorpe/Operations/pull/216)]: Adds SwiftLint to the project & CI, including fixes for all the issues which were warnings or errors.
10. [[OPR-192](https://github.com/danthorpe/Operations/pull/192)]: Updates the `.podspec` to have more granular dependencies. For users of `CloudKitOperation` this is a breaking change, and you will need to update your `Podfile`:

    ```ruby
    pod ‘Operations/+CloudKit’
    ```

    Thanks to [@itsthejb](https://github.com/itsthejb) for this one.


# 2.6.1

1. [[OPR-205, OPR-206](https://github.com/danthorpe/Operations/pull/206)]: Fixes a mistake where the Cloud Capability was not available on tvOS platform.

2. Temporary work around for an issue with Carthage versions 0.12 and later. In this version, Carthage now builds all Xcode projects it can find, which in this case is 4 projects because there are two examples. Those example projects use CocoaPods to setup their dependency on the Operations framework, using the "development pod" technique. I would prefer to not include their `Pods/` folder in the repo, however, without it, it becomes necessary to run `pod update` before building - which Carthage (reasonably) does not do. Therefore they fail to build and Carthage exits.

# 2.6.0

🚀 This release contains quite a few changes, with over 230 commits with input from 11 contributors! Thanks! 😀🎉

A note on quality: test coverage has increased from 64% in v2.5 to 76%. The code which remains untested is either untestable (`fatalError` etc) or is due for deletion or deprecation such as `AddressBookCondition` etc.

### New Operations

1. [[OPR-150](https://github.com/danthorpe/Operations/pull/150)]: `MapOperation`, `FilterOperation` and `ReduceOperation` *For advanced usage*. 

	These operations should be used in conjunction with `ResultOperationType` which was introduced in v2.5.0. Essentially, given an receiving operation, conforming to `ResultOperationType`, the result of mapping, filtering, or reducing the receiver’s `result` can be returned as the `result` of another operation, which also conforms to `ResultOperationType`. This means that it can be trivial to map the results of one operation inside another.

	It is suggested that this is considered for advanced users only as it’s pretty subtle behavior.

2. [[OPR-154](https://github.com/danthorpe/Operations/pull/154), [OPR-168](https://github.com/danthorpe/Operations/pull/168)]: `RepeatedOperation`

	The `RepeatedOperation` is a `GroupOperation` subclass which can be used in conjunction with a generator to schedule `NSOperation` instances. It is useful to remember that `NSOperation` is a “one time only” class, meaning that once an instance finishes, it cannot be re-executed. Therefore, it is necessary to construct repeatable operations using a closure or generator.
 
	This is useful directly for periodically running idempotent operations. It also forms the basis for operation types which can be retried.
 
	The operations may optionally be scheduled after a delay has passed, or a date in the future has been reached.
 
	At the lowest level, which offers the most flexibility, `RepeatedOperation` is initialized with a generator. The generator (something conforming to `GeneratorType`) element type is `(Delay?, T)`, where `T` is a `NSOperation` subclass, and `Delay` is an enum used in conjunction with `DelayOperation`.
 
	`RepeatedOperation` can also be initialized with a simple `() -> T?` closure and `WaitStrategy`. The strategy offers standardized delays such as `.Random` and `.ExpoentialBackoff`, and will automatically create the appropriate `Delay`. 

	`RepeatedOperation` can be stopped by returning `nil` in the generator, or after a maximum count of operations, or by calling `cancel()`.

	Additionally, a `RepeatableOperation` has been included, which composes an `Operation` type, and adds convenience methods to support whether or not another instance should be scheduled based on the previous instance.

2. [[OPR-154](https://github.com/danthorpe/Operations/pull/154), [OPR-161](https://github.com/danthorpe/Operations/pull/161), [OPR-168](https://github.com/danthorpe/Operations/pull/168)]: `RetryOperation`

	`RetryOperation` is a subclass of `RepeatedOperation`, except that instead of repeating irrespective of the finishing state of the previous instance, `RetryOperation` only repeats if the previous instance finished with errors.

	Additionally, `RetryOperation` is initialized with an “error recovery” block. This block receives various info including the errors from the previous instance, the aggregate errors so far, a `LoggerType` value, plus the *suggested* `(Delay, T?)` tuple. This tuple is the what the `RetryOperation` would execute again without any intervention. The error block allows the consumer to adjust this, either by returning `.None` to not retry at all, or by modifying the return value.

3. [[OPR-160](https://github.com/danthorpe/Operations/pull/160), [OPR-165](https://github.com/danthorpe/Operations/pull/165), [OPR-167](https://github.com/danthorpe/Operations/pull/167)]: `CloudKitOperation` 2.0

	Technically, this work is a refactor of `CloudKitOperation`, however, because it’s a major overhaul it is best viewed as completely new.

	`CloudKitOperation` is a subclass of `RetryOperation`, which composes the `CKOperation` subclass inside a `ReachableOperation`.
	
	`CloudKitOperation` can be used to schedule `CKOperation` subclasses. It supports configuration of the underlying `CKOperation` instance “through” the outer `CloudKitOperation`, where the configuration applied is stored and re-applied on new instances in the event of retrying. For example, below
	
	```swift
    // Modify CloudKit Records
    let operation = CloudKitOperation { CKModifyRecordsOperation() }
    
    // The user must be logged into iCloud 
    operation.addCondition(AuthorizedFor(Capability.Cloud()))
    
    // Configure the container & database
    operation.container = container
    operation.database = container.privateCloudDatabase
    
    // Set the records to save
    operation.recordsToSave = [ recordOne, recordTwo ]
    
    // Set the policy
    operation.savePolicy = .ChangedKeys
    
    // Set the completion
    operation.setModifyRecordsCompletionBlock { saved, deleted in
        // Only need to manage the happy path here
    }
	```
	
	In the above example, all the properties set on `operation` are saved into an internal configuration block. This is so that it in the case of retrying after an error, the same configuration is applied to the new `CKOperation` instance returned from the generator. The same could also be achieved by setting these properties inside the initial block, however the completion block above must be called to setup the `CloudKitOperation` correctly. 
	
	Thanks to `RetryOperation`, `CloudKitOperation` supports some standardized error handling for common errors. For example, if Apple’s CloudKit service is unavailable, your operation will be automatically re-tried with the correct delay. Error handling can be set for individual `CKErrorCode` values, which can replace the default handlers if desired. 
	
	`CKOperation` subclasses also all have completion blocks which receives the result and an optional error. As discussed briefly above, `CloudKitOperation` provides this completion block automatically when the consumer sets the “happy path” completion block. The format of this function is always `set<Name of the CKOperation completion block>()` This means, that it is only necessary to set a block which is executed in the case of no error being received.
	
	`BatchedCloudKitOperation` is a `RepeatedOperation` subclass which composed `CloutKitOperation` instances. It can only be used with `CKOperation` subclasses which have the notion of batched results.
	
	See the class header, example projects, blog posts and (updated) guide for more documentation. This is significant change to the existing class, and should really be viewed as entirely new. Please get in touch if you were previously using `CloudKitOperation` prior to this version, and are now unsure how to proceed. I’m still working on improving the documentation & examples for this class. 

### Examples & Documentation

1. [[OPR-169](https://github.com/danthorpe/Operations/pull/172)]: Last Opened example project

	Last Opened, is the start of an iOS application which will demonstrate how to use the new `CloudKitOperation`. At the moment, it is not exactly complete, but it does show some example. However, the application does not compile until the correct development team & bundle id is set. 

2. [[OPR-171](https://github.com/danthorpe/Operations/pull/171)]: `CloudKitOperation` documentation

	There is now quite a bit of public interface documentation. Still working on updating the programming guide right now.

### Operation Changes

1. [[OPR-152](https://github.com/danthorpe/Operations/pull/156)]: Adding Conditions & Observers

	When adding conditions and observers, we sanity check the state of the operation as appropriate. For adding a Condition, the operation must not have started executing. For adding an Observer, it now depends on the kind, for example, it is possible to add a `OperationDidFinishObserver` right up until the operation enters its `.Finishing` state.

2. [[OPR-147](https://github.com/danthorpe/Operations/pull/157)]: Scheduling of Operations from Conditions

	When an Operation has dependencies and also has Conditions attached which also have dependencies, the scheduling of these dependencies is now well defined. Dependencies from Conditions are referred to as *indirect dependencies* versus *direct* for dependencies added normally.

	The *indirect dependencies* are now scheduled __after__ *all* the direct dependencies finish. See [original issue](https://github.com/danthorpe/Operations/pull/147) and the [pull request](https://github.com/danthorpe/Operations/pull/157) for further explanation including a diagram of the queue.

3. [[OPR-129](https://github.com/danthorpe/Operations/pull/159)]: Dependencies of mutually exclusive Conditions.

	If a Condition is mutually exclusive, the `OperationQueue` essentially adds a lock on the associated `Operation`. However, this previously would lead to unexpected scheduling of that condition had a dependency operation. Now, the “lock” is placed on the dependency of the condition instead of the associated operation, but only if it’s not nil. Otherwise, standard behavior is maintained.

4. [[OPR-162](https://github.com/danthorpe/Operations/pull/162)]: Refactor of `ComposedOperation` and `GatedOperation`

	Previously, the hierarchy of these two classes was all mixed up. `ComposedOperation` has been re-written to support both `Operation` subclasses and `NSOperation` subclasses. When a `NSOperation` (but not `Operation`) subclass is composed, it is scheduled inside its own `GroupOperation`. However, if composing an `Operation` subclass, instead we “produce” it and use observers to finish the `ComposedOperation` correctly.

	Now, `GatedOperation` is a subclass of `ComposedOperation` with the appropriate logic.

5. [[OPR-163](https://github.com/danthorpe/Operations/pull/163), [OPR-171](https://github.com/danthorpe/Operations/pull/171), [OPR-179](https://github.com/danthorpe/Operations/pull/179)]: Refactor of `ReachableOperation`

	`ReachableOperation` now subclasses `ComposedOperation`, and uses `SCNetworkReachablity` callbacks correctly. 

6. [[OPR-187](https://github.com/danthorpe/Operations/pull/187)]: Sanity check `produceOperation()`. Thanks to [@bastianschilbe](https://github.com/bastianschilbe) for this fix. Now the `Operation` must at least have passed the `.Initialized` state before `produceOperation()` can be called.

### Project Configurations

1. [[OPR-182](https://github.com/danthorpe/Operations/pull/184)]: Extension Compatible

	Updates the extension compatible Xcode project. Sorry this got out of sync for anyone who was trying to get it to work!

### Bug Fixes!

1. [[OPR-186](https://github.com/danthorpe/Operations/pull/186), [OPR-188](https://github.com/danthorpe/Operations/pull/188)]: Ensures `UIOperation` finishes correctly.

2. [[OPR-180](https://github.com/danthorpe/Operations/pull/180)]: Completion Blocks.

	Changes in this pull request improved the stability of working with `OperationCondition`s attached to `Operation` instances. However, there is still a bug which is potentially an issue with KVO.
	
	Currently it is suggested that the `completionBlock` associated with `NSOperation` is avoid. Other frameworks expressly forbid its usage, and there is even a Radar from Dave De Long recommending it be deprecated.
	
	The original issue, [#175](https://github.com/danthorpe/Operations/issue/180) is still being tracked.

3. [[OPR-181](https://github.com/danthorpe/Operations/pull/189)]: Fixes a bug in `GroupOperation` where many child operations which failed could cause a crash. Now access to the `aggregateErrors` property is thread safe, and this issue is tested with a tight loop of 10,000 child operations which all fail. Thanks to [@ansf](https://github.com/ansf) for reporting this one.
	
### Thanks!

 I want to say a *huge thank you* to everyone who has contributed to this project so far. Whether you use the framework in your apps (~ 90 apps, 6k+ downloads via CocoaPods metrics), or you’ve submitted issues, or even sent me pull requests - thanks!  
 
 I don’t think I’d be able to find anywhere near the number of edge cases without all the help. The suggestions and questions from everyone keeps me learning new stuff. 

Cheers,
Dan

### What’s next?

I’ve not got anything too major planned right now, except improving the example projects. So the next big thing will probably be Swift 3.0 support, and possibly ditching `NSOperation`.



# 2.5.1
1. [[OPR-151](https://github.com/danthorpe/Operations/pull/151), [OPR-155](https://github.com/danthorpe/Operations/pull/155)]: Fixes a bug where `UserLocationOperation` could crash when the LocationManager returns subsequent locations after the operation has finished.

# 2.5.0

This is a relatively large number of changes with some breaking changes from 2.4.*.

### Breaking changes

1. [[OPR-140](https://github.com/danthorpe/Operations/pull/140)]: `OperationObserver` has been refactored to refine four different protocols each with a single function, instead of defining four functions itself. 

    The four protocols are for observing the following events: *did start*, *did cancel*, *did produce operation* and *did finish*. There are now specialized block observers, one for each event.

    This change is to reflect that observers are generally focused on a single event, which is more in keeping with the single responsibility principle. I feel this is better than a single type which typically has either three no-op functions or consists entirely of optional closures.

    To observe multiple events using blocks: add multiple observers. Alternatively, create a bespoke type to observe multiple events with the same type.

    `BlockObserver` itself still exists, however its usage is discouraged and it will be removed at a later time. It may also be necessary to make syntactic changes to existing code, in which case, I recommend replacing its usage entirely with one or more of `StartedObserver`, `CancelledObserver`, `ProducedOperationObserver` or `FinishedObserver`, all of which accept a non-optional block.

2. [[OPR-139](https://github.com/danthorpe/Operations/pull/139)]: Removed `Capabiltiy.Health`. Because this capability imports HealthKit, it is flagged by the app review team, and an application may be rejecting for not providing guidance on its usage of HealthKit. Therefore, as the majority of apps probably do not use this capability, I have removed it from the standard application framework. It is available as a subspec through Cocoapods:

    ```ruby
    pod 'Operations/+Health'
    ```

### Improvements

1. [[OPR-121](https://github.com/danthorpe/Operations/issues/121),[OPR-122](https://github.com/danthorpe/Operations/pull/122), [OPR-126](https://github.com/danthorpe/Operations/pull/126), [OPR-138](https://github.com/danthorpe/Operations/pull/138)]: Improves the built in logger. So that now:

    1. the message is enclosed in an  `@autoclosure`. 
    2. there is a default/global severity threshold
    3. there is a global enabled setting.

    Thanks to Jon ([@jshier](https://github.com/jshier)) for raising the initial issue on this one.

2. [[OPR-128](https://github.com/danthorpe/Operations/pull/128)]: Improves how code coverage is generated.

    Thanks to Steve ([@stevepeak](https://github.com/stevepeak)) from [Codecov.io](https://codecov.io) for helping with this.

3. [[OPR-133](https://github.com/danthorpe/Operations/issues/133), [OPR-134](https://github.com/danthorpe/Operations/pull/134)]: `DelayOperation` and `BlockOperation` have improved response to being cancelled.

    Thanks to Jon ([@jshier](https://github.com/jshier)) for raising the initial issue on this one.

4. [[OPR-132](https://github.com/danthorpe/Operations/pull/132)]: `BlockObserver` now supports a cancellation handler. However see the notes regarding changes to `OperationObserver` and `BlockObserver` above under breaking changes.

5. [[OPR-135](https://github.com/danthorpe/Operations/issues/135),[OPR-137](https://github.com/danthorpe/Operations/pull/137)]: Result Injection.

    It is now possible to inject the results from one operation into another operation as its requirements before it executes. This can be performed with a provided block, or automatically in the one-to-one, result-to-requirement case. See the [programming guide](https://operations.readme.io/docs/injecting-results) for more information.

    Thanks very much to Frank ([@difujia](https://github.com/difujia)) for the inspiration on this, and Jon ([@jshier](https://github.com/jshier)) for contributing to the discussion.

6. [[OPR-141](https://github.com/danthorpe/Operations/pull/141)]: `Operation` now uses `precondition` to check the expectations of public APIs. These are called out in the function’s documentation. Thanks to the Swift evolution mailing list & Chris Lattner on this one.

7. [[OPR-144](https://github.com/danthorpe/Operations/issues/144), [OPR-145](https://github.com/danthorpe/Operations/pull/145)]: Supports adapting the internal logger to use 3rd party logging frameworks. The example project uses [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver) as a logger. 

    Thanks to Steven ([@shsteven](https://github.com/shsteven)) for raising the issue on this one!

8. [[OPR-148](https://github.com/danthorpe/Operations/pull/148)]: Location operations now conform to `ResultOperationType` which means their result (`CLLocation`, `CLPlacemark`) can be injected automatically into appropriate consuming operations.

### Bug Fixes

1. [[OPR-124](https://github.com/danthorpe/Operations/pull/124)]: Fixes a bug where notification names conflicted. 

    Thanks to Frank ([@difujia](https://github.com/difujia)) for this one.

2. [[OPR-123](https://github.com/danthorpe/Operations/issues/123),[OPR-125](https://github.com/danthorpe/Operations/pull/125), [OPR-130](https://github.com/danthorpe/Operations/pull/130)]: Fixes a bug where a completion block would be executed twice. 

    Thanks again to Frank ([@difujia](https://github.com/difujia)) for raising the issue.

3. [[OPR-127](https://github.com/danthorpe/Operations/issues/127), [OPR-131](https://github.com/danthorpe/Operations/pull/131)]: Fixes a bug where an operation could fail to start due to a race condition. Now, if an operation has no conditions, rather than entering a `.EvaluatingConditions` state, it will immediately (i.e. synchronously) become `.Ready`. 

    Thanks to Kevin ([@kevinbrewster](https://github.com/kevinbrewster)) for raising this issue.

4. [[OPR-142](https://github.com/danthorpe/Operations/pull/142)]: `Operation` now checks the current state in comparison to `.Ready` before adding conditions or operations. This is unlikely to be a breaking change, as it is not a significant difference.

    Thanks to Frank ([@difujia](https://github.com/difujia)) for this one.

5. [[OPR-146](https://github.com/danthorpe/Operations/pull/146)]: Fixes a subtle issue where assessing the readiness could trigger state changes.


Thanks to [@difujia](https://github.com/difujia), [@jshier](https://github.com/jshier), [@kevinbrewster](https://github.com/kevinbrewster), [@shsteven](https://github.com/shsteven) and [@stevepeak](https://github.com/stevepeak) for contributing to this version. :)


# 2.4.1
1. [[OPR-113](https://github.com/danthorpe/Operations/pull/113)]: Fixes an issue where building against iOS 9 using Carthage would unleash a tidal wave of warnings related to ABAddressBook. Thanks to [@JaimeWhite](https://github.com/JamieWhite) for bringing this to my attention!
2. [[OPR-114](https://github.com/danthorpe/Operations/pull/114)]: Reorganized the repository into two project files. One create standard frameworks for applications, for iOS, watchOS, tvOS, and OS X. The other creates Extension API compatible frameworks for iOS, tvOS and OS X. At the moment, if you wish to use an API extension compatible framework with Carthage - this is a problem, as Carthage only builds one project, however the is a Pull Request which will fix this. The issue previously was that the `Operations.framework` products would overwrite each other. I’ve tried everything I can think of to make Xcode produce a product which has a different name to its module - but it won’t let me. So.. the best thing to do in this case is use CocoaPods and the Extension subspec.
3. [[OPR-115](https://github.com/danthorpe/Operations/pull/115)]: Fixes an issue with code coverage after project reorganization.
4. [[OPR-116](https://github.com/danthorpe/Operations/pull/116)]: Fixes a mistake where `aggregateErrors` was not publicly accessible in `GroupOperation`. Thanks to [@JaimeWhite](https://github.com/JamieWhite) for this.

Thanks a lot to [@JaimeWhite](https://github.com/JamieWhite) for helping me find and squash some bugs with this release. Greatly appreciated!  

# 2.4.0
1. [[OPR-108](https://github.com/danthorpe/Operations/pull/108)]: Adds an internal logging mechanism to `Operation`. Output log information using the `log` property  of the operation. This property exposes simple log functions. E.g.

   ```swift
   let operation = MyOperation() // etc
   operation.log.info(“This is a info message.”)
   ```
To use a custom logger, create a type conforming to `LoggerType` and add an instance property to your `Operation` subclass. Then override `getLogger()` and `setLogger(: LoggerType)` to get/set your custom property.

The global severity is set to `.Warning`, however individual operation loggers can override to set it lower, e.g. 

    ```swift
    operation.log.verbose(“This verbose message will not be logged, as the severity threshold is .Warning”)
    operation.log.severity = .Verbose
    operation.log.verbose(“Now it will be logged.”)
    ```
2. [[OPR-109](https://github.com/danthorpe/Operations/pull/109)]: Added documentation to all of the Capability (device permissions etc) functionality. Also now uses Jazzy categories configuration to make the generated documentation more easily navigable. Documentation is hosted on here: [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.4.0/index.html).


# 2.3.0
1. [[OPR-89](https://github.com/danthorpe/Operations/pull/89)]: Adds support (via subspecs) for watchOS 2 and tvOS apps.
2. [[OPR-101](https://github.com/danthorpe/Operations/pull/101)]: Fixes a bug where `ReachableOperation` may fail to start in some scenarios.
3. [[OPR-102](https://github.com/danthorpe/Operations/pull/102)]: Adds more documentation to the finish method of Operation. If it’s possible for an Operation to be cancelled before it’s started, then do not call finish. This is mostly likely a possibility when writing network operations and cancelling groups.
4. [[OPR-103](https://github.com/danthorpe/Operations/pull/103)]: Adds % of code covered by tests to the README. Service performed by CodeCov.
5. [[OPR-104](https://github.com/danthorpe/Operations/pull/104)]: Maintenance work on the CI scripts, which have now moved to using a build pipeline which is uploaded to BuildKite and executed all on the same physical box. See [post on danthorpe.me](http://danthorpe.me/posts/uploading-build-pipelines.html).
6. [[OPR-105](https://github.com/danthorpe/Operations/pull/105)]: Improves the testability and test coverage of the Reachability object.
7. [[OPR-106](https://github.com/danthorpe/Operations/pull/106)]: Adds more tests to the AddressBook swift wrapper, increases coverage of `Operation`, `NegatedCondition` & `UIOperation`.

# 2.2.1
1. [[OPR-100](https://github.com/danthorpe/Operations/pull/100)]: Adds documentation to all “Core” elements of the framework. Increases documentation coverage from 8% to 22%. Still pretty bad, but will get there eventually.

# 2.2.0
1. [[OPR-91](https://github.com/danthorpe/Operations/pull/91), [OPR-92](https://github.com/danthorpe/Operations/pull/92)]: Fixes a bug in AddressBook when building against iOS 9, where `Unmanaged<T>` could be unwrapped incorrectly.
2. [[OPR-93](https://github.com/danthorpe/Operations/pull/93), [OPR-95](https://github.com/danthorpe/Operations/pull/95)]: Adds support for Contacts.framework including `ContactsCondition` plus operations for `GetContacts`, `GetContactsGroup`, `RemoveContactsGroup`, `AddContactsToGroup` and `RemoveContactsFromGroup` in addition to a base contacts operation class. Also included are UI operations `DisplayContactViewController` and `DisplayCreateContactViewController`.
3. [[OPR-97](https://github.com/danthorpe/Operations/pull/97), [OPR-98](https://github.com/danthorpe/Operations/pull/98)]: Refactors how device authorization permissions are checked and requested. Introduces the concept of a `CapabilityType` to govern authorization status and requests. This works in tandem with new operations `GetAuthorizationStatus<Capability>` and `Authorize<Capability>` with an operation condition `AuthorizedFor<Capability>`. The following conditions are now deprecated: `CalendarCondition`, `CloudContainerCondition`, `HealthCondition`, `LocationCondition`, `PassbookCondition`, `PhotosCondition` in favor of `Capability.Calendar`, `Capability.Cloud`, `Capability.Heath`, `Capability.Location`, `Capability.Passbook`, `Capability.Photos` respectively. Replace your condition code like this example:

```swift
operation.addCondition(AuthorizedFor(Capability.Location(.WhenInUse)))
```

# 2.1.0
1. [[OPR-90](https://github.com/danthorpe/Operations/pull/90)]: Multi-platform support. Adds new framework targets to the project for iOS Extension only API framework. This doesn’t have support for BackgroundObserver, or NetworkObserver for example. Use `pod ‘Operations/Extension’` to use it in a Podfile for your iOS Extension target. Also, we have Mac OS X support (no special pod required). And watchOS support - use `pod ‘Operations/watchOS’`.

# 2.0.2
1. [[OPR-87](https://github.com/danthorpe/Operations/pull/87)]: Improves the reliability of the reverse geocoder unit tests.

# 2.0.1
1. [[OPR-62, OPR-86](https://github.com/danthorpe/Operations/pull/86)]: Fixes a bug in Swift 2.0 where two identical conditions would cause a deadlock. Thanks to @mblsha.
2. [[OPR-85](https://github.com/danthorpe/Operations/pull/85)]: Fixes up the Permissions example project for Swift 2.0. Note that YapDatabase currently has a problem because it has some weak links, which doesn’t work with Bitcode enabled, which is default in Xcode 7. This PR just turned off Bitcode, but if you re-run the Pods, then that change will be over-ridden. What you can do instead, if YapDatabase is still not fixed is to use my fork which has a fix on the `YAP-180` branch.

# 2.0.0
This is the Swift 2.0 compatible version.

# 1.0.0
1. [[OPR-79](https://github.com/danthorpe/Operations/pull/79)]: Adds more documentation to the types.
2. [[OPR-83](https://github.com/danthorpe/Operations/pull/83)]: Adds some convenience functions to `NSOperation` and `GroupOperation` for adding multiple dependencies at once, and multiple operations to a group before it is added to a queue.

This is a release for Swift 1.2 compatible codebases.

# 0.12.1
1. [[OPR-74](https://github.com/danthorpe/Operations/pull/74)]: Work in progress on AddressBook external change request. *Warning* so not use this, as I cannot actually get this working yet.
2. [[OPR-75](https://github.com/danthorpe/Operations/pull/75)]: Fixes a serious bug where attempting to create an ABAddressBook after previously denying access executed a fatalError.

# 0.12.0
1. [[OPR-63](https://github.com/danthorpe/Operations/pull/63)]: Speeds up the test suite by 40 seconds.
2. [[OPR-65](https://github.com/danthorpe/Operations/pull/65)]: Adds a generic `UIOperation` class. Can be used to show view controllers, either present modally, show or show detail presentations. It is used as the basis for `AlertOperation`, and the `AddressBookDisplayPersonController`, `AddressBookDisplayNewPersonController` operations.
3. [[OPR-67](https://github.com/danthorpe/Operations/pull/67)]: Adds reverse geocode operations. Supply a `CLLocation` to `ReverseGeocodeOperation` directly. Or use `ReverseGeocodeUserLocationOperation` to reverse geocode the user’s current location. Additionally, `LocationOperation` has been renamed to `UserLocationOperation`.
4. [[OPR-68](https://github.com/danthorpe/Operations/pull/68)]: General improvements to the `AddressBook` APIs including a `createPerson` function, plus addition of missing person properties & labels. Additionally, fixes a bug in setting multi-value string properties.
5. [[OPR-71](https://github.com/danthorpe/Operations/pull/71)]: Updates the unit test scripts to use Fastlane, same as Swift 2.0 branch.

# 0.11.0
1. [[OPR-45](https://github.com/danthorpe/Operations/pull/45), [OPR-46](https://github.com/danthorpe/Operations/pull/46), [OPR-47](https://github.com/danthorpe/Operations/pull/47), [OPR-48](https://github.com/danthorpe/Operations/pull/48), [OPR-49](https://github.com/danthorpe/Operations/pull/49), [OPR-54](https://github.com/danthorpe/Operations/pull/54)]:

Refactor of AddressBook.framework related functionality. The `AddressBookOperation` is no longer block based, but instead keeps a reference to the address book as a property. This allows for superior composition. Additionally there is now an `AddressBookGetResource` operation, which will access the address book, and then exposes methods to read people, and if set, an individual person record and group record.

Additionally, there is now operations for adding/removing a person to a group. Add/Remove groups. And map all the people records into your own type.

Internally, these operations are supported by a Swift wrapper of the AddressBook types, e.g. `AddressBookPerson` etc. This wrapper is heavily inspired by the Gulliver. If you want more powerful AddressBook features, I suggest you checkout that project, and then either subclass the operations to expose Gulliver types, or write a simple protocol extension to get Gulliver types from `AddressBookPersonType` etc etc.

2. [[OPR-57](https://github.com/danthorpe/Operations/pull/57)]: The CloudKitOperation is no longer a GroupOperation, just a standard Operation, which enqueues the `CKDatabaseOperation` onto the database’s queue directly.
3. [[OPR-58](https://github.com/danthorpe/Operations/pull/58)]: Added `ComposedOperation` which is a specialized `GatedOperation` which always succeeds. This is handy if you want to add conditions or observers to an `NSOperation`.
4. [[OPR-60](https://github.com/danthorpe/Operations/pull/60)]: Renamed `NoCancellationsCondition` to `NoFailedDependenciesCondition` which encompasses the same logic, but will also fail if any of the operation’s dependencies are `Operation` subclasses which have failed. In addition, `Operation` now exposes all it’s errors via the `errors` public property.

# 0.10.0
1. [[OPR-14](https://github.com/danthorpe/Operations/pull/14)]: Supports Photos library permission condition.
2. [[OPR-16](https://github.com/danthorpe/Operations/pull/16)]: Supports Health Kit permission condition.

# 0.9.0
1. [[OPR-11](https://github.com/danthorpe/Operations/pull/11)]: Supports Passbook condition.
2. [[OPR-13](https://github.com/danthorpe/Operations/pull/13)]: Supports a EventKit permission condition.
3. [[OPR-17](https://github.com/danthorpe/Operations/pull/17)]: Supports remote notification permission condition.
4. [[OPR-18](https://github.com/danthorpe/Operations/pull/18)]: Supports user notification settings condition.
5. [[OPR-38](https://github.com/danthorpe/Operations/pull/38)]: Adds a `LocationOperation` demo to Permissions.app
6. [[OPR-39](https://github.com/danthorpe/Operations/pull/39)]: Adds a user confirmation alert condition.


# 0.8.0
1. [[OPR-37](https://github.com/danthorpe/Operations/pull/37)]: Creates an example app called Permissions. This is a simple catalogue style application which will be used to demonstrate functionality of the Operations framework.

At the moment, it only shows Address Book related functionality. Including using combinations of `SilentCondition`, `NegatedCondition` and `AddressBookCondition` to determine if the app has already got authorization, requesting authorization and performing a simple ABAddressBook related operation.

Additionally, after discussions with Dave DeLong, I’ve introduced changes to the underlying Operation’s state machine.

Lastly, the structure of `BlockOperation` has been modified slightly to allow the task execution block to pass an error (`ErrorType`) into the continuation block. Because closures cannot have default arguments, this currently means that it is required, e.g. `continueWithError(error: nil)` upon success. 
 

# 0.7.0
1. [[OPR-7](https://github.com/danthorpe/Operations/pull/7)]: Supports a condition which requires all of an operation’s dependencies to succeed.
2. [[OPR-12](https://github.com/danthorpe/Operations/pull/12)]: Adds `LocationOperation` and `LocationCondition`. This allows for accessing the user’s location, requesting “WhenInUse” authorization.
3. [[OPR-36](https://github.com/danthorpe/Operations/pull/36)]: Adds `AddressBookOperation` which allows for access to the user’s address book inside of a handler block (similar to a `BlockOperation`). As part of this, `AddressBookCondition` is also available, which allows us to condition other operation types.


# 0.6.0
1. [[OPR-5](https://github.com/danthorpe/Operations/pull/5)]: Supports silent conditions. This means that if a condition would normally produce an operation (say, to request access to a resource) as a dependency, composing it inside a `SilentCondition` will suppress that dependent operation.
2. [[OPR-6](https://github.com/danthorpe/Operations/pull/r)]: Supports negating condition.
3. [[OPR-30](https://github.com/danthorpe/Operations/pull/30)]: Adds a `LoggingObserver` to log operation lifecycle events.
4. [[OPR-33](https://github.com/danthorpe/Operations/pull/33)]: Adds `GatedOperation` which will only execute the composed operation if the supplied block evaluates true - i.e. opens the gate.
5. [[OPR-34](https://github.com/danthorpe/Operations/pull/34)] & [[OPR-35](https://github.com/danthorpe/Operations/pull/35)]: Adds a `ReachableOperation`. Composing an operation inside a `ReachableOperation` will ensure that it runs after the device regains network reachability. If the network is reachable, the operation will execute immediately, if not, it will register a Reachability observer to execute the operation when the network is available. Unlike the `ReachabilityCondition` which will fail if a host is not available, use `ReachableOperation` to perform network related tasks which must be executed regardless.


# 0.5.0
1. [[OPR-22](https://github.com/danthorpe/Operations/pull/22)]: Supports displaying a `UIAlertController` as a `AlertOperation`.
2. [[OPR-26](https://github.com/danthorpe/Operations/pull/26)]: Adds a Block Condition. This allows an operation to only execute if a block evaluates true.
3. [[OPR-27](https://github.com/danthorpe/Operations/pull/27)]: Fixes a bug where the `produceOperation` function was not publicly accessible. Thanks - @MattKiazyk
4. [[OPR-28](https://github.com/danthorpe/Operations/pull/28)]: Supports a generic `Operation` subclass which wraps a `CKDatabaseOperation` setting the provided `CKDatabase`.
5. [[OPR-29](https://github.com/danthorpe/Operations/pull/29)]: Improves the `CloudCondition.Error` to include `.NotAuthenticated` for when the user is not signed into iCloud.


# 0.4.2 - Initial Release of Operations.
Base `Operation` and `OperationQueue` classes, with the following features.

The project has been developed using Xcode 7 and Swift 2.0, with  unit testing (~ 75% test coverage). It has now been back-ported to Swift 1.2 for version 1.0 of the framework. Version 2.0 will support Swift 2.0 features, including iOS 9 technologies such as Contacts framework etc.

1. Operation types:
1.1. `BlockOperation`: run a block inside an operation, taking advantage of Operation features.
1.2. `GroupOperation`: compose one more operations into a group.
1.3. `DelayOperation`: delay execution of operations on the queue.

2. Conditions
Conditions can be attached to `Operation`s, and optionally introduce new `NSOperation` instances to overcome the condition requirements. E.g. presenting a permission dialog. The following conditions are currently supported:
2.1. `MutuallyExclusive`: for exclusivity of a given kind, e.g. to prevent system alerts presenting at the same time.
2.2. `ReachabilityCondition`: only execute tasks when the device is online.
2.3. `CloudCondition`: authorised access to a CloudKit container. 

3. Observers
Observers can be attached to `Operation`s, and respond to events such as the operation starting, finishing etc. Currently observer types are:
3.1. `BackgroundObserver`: when the app enters the background, a background task will automatically be started, and ended when the operation ends.
3.2. `BlockObserver`: run arbitrary blocks when events occur on the observed operation.
3.3. `NetworkObserver`: updates the status of the network indicator.
3.4. `TimeoutObserver`: trigger functionality if the operation does not complete within a given time interval.

