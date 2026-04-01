# Network International iOS SDK

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![Banner](assets/banner.jpg)

The NI-payment-sdk-ios allows you to quickly integrate a payment checkout experience in your iOS app.

## Requirements

The Network International iOS payment SDK requires Xcode 13.0 and later and works with iOS versions 13 and above

## Getting Started

### Integration

We support all the popular iOS dependency management tools. The SDK can be added via [Swift package Manager](https://www.swift.org/documentation/package-manager/), [CocoaPods](https://cocoapods.org/) or [Carthage](https://github.com/Carthage/Carthage).

Head over to our [iOS Integration Docs](https://docs.ngenius-payments.com/reference#ios-sdk-integration-guide), which explain in detail the payment-sdk integration flow.

### Examples

There are 2 example apps, one written in swift and the other in Objective-C included in this repository, which can be used as a reference for integrating the sdk into your app.

- [**Simple Integration** - Examples/Simple Integration](/Examples/Simple%20Integration/)
- [**Simple Integration Obj-C** - Examples/Simple Integration Obj-C](/Examples/Simple%20Integration%20Obj-C/)

### Saved Card Payment

The saved card token serves as a secure means to facilitate payments through the SDK. For comprehensive instructions and illustrative code samples, please refer to the detailed guide available [here](https://github.com/network-international/payment-sdk-ios/wiki/Saved-Card-payment).

## SDK Configuration

#### Customizing Colors in Payment SDK

The Payment SDK provides a convenient way for developers to customize the color scheme of the payment page to match their application's design. refer to the detailed guide available [here](https://github.com/network-international/payment-sdk-ios/wiki/Customizing-Colors-in-Payment-SDK-for-iOS)

#### Customize pay button

You can utilize the `shouldShowOrderAmount` property to control the visibility of the amount on the pay button. The default value is set to true.

```swift
NISdk.sharedInstance.shouldShowOrderAmount = false
```

#### Optional Alert dialog

To enhance user experience, you can prompt an alert dialog when users attempt to close the payment page. This feature can be enabled or disabled using the `shouldShowCancelAlert` configuration property.

```kotlin
NISdk.sharedInstance.shouldShowCancelAlert = false
```

#### Customize language

Set the language for the SDK using the setSDKLanguage method. Currently, the SDK supports English and Arabic.

```swift
NISdk.sharedInstance.setSDKLanguage(language: "ar")
```
