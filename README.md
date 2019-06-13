# Payment SDK for iOS

[![Build Status](https://travis-ci.com/network-international/payment-sdk-ios.svg?branch=master)](https://travis-ci.com/network-international/payment-sdk-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![Banner](assets/banner.jpg)

### Specifications
The target iOS version of the SDK is 11.0. It is built using Swift 4.2.

### Localization
iOS SDK supports English and Arabic.

***
### Installation
## [Carthage](http://github.com/Carthage/Carthage)
Simply add the following line to your `Cartfile`:
```ruby
github "network-international/payment-sdk-ios" >= 1.0.2
```
Then add the `PaymentSDK.framework` to your frameworks list in the Xcode project.

Then import it where you use it:

```swift
import PaymentSDK
```

<details>
<summary>In Objective-C</summary>

```objective-c
#import <PaymentSDK/PaymentSDK.h>
```
***
</details>

## Card Integration
Configure the SDK:

```swift
import PaymentSDK
// ...
let sdk = PaymentSDK.Interface.sharedInstance
sdk.configure()
```

<details>
<summary>In Objective-C</summary>

```objective-c
#import <PaymentSDK/PaymentSDK.h>
// ...
Interface *sdk = [Interface sharedInstance];
[_sdk configure];

```
</details>

Once its configure, create a PaymentSDK delegate file which will implement `PaymentDelegate`

```swift
final class PaymentSDKDelegate : PaymentDelegate {
// Implement methods from PaymentDelegate to conform the protocol
}
```

<details>
<summary>In Objective-C</summary>

```objective-c
@interface PaymentSDKDelegate : NSObject <PaymentDelegate>
@end
```
</details>

Once the SDK is configured you can call the card payment method on tap of the Pay button in your app:

```swift
guard let paymentHandler = PaymentSDKHandler.sdk.paymentAuthorizationHandler else
{
return
}
paymentHandler.presentCardView(overParent: parent, withDelegate: paymentDelegate, completion: completion)
```

<details>
<summary>In Objective-C</summary>

```objective-c

PaymentAuthorizationHandler *paymentHandler = handler.sdk.paymentAuthorizationHandler;
if (paymentHandler == nil) { return; }
[paymentHandler presentCardViewWithOverParent:parent withDelegate:delegate completion:completionBlock];

```
</details>

Above:
- `overParent` will be your controller on which the card view will appear
- `withDelegate` should be your delegate instance which was created in previous step
- `completion` completion block.

Above step will call `beginAuthorization` method in the delegate. In this method, app should call `merchant-server` to create the order in gateway and get the `PaymentAuthorization` link & code.

```swift
// Pseudo code to create order
OrderService.create(amount: amount, action: "AUTH"){
(orderCreateResponse) in
if let order = orderCreateResponse {
// Create auth link by URL & code
let authLink = PaymentAuthorizationLink(href: order.paymentAuthorizationUrl, code: order.code)
completion(authLink)
}
}
```
<details>
<summary>In Objective-C</summary>

```objective-c
[OrderService create: amount withAction: @"AUTH" withCompletion:^(OrderResponse * _Nonnull order, NSError * _Nonnull error) {
if (error == nil) {
if (order) {
PaymentAuthorizationLink *authLink = [[PaymentAuthorizationLink alloc]initWithHref:order.paymentAuthorizationUrl code:order.code];
completion(authLink);
}
} else {
NSLog(@"Failed to get authorization link with error : %@", error);
completion(nil);
s}
}];

```
</details>


Now the card payment UI will appear and once the transaction is processing/processed, delegate methods like `authorizationCompleted`, `paymentStarted`, `paymentCompleted` will be called respectively.
***

## Card payment process
This section shows the possible steps that card payment contains.

1. The merchant app requests for payment authorization URL from the merchant server.
2. The merchant server returns the required information.
3. Merchant app passes the payment authorization URL to the SDK.
4. SDK launches the card payment screen.
5. SDK gets the card details (PAN, CVV, expiry date and card holder) from the user, and make a http call to make payment.
6. The payment gateway starts a 3D secure flow if required.
7. The payment result is returned to SDK, and then to the merchant app in order.

![Payment Process](assets/payment_process.png)
