# Strongbox

[![CI Status](http://img.shields.io/travis/granoff/Strongbox.svg?style=flat)](https://travis-ci.org/granoff/Strongbox)
[![Version](https://img.shields.io/cocoapods/v/Strongbox.svg?style=flat)](http://cocoapods.org/pods/Strongbox)
[![License](https://img.shields.io/cocoapods/l/Strongbox.svg?style=flat)](http://cocoapods.org/pods/Strongbox)
[![Platform](https://img.shields.io/cocoapods/p/Strongbox.svg?style=flat)](http://cocoapods.org/pods/Strongbox)

Strongbox is a Swift utility class for storing data securely in the keychain. Use it to store small, sensitive bits of data securely.

Strongbox is based on [Lockbox v3](http://cocoapods.org/pods/Lockbox), an equivalent Objective-C implementation.

## Overview

There are some bits of data that an app sometimes needs to store that are sensitive:

+ Usernames
+ Passwords
+ In-App Purchase unlocked feature bits
+ and anything else that, if in the wrong hands, would be B-A-D.

The thing to realize is that data stored in `NSUserDefaults` is stored in the clear! For that matter, most everything stored in your app's sandbox is also there in the clear.

Surprisingly, new and experienced app developers alike often do not realize this, until it's too late.

Strongbox makes it easy to store and retrieve any Foundation-based object that conforms to `NSSecureCoding` into and from the key chain. You are spared having to deal with the keychain APIs directly!

For greater security, and to avoid possible collisions between data stored by your app with data stored by other apps (yours or other developers), the keys you provide in the class methods for storing and retrieving data are prefixed with your app's bundle id. You can override this by calling the alternate `init()` method that accepts a prefix of your choosing.

The one caveat to keep in mind is that the keychain is really not meant to store large chunks of data, so don't try and store a huge array of data with these APIs simply because you want it secure. In this case, consider alternative encryption techniques.

## Methods

Strongbox includes the following methods:

## General object storage and retrieval

+ `archive(_ object: Any?, key: String) -> Bool`
+ `archive(_ object: Any?, key: String, accessibility: CFString) -> Bool`
+ `unarchive(objectForKey: String) -> Any?`
+ `remove(key: String) -> Bool`

These methods use an `NSKeyedArchiver` and `NSKeyedUnarchiver`, respectively, to encode and decode your objects. Your objects must conform to `NSSecureCoding`.

The `archive` methods return `Bool` indicating if the keychain operation succeeded or failed. The `unarchive` method returns an optional which may be unwrapped if the operation succeeded. The returned value is of type `Any?` and you are expected to unwrap it and cast it appropriately to whatever type you know it should be. For example:

```swift
let sb = Strongbox()
sb.archive("String", key: "MyKey") // true
let myString = sb.unarchive(objectForKey: "MyKey") as! String
```

The `remove` method is a convenient and more intuitive mechanism for removing previously stored values.

Slightly less contrived:


```swift
var myArray: Array[String] = ...
let sb = Strongbox()
sb.archive(myArray, key: "MyArrayKey") // true
...
if let savedArray = sb.unarchive(objectForKey: "MyArrayKey") as? Array<String> {
    ...
}

```


The methods with an `accessibility` argument take a [Keychain Item Accessibility
Constant](https://developer.apple.com/reference/security/1658642-keychain_services/1663541-keychain_item_accessibility_cons). You can use this to control when your keychain item should be readable. For
example, passing `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` will make
it accessible only while the device is unlocked, and will not migrate this
item to a new device or installation. The methods without a specific
`accessibility` argument will use `kSecAttrAccessibleWhenUnlocked`, the default in recent iOS versions.

## Requirements & Limitations

To use this class you will need to add the `Security` framework to your project.

Your project will have to have Keychain Sharing enabled for Lockbox to access the keychain, but you can remove any Keychain Groups that Xcode adds. The entititlement is apparently required for any keychain access, not just sharing.

This class was written for use under Cocoa Touch and iOS. The code and tests run fine in the iOS simulator under Mac OS. But there are some issues using this class under Cocoa and Mac OS. There are some keychain API differences between the two platforms, as it happens. Feel free to fork this repo to make it work for both Cocoa and Cocoa Touch and I'll be happy to consider your pull request!

### Note on running unittests on device
If you experience SecItemCopyMatching errors with code -34018 on Strongbox methods while running your app unit tests target on device, your can avoid these by code signing your unit tests .xcttest folder. 

Add Run Script phase to your unit tests target Build Phases with:

`codesign --verify --force --sign "$CODE_SIGN_IDENTITY" "$CODESIGNING_FOLDER_PATH"`


## Installation

Strongbox is available through [CocoaPods](http://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods
To install, simply add the following line to your Podfile:

```ruby
pod "Strongbox"
```

Then, run `pod install` from Terminal.

### Carthage
To install, simply add the following line to your Cartfile:

```ruby
github "granoff/Strongbox"
```

Then, run `carthage update` to build the framework, and follow Carthage's [instructions](https://github.com/Carthage/Carthage#getting-started) for adding to your project.

## Author

Mark H. Granoff, mark@granoff.net

## License

Strongbox is available under the MIT license. See the LICENSE file for more info.
