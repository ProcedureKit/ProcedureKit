# YapDatabaseExtensions

[![Join the chat at https://gitter.im/danthorpe/YapDatabaseExtensions](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/danthorpe/YapDatabaseExtensions?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build status](https://badge.buildkite.com/95784c169af7db5e36cefe146d5d3f3899c8339d46096a6349.svg)](https://buildkite.com/danthorpe/yapdatabaseextensions)
[![CocoaPods version](https://img.shields.io/cocoapods/v/YapDatabaseExtensions.svg)](https://cocoapods.org/pods/YapDatabaseExtensions) 
[![MIT License](https://img.shields.io/cocoapods/l/YapDatabaseExtensions.svg)](LICENSE) 
[![Platform iOS OS X](https://img.shields.io/cocoapods/p/YapDatabaseExtensions.svg)](PLATFORM)

Read my introductory blog post about [YapDatabase & YapDatabaseExtensions](http://danthorpe.me/posts/yap-database.html).

## Updates r.e. Xcode 7 & Swift 2.0

The core elements of YapDatabaseExtensions supports Swift 2.0 on the branch `swift_2.0`. Install it using CocoaPods like so:

```ruby
pod ‘YapDatabaseExtensions’, :git => ‘https://github.com/danthorpe/YapDatabaseExtensions.git', :branch => ‘swift_2.0’
```

If you need to use YapDatabaseExtensions in a Swift 2.0 framework using CocoaPods, make sure that you include the line above in the application target’s Podfile to override podspec dependencies.

At the moment, Swift 2.0 support for extensions on FRP libraries  is pending support in those libraries, so it will follow in due course. I won’t merge this branch until it is at feature parity with `master`.

Lastly, until `xctool` is updated, continuous integration is not working, however I do have Xcode bots configured, so the quality of the `master`, `development` and `swift-2.0` branches is maintained. Additionally, I can now remote the test coverage of this library, which is currently at 53%, something which I fully intend to improve over the coming month.

## Requirements

[YapDatabase](https://github.com/yapstudios/YapDatabase) :)

## Installation

YapDatabaseExtensions is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'YapDatabaseExtensions'
```

## Usage

This framework extends a `YapDatabaseTransaction` and `YapDatabaseConnection` with type-safe `read`, `write` and `remove` APIs with both synchronous and asynchronous variants. However, to leverage such APIs, your own domain types must conform to some generic protocols.

### Persistable & Identifiable 

The `Persistable` protocol defines how the object will be indexed in YapDatabase. It extends the generic `Identifiable` protocol.

```swift

public protocol Identifiable {
    typealias IdentifierType: Printable
    var identifier: IdentifierType { get }
}

public protocol Persistable: Identifiable {
    static var collection: String { get }
}

```

Typically, it would be implemented like so:

```swift
extension User: Persistable, Identifiable {

    static var collection: String { 
    	return "Users"
    }
    
    var identifier: Int { 
    	return userId
    }
}
```

Assuming that `userId` is a unique identifier for the type. Note that `String` doesn't actually conform to `Printable` but it's implemented in an extension on a typealias called `Identifier`.

There is also `MetadataPersistable` protocols which can be used to expose metadata on the type.

### Using value types in YapDatabase

To use struct or enum types with YapDatabase requires implementing the `Saveable` protocol, in addition to `Persistable`. `Saveable` in turn requires an `Archiver` type. This essentially, expose a class which implements `NSCoding` as an archiving adaptor for your value type. 

For example, this is the Barcode enum from "The Swift Programming Language" book:

```swift

enum Barcode {
    case UPCA(Int, Int, Int, Int)
    case QRCode(String)
}

```

It can be saved in YapDatabase with the following extension:

```swift

extension Barcode: Persistable {

    static var collection: String {
        return "Barcodes"
    }

    var identifier: Identifier {
        switch self {
        case let .UPCA(numberSystem, manufacturer, product, check):
            return "\(numberSystem).\(manufacturer).\(product).\(check)"
        case let .QRCode(code):
            return code
        }
    }
}

extension Barcode: Saveable {

    typealias Archive = BarcodeArchiver

	enum Kind: Int { case UPCA = 1, QRCode }

    var archive: Archive {
        return Archive(self)
    }

	var kind: Kind {
		switch self {
		case UPCA(_): return Kind.UPCA
		case QRCode(_): return Kind.QRCode
		}
	}
}

class BarcodeArchiver: NSObject, NSCoding, Archiver {
	let value: Barcode

    required init(_ v: Barcode) {
        value = v
    }

    required init(coder aDecoder: NSCoder) {
		if let kind = Barcode.Kind(rawValue: aDecoder.decodeIntegerForKey("kind")) {
			switch kind {
			case .UPCA:
				let numberSystem = aDecoder.decodeIntegerForKey("numberSystem")
				let manufacturer = aDecoder.decodeIntegerForKey("manufacturer")
				let product = aDecoder.decodeIntegerForKey("product")
				let check = aDecoder.decodeIntegerForKey("check")
                value = .UPCA(numberSystem, manufacturer, product, check)
            case .QRCode:
                let code = aDecoder.decodeObjectForKey("code") as! String
                value = .QRCode(code)
			}
		}
		preconditionFailure("Barcode.Kind not correctly encoded.")
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(value.kind.rawValue, forKey: "kind")
		switch value {
		case let .UPCA(numberSystem, manufacturer, product, check):
			aCoder.encodeInteger(numberSystem, forKey: "numberSystem")
			aCoder.encodeInteger(manufacturer, forKey: "manufacturer")
			aCoder.encodeInteger(product, forKey: "product")
			aCoder.encodeInteger(check, forKey: "check")
		case let .QRCode(code):
			aCoder.encodeObject(code, forKey: "code")
		}
    }
}

```

This may look like quite a bit of code, but it's really just NSCoding. And it’s likely this already exists on your classes. Therefore, it’s easy to move it into a bespoke Archiver class. This can help keep your domain types clean and easy to comprehend. See the example project for more examples of implementations of `Saveable`, including nesting value types.

## The Functions
The framework provides a number of generic functions in extensions on `YapDatabaseReadTransaction`, `YapDatabaseReadWriteTransaction`, `YapDatabaseConnection` and `YapDatabase`. The latter set are provided mostly for ease of use and testing however, and it is strongly recommended that `YapDatabaseConnection` references are owned and operated on.

The functions support synchronous or asynchronous reading of item by index or key, either individually or in arrays. For example:

```swift
if let barcode: Barcode = connection.read(key) {
	println(“the barcode: \(barcode)”)
}

connection.asyncRead(key) { (barcode: Barcode) in 
	println(“the barcode: \(barcode)”)
}
```

### FRP Library support for PromiseKit, BrightFutures etc
The default subspec provides asynchronous methods using callback closures, see above.

In addition, there is support for asynchronous APIs using some popular 3rd party functional reactive programming libraries. These are available as CocoaPods subspecs, e.g.

```ruby
pod 'YapDatabaseExtensions/PromiseKit'
```

will make APIs such as the following possible:

```swift
connection.asyncRead(key).then { (barcode: Barcode) -> Void in
  println(“the barcode: \(barcode)”)
}
```

The following are supported:
- [x] [PromiseKit](http://promisekit.org)
- [x] [Bright Futures](https://github.com/Thomvis/BrightFutures)
- [x] [SwiftTask](https://github.com/ReactKit/SwiftTask)
- [ ] [ReactiveCocoa 3.0](https://github.com/ReactiveCocoa/ReactiveCocoa/releases/tag/v3.0-beta.1)

## API Documentation

API documentation is available on [CocoaDocs.org](http://cocoadocs.org/docsets/YapDatabaseExtensions).

## Author

Daniel Thorpe, @danthorpe

## License

YapDatabaseExtensions is available under the MIT license. See the LICENSE file for more info.
