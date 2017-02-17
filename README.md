# SystemWindowController
[![Swift](https://img.shields.io/badge/Swift-3.0.1-orange.svg)]()
[![Version](https://img.shields.io/cocoapods/v/SystemWindowController.svg?style=flat)](http://cocoapods.org/pods/SystemWindowController)
[![License](https://img.shields.io/cocoapods/l/SystemWindowController.svg?style=flat)](http://cocoapods.org/pods/SystemWindowController)
[![Platform](https://img.shields.io/cocoapods/p/SystemWindowController.svg?style=flat)](http://cocoapods.org/pods/SystemWindowController)
[![Build Status](https://travis-ci.org/diejmon/SystemWindowController.svg?branch=master)](https://travis-ci.org/diejmon/SystemWindowController)
[![codebeat badge](https://codebeat.co/badges/8a24a4ed-c8b5-4551-8230-a7db6acde319)](https://codebeat.co/projects/github-com-diejmon-systemwindowcontroller)

## Library Goal
Provide a way to show global view controller with custom window management.

## Example usage:

```swift
private let sysWindowController = SystemWindowController(windowLevel: UIWindowLevelAlert + 1)
let viewController: UIViewController
sysWindowController.showSystemViewController(viewController, atLevel: 0)
```

## Requirements
- CocoaPods 1.2
- Swift 3.0.1

## Installation

SystemWindowController is available through [CocoaPods](http://cocoapods.org). To Install:
* Add SystemWindowController git submodule to the main project
* In your Podfile add the following line:

  ```ruby
  pod 'SystemWindowController', :path => "$PATH"
  ```

  where `$PATH` is relative path to SystemWindowController submodule from Podfile location.

  This way you will be able to change and update the library easily while developing.

## TODO
Read [this](TODO.md) for up to date TODO list.

## Author

Alexander Belyavskiy diejmon@gmail.com

## License

MIT
