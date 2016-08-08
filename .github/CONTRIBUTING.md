# Contributing Guidelines

This document contains information and guidelines about contributing to this project.

## Before creating a GitHub Issue
Before creating an issue, please search the project first. Your question or bug may have already been asked, answered and or reported. 

Additionally, frequently asked questions are collected in the Wiki.

## Asking Questions
1. Create an issue in the project.
    Please prefix your subject with `[Question]:`, it will get labelled as such. Please try to reduce your question into elements which are specific to _ProcedureKit_.
3. Ask a question on [Stack Overflow](http://stackoverflow.com).
    Add a tag `procedure-kit` to your question, or reference core contributors such as [@Daniel.Thorpe](http://stackoverflow.com/users/197626/daniel-thorpe).

## Reporting Bugs
A great way to contribute to the project is to send a detailed issue when you encounter a problem. A well written and detailed bug report is always welcome.

Please include verbose log output. Verbose logging can be enabled globally:

```swift
LogManager.severity = .Verbose
```

or for a single operation:

```swift
operation.log.severity = .Verbose
```

this will print out lifecycle event, and is very useful for debugging scheduling issues.

## Contributing Code
Before contributing code, create an issue to engage with core contributors about the feature or changes you wish to make.

1. Install SwiftLint
    The project uses [SwiftLint](https://github.com/realm/SwiftLint) to maintain a consistent Swift style. Linting occurs during an Xcode build phase, at which time white space issues are automatically corrected.
    
    ```
    brew install swiftlint
    ```    
2. Write unit tests 
    We are aiming for maximum test coverage. Most importantly, we want to always increase coverage which is currently ~ 75%. Please ask (in your GitHub issue) if you are unsure how to write unit tests for features you are adding.
3. Write documentation
    Add source code documentation in English for any public interfaces. Try to follow the tone of the existing documentation. Please ask (in your GitHub issue) for clarity on how to write documentation if you are unsure.
4. Prefix your commit messages
    Use the GitHub ticket number, browse the commit history for examples.

## Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

- (a) The contribution was created in whole or in part by me and I have the right to submit it under the open source license indicated in the file; or

- (b) The contribution is based upon previous work that, to the best of my knowledge, is covered under an appropriate open source license and I have the right under that license to submit that work with modifications, whether created in whole or in part by me, under the same open source license (unless I am permitted to submit under a different license), as indicated in the file; or

- (c) The contribution was provided directly to me by some other person who certified (a), (b) or (c) and I have not modified it.

- (d) I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it, including my sign-off) is maintained indefinitely and may be redistributed consistent with this project or the open source license(s) involved.

## Code of Conduct
The code of conduct governs how we behave in public or in private whenever the project will be judged by our actions. We expect it to be honored by everyone who contributes to this project. See [CONDUCT.md](CONDUCT.md).
