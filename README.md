# Operations

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. See the session video here: https://developer.apple.com/videos/wwdc/2015/?id=226

I want to stress that this code is heavily influenced by Apple. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

Rather than just copy Apple’s sample code, I have been re-writing it from scratch, but heavily guided. The main changes I have made, other than some minor bug fixes, have been architectural to enhance the testability of the code. Unfortunately, this makes the public API a little messy for Swift 1.2, but thanks to `@testable` will not be visible in Swift 2.

Other changes, beyond what Apple have shown will be forthcoming. Already, there is a `BlockCondition` which will only allow it’s parent operation to execute if a block evaluates true. Additionally, I have improved the utility of the framework for CloudKit operations. 

So, while not currently feature compatible with Apple’s sample code, it currently does support the basic concepts, along with some useful observers and conditions.

The framework is well tested, with approximately 70% coverage. This is known as I wrote it using Xcode 7 but have back ported it to Swift 1.2.

Development of a usable Swift 1.2 version is the priority. However, development of the Swift 2.0 version will shortly begin in parallel, and increase in priority. Therefore the versioning of this project will follow this pattern: Swift 1.2: `0.4 -> 1.x` and Swift 2.0: `2.0 -> 2.x`. 
