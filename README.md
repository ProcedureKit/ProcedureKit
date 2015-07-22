# Operations

A reusable Swift framework Inspired by WWDC 2015 Advanced NSOperations session. See the session video here: https://developer.apple.com/videos/wwdc/2015/?id=226

I want to stress that this code is heavily influenced by Apple. The only changes I have made so far have been bug fixes, and architectural changes to increase the testability of the classes. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

While not currently feature compatible with Apple’s sample code, it currently does support the basic concepts, along with some useful observers and conditions.

In addition, the framework is well tested, with approximately 70% coverage. This is known as I wrote it using Xcode 7 but have back ported it to Swift 1.2.

Missing Operation types will be added, see the project’s Milestones.
