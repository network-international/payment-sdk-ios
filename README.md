# Payment SDK for iOS

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/NISdk.svg)](https://cocoapods.org/pods/NISdk)

![Banner](assets/banner.jpg)

The Payment SDK for iOS provides a pre-built checkout experience for accepting payments in your iOS app. It supports card payments, Apple Pay, Click to Pay, saved cards, Aani Pay, and Visa Installments — all with 3D Secure support.

## Requirements

| Requirement | Version |
|-------------|---------|
| **iOS** | 14.0+ |
| **Xcode** | 13.0+ |
| **Swift** | 4.2+ |

#### Supported Languages

English and Arabic.

---

## Installation

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'NISdk'
```

Then run:

```bash
pod install
```

### Carthage

Add to your `Cartfile`:

```
github "network-international/payment-sdk-ios"
```

Then run:

```bash
carthage update --use-xcframeworks
```

---

## Quick Start — Card Payment

### 1. Import the SDK

```swift
import NISdk
```

### 2. Configure the SDK (optional)

```swift
NISdk.sharedInstance.shouldShowOrderAmount = true
NISdk.sharedInstance.shouldShowCancelAlert = true
```

### 3. Launch Payment

Present the card payment view controller from your view controller:

```swift
NISdk.sharedInstance.showCardPaymentViewWith(
    cardPaymentDelegate: self,
    overParent: self,
    for: orderResponse
)
```

### 4. Handle the Result

Implement `CardPaymentDelegate`:

```swift
extension CheckoutViewController: CardPaymentDelegate {
    func paymentDidComplete(with status: PaymentStatus) {
        switch status {
        case .PaymentSuccess:
            // Payment successful
        case .PaymentFailed:
            // Payment failed
        case .PaymentCancelled:
            // User cancelled
        case .PaymentPostAuthReview:
            // Pending fraud review
        case .PartiallyAuthorised:
            // Partial authorization accepted
        case .PartialAuthDeclined:
            // Partial authorization declined by user
        case .InValidRequest:
            // Invalid request
        default:
            break
        }
    }

    // Optional delegates
    func authorizationWillBegin() { }
    func authorizationDidBegin() { }
    func authorizationDidComplete(with status: AuthorizationStatus) { }
    func paymentDidBegin() { }
    func threeDSChallengeDidBegin() { }
    func threeDSChallengeDidComplete(with status: ThreeDSStatus) { }
}
```

---

## Card Payment with All Options

Launch the card payment with Apple Pay, Click to Pay, and Aani support in a single call:

```swift
NISdk.sharedInstance.showCardPaymentViewWith(
    cardPaymentDelegate: self,
    applePayDelegate: self,           // optional
    overParent: self,
    for: orderResponse,
    with: applePayRequest,            // optional PKPaymentRequest
    clickToPayConfig: clickToPayConfig, // optional
    aaniBackLink: "yourapp://aani"    // optional
)
```

---

## Apple Pay

### 1. Check Device Support

```swift
if NISdk.sharedInstance.deviceSupportsApplePay() {
    // Show Apple Pay option
}
```

### 2. Launch Apple Pay Directly

```swift
NISdk.sharedInstance.initiateApplePayWith(
    applePayDelegate: self,
    cardPaymentDelegate: self,
    overParent: self,
    for: orderResponse,
    with: paymentRequest
)
```

### 3. Handle Apple Pay Delegate

```swift
extension CheckoutViewController: ApplePayDelegate {
    func didSelectPaymentMethod(paymentMethod: PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate {
        return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: items)
    }

    func didSelectShippingMethod(shippingMethod: PKShippingMethod) -> PKPaymentRequestShippingMethodUpdate {
        return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: items)
    }

    func didSelectShippingContact(shippingContact: PKContact) -> PKPaymentRequestShippingContactUpdate {
        return PKPaymentRequestShippingContactUpdate(paymentSummaryItems: items)
    }
}
```

---

## Saved Card Payment

Process payments with previously tokenized cards:

```swift
// With optional CVV
NISdk.sharedInstance.launchSavedCardPayment(
    cardPaymentDelegate: self,
    overParent: self,
    for: orderResponse,
    with: "123"  // CVV, or nil to skip
)

// Without CVV
NISdk.sharedInstance.launchSavedCardPayment(
    cardPaymentDelegate: self,
    overParent: self,
    for: orderResponse
)
```

The result is returned through the same `CardPaymentDelegate`.

For more details, see the [Saved Card Payment Guide](https://github.com/network-international/payment-sdk-ios/wiki/Saved-Card-payment).

---

## Click to Pay

Click to Pay (Visa SRC / Mastercard) lets returning consumers pay with saved cards without re-entering card details.

### 1. Configure

```swift
let clickToPayConfig = ClickToPayConfig(
    dpaId: "your-dpa-id",
    dpaClientId: "your-client-id",    // optional
    cardBrands: ["visa", "mastercard"],
    dpaName: "Your Merchant Name",
    isSandbox: true                    // false for production
)
```

### 2. Launch (integrated)

Pass the config when showing the card payment view:

```swift
NISdk.sharedInstance.showCardPaymentViewWith(
    cardPaymentDelegate: self,
    applePayDelegate: nil,
    overParent: self,
    for: orderResponse,
    with: nil,
    clickToPayConfig: clickToPayConfig
)
```

### 3. Launch (standalone)

```swift
NISdk.sharedInstance.launchClickToPay(
    clickToPayDelegate: self,
    overParent: self,
    for: orderResponse,
    with: clickToPayConfig
)
```

### 4. Handle Result

```swift
extension CheckoutViewController: ClickToPayDelegate {
    func clickToPayDidComplete(with status: ClickToPayStatus) {
        switch status {
        case .success:
            // Payment successful
        case .failed:
            // Payment failed
        case .cancelled:
            // User cancelled
        case .postAuthReview:
            // Pending review
        }
    }
}
```

---

## Aani Pay

Aani Pay is a payment method available in Saudi Arabia.

```swift
NISdk.sharedInstance.launchAaniPay(
    aaniPaymentDelegate: self,
    overParent: self,
    orderResponse: orderResponse,
    backLink: "yourapp://aani"
)
```

Handle the result:

```swift
extension CheckoutViewController: AaniPaymentDelegate {
    func aaniPaymentCompleted(with status: AaniPaymentStatus) {
        switch status {
        case .success:
            // Payment successful
        case .failed:
            // Payment failed
        case .cancelled:
            // User cancelled
        case .invalidRequest:
            // Invalid request
        }
    }
}
```

---

## 3D Secure

3D Secure (both 1.0 and 2.0) is handled automatically within the card payment flow. For manual 3DS Two execution:

```swift
NISdk.sharedInstance.executeThreeDSTwo(
    cardPaymentDelegate: self,
    overParent: self,
    for: paymentResponse
)
```

---

## SDK Configuration

### Show/Hide Order Amount

Control whether the amount is displayed on the pay button (default: `true`):

```swift
NISdk.sharedInstance.shouldShowOrderAmount = false
```

### Cancel Alert Dialog

Prompt an alert when users try to close the payment page:

```swift
NISdk.sharedInstance.shouldShowCancelAlert = true
```

### Merchant Logo

Display your logo at the top of the payment screen:

```swift
NISdk.sharedInstance.merchantLogo = UIImage(named: "your_logo")
```

### Language

Set the SDK language (English or Arabic):

```swift
NISdk.sharedInstance.setSDKLanguage(language: "ar")
```

---

## Customizing Colors

Use `NISdkColors` to customize the SDK's color scheme:

```swift
let colors = NISdkColors()

// Pay button
colors.payButtonBackgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0)
colors.payButtonTitleColor = .white

// Disabled button
colors.payButtonDisabledBackgroundColor = UIColor(hexString: "#BDBDBD")
colors.payButtonDisabledTitleColor = UIColor(hexString: "#757575")

// Apply
NISdk.sharedInstance.setSDKColors(sdkColors: colors)
```

### Available Color Properties

| Property | Default | Description |
|----------|---------|-------------|
| `payButtonBackgroundColor` | System link color | Pay button background |
| `payButtonTitleColor` | White | Pay button text |
| `payButtonTitleColorHighlighted` | White (60% opacity) | Pay button text when highlighted |
| `payButtonActivityIndicatorColor` | White | Loading spinner on pay button |
| `payButtonDisabledBackgroundColor` | `#D1D1D6` | Disabled button background |
| `payButtonDisabledTitleColor` | `#8E8E93` | Disabled button text |
| `payPageBackgroundColor` | System background | Payment page background |
| `payPageLabelColor` | Black | Label text |
| `payPageTitleColor` | Black | Title text |
| `payPageDividerColor` | `#DBDBDC` | Divider lines |
| `textFieldLabelColor` | Black | Text field labels |
| `textFieldPlaceholderColor` | Gray | Text field placeholders |
| `cardPreviewColor` | `#171618` | Card preview background |
| `cardPreviewLabelColor` | White | Card preview text |

Color customization applies to all SDK screens including card payment, saved card, Click to Pay WebView buttons, and Aani Pay.

---

## Examples

Two example apps are included in this repository:

- [**Simple Integration (Swift)**](/Examples/Simple%20Integration/) — Full-featured demo with environment management, SDK color configuration, and all payment methods.
- [**Simple Integration (Objective-C)**](/Examples/Simple%20Integration%20Obj-C/) — Basic Objective-C integration example.

---

## Support

For integration support, contact: **ecom-reintegration@network.global**
