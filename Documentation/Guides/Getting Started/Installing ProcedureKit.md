# Installing _ProcedureKit_

_ProcedureKit_ is a "multi-module" framework (don't bother Googling that, I just made it up). What we mean by this, is that the Xcode project has multiple targets/products each of which produces a Swift module. Some of these modules are cross-platform, others are dedicated, e.g. `ProcedureKitNetwork` vs `ProcedureKitMobile`.

You can add _ProcedureKit_ to your project, by following [Apple's guidelines](https://www.google.com/search?q=apple+docs,+add+framework+to+xcode+project) (dragging the `.xcodeproj` file into your project). Alternatively, you can use package managers as described below.

## CocoaPods

ProcedureKit is available through [CocoaPods](https://cocoapods.org/pods/ProcedureKit). To install
it, include it in your Podfile. Here is a full example of a cross platform application with unit test support. In this case, _ProcedureKit_ has been included via submodules.

```ruby
target 'MyApp' do
  platform :osx, '10.11'

  use_frameworks!

  # This subspec includes all the cross-platform modules
  # including networking, location & cloudkit
  pod 'ProcedureKit/All', :path => 'submodules/ProcedureKit'

  target 'TryProcedureKitTests' do
    inherit! :search_paths
    # This pod provides test harnesses and mechanism to help
    # write unit tests for your Procedures
    pod 'TestingProcedureKit', :path => 'submodules/ProcedureKit'
  end
end

target 'MyApp iOS' do
  platform :ios, '10'
  use_frameworks!

  pod 'ProcedureKit/All', :path => 'submodules/ProcedureKit'
  # This subspec is the iOS only UIKit related stuff
  pod 'ProcedureKit/Mobile', :path => 'submodules/ProcedureKit'  

  target 'TryProcedureKit iOSTests' do
    inherit! :search_paths
    pod 'TestingProcedureKit', :path => 'submodules/ProcedureKit'
  end
end
```

Now, due to the way that CocoaPods works, all code from the _ProcedureKit_ is made available under a single module name, `ProcedureKit`. This is because CocoaPods creates its own Xcode targets to add the files defined in the spec. So, your Swift files will only need to add `import ProcedureKit` even if you want to use functionality from other modules, such as  _ProcedureKitMobile_. We appreciate that this can be a bit confusing!

## Carthage

Add the following line to your Cartfile:

```ruby
github 'ProcedureKit/ProcedureKit'
```

Then update your `Carthage` directory by running on the command line:

```bash
$ carthage bootstrap
```
This will go off and build everything. It'll take a short while, definitely time for a cup of tea. When it's complete, you can drag the built frameworks to your project and embed them in the binary.

When using Carthage, each module is separated out. So, if you want to use the networking APIs, you would add the following to your Swift file:

```swift
import ProcedureKit
import ProcedureKitNetwork
```

## Swift Package Manager
_ProcedureKit_ totally supports SPM, it's basically just like Carthage.
