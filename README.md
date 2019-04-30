# Payment SDK for iOS

![Banner](assets/banner.jpg)

### Specifications
The target iOS version of the SDK is 11.0. It is built using Swift 2.0.

### Localization
iOS SDK supports English and Arabic.

***

## Payment API reference
SDK provides `PaymentSDKHandler` for making payments. To get the handler you need to configure your app with the SDK.

```swift
PaymentSDK.Interface.sharedInstance.configure{
	(result) in
	PaymentSDKHandler.sharedInstance.configResult = result
}
```

Once the SDK is configured you can use the PaymentSDKHandler to launch card payment view.

### Card payment API
SDK provides a very simple API to be able to get payment using debit or credit cards.

```swift
PaymentSDKHandler.sdk.paymentAuthorizationHandler
	.presentView(parentViewController, configuration, items, completion)
```

The card payment API internally launches another view to get card details from the user, and control payment/3D Secure flows between the payment gateway and the merchant app.

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
