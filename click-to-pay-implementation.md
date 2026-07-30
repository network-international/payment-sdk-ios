# Click to Pay — Implementation Guide

## Architecture Overview

Click to Pay uses a **hybrid native + WebView** approach. A native `UIViewController` hosts a `WKWebView` that loads Visa's SRC (Secure Remote Commerce) SDK. Communication between native and web happens via a JavaScript bridge.

```
┌─────────────────────────────────────────────────┐
│  Merchant App                                   │
│  └── NISdk.launchClickToPay()                   │
│       └── ClickToPayViewController (native)     │
│            ├── WKWebView + click_to_pay.html    │
│            │    └── Visa SDK (Vsb)              │
│            ├── ClickToPayApiInteractor (HTTP)   │
│            └── ClickToPayDelegate (callback)    │
└─────────────────────────────────────────────────┘
```

---

## Key Files

| File | Role |
|------|------|
| `NISdk/Source/Domain/ClickToPay/ClickToPayConfig.swift` | Merchant config (DPA ID, card brands, sandbox flag) |
| `NISdk/Source/Domain/ClickToPay/ClickToPayArgs.swift` | Transaction-specific params (amount, currency, tokens) |
| `NISdk/Source/Domain/ClickToPay/ClickToPayResponse.swift` | Response models from Visa SDK and gateway |
| `NISdk/Source/ClickToPayDelegate.swift` | Public delegate protocol for completion callbacks |
| `NISdk/Source/UI Components/Click To Pay/ClickToPayViewController.swift` | Main native view controller — loads WebView, handles bridge messages, submits payment |
| `NISdk/Source/UI Components/Click To Pay/ClickToPayApiInteractor.swift` | HTTP client for submitting payment to gateway |
| `NISdk/Resources/click_to_pay.html` | HTML/JS page loaded in WebView — contains Visa SDK integration and UI screens |
| `NISdk/Source/NISdk.swift` | Public SDK entry point with `launchClickToPay()` |
| `NISdk/Source/UI Components/PaymentViewController.swift` | Integrates Click to Pay into the unified payment page flow |
| `NISdk/Source/UI Components/Unified Payment Page/UnifiedPaymentPageViewController.swift` | Shows Click to Pay as a payment option if available |

---

## User Flow (Step by Step)

```
1. Order created via Transaction Service
         │
2. SDK checks if order has a `payment:visa_click_to_pay` link
         │
3. Click to Pay appears as option on Unified Payment Page
         │
4. User taps Click to Pay
         │
5. App authorizes → gets access-token + payment-token cookie
         │
6. ClickToPayViewController loads click_to_pay.html in WKWebView
         │
7. HTML dynamically loads Visa SDK from CDN
         │
8. User enters email → Vsb.getCards() fetches saved cards
         │
9. (If needed) OTP verification via Vsb.initiateIdentityValidation()
         │
10. User selects card → Vsb.checkout() returns encrypted payment data
         │
11. Native code submits checkout data to gateway PUT endpoint
         │
12. Gateway returns state (AUTHORISED / FAILED / etc.)
         │
13. Delegate called with .success / .failed / .cancelled / .postAuthReview
```

---

## JS Bridge Communication

The native side and WebView talk through a bridge named **`clickToPayBridge`** (via `WKUserContentController`).

### Messages from HTML → Native

| Message | Meaning |
|---------|---------|
| `onSdkInitialized` | Visa SDK is ready |
| `onCardsAvailable` | Saved cards fetched from Visa vault |
| `onIdentityValidationRequired` | OTP needed before proceeding |
| `onOtpSent` | OTP sent to user's phone/email |
| `onIdentityValidated` | OTP verified successfully |
| `onCheckoutSuccess` | Checkout complete — encrypted data ready to submit |
| `onAddCardRequired` | No saved cards found for this email |
| `onError` | Something went wrong |
| `onCanceled` | User cancelled the flow |

### Native → HTML (JS injection)

- `getInitConfigJson()` — passes merchant config (DPA ID, amount, currency, etc.)

---

## API Calls

### 1. Authorization

```
POST {authUrl}
Body: code={authCode}
Response: Sets cookies → access-token, payment-token
```

### 2. Visa SDK (client-side JS in WebView)

```javascript
Vsb.initialize(dpaTransactionOptions)   // Init SDK with merchant config
Vsb.getCards(consumerIdentity)           // Fetch saved cards by email
Vsb.initiateIdentityValidation(channel) // Send OTP
Vsb.checkout(checkoutParams)            // Execute payment → returns encrypted data
```

### 3. Submit Payment to Gateway

```
PUT /api/outlets/{outletId}/orders/{orderId}/payments/{paymentRef}/unified-click-to-pay

Headers:
  Authorization: Bearer {accessToken}
  Cookie: payment-token={paymentToken}
  Content-Type: application/vnd.ni-payment.v2+json

Body:
{
  "checkoutResponse": "{encrypted_visa_data}",
  "srcDigitalCardId": "{optional_card_id}"
}

Response:
{
  "state": "AUTHORISED | PURCHASED | CAPTURED | POST_AUTH_REVIEW | AWAIT_3DS | FAILED",
  "message": "..."
}
```

---

## Domain Models

### ClickToPayConfig

```swift
ClickToPayConfig(
    dpaId: "VISA_DPA_ID",        // Required — assigned by Visa
    dpaClientId: nil,             // Optional — for multi-merchant setups
    cardBrands: ["visa", "mastercard"],
    dpaName: "Merchant Name",
    isSandbox: true               // Switches Visa SDK URL
)
```

### ClickToPayPaymentResult (from gateway)

| State | Meaning |
|-------|---------|
| `.authorised` | Payment authorized |
| `.purchased` | Payment purchased |
| `.captured` | Payment captured |
| `.postAuthReview` | Needs post-auth review |
| `.requires3DS` / `.requires3DSTwo` | 3DS needed (NOT YET SUPPORTED) |
| `.failed(String)` | Payment failed with message |

### ClickToPayStatus (delegate callback)

| Status | Meaning |
|--------|---------|
| `.success` | Payment went through |
| `.failed` | Payment failed |
| `.cancelled` | User cancelled |
| `.postAuthReview` | Post-auth review required |

---

## Entry Points

### Standalone Launch

```swift
NISdk.sharedInstance.launchClickToPay(
    clickToPayDelegate: self,
    overParent: viewController,
    for: orderResponse,
    with: clickToPayConfig
)
```

### From Unified Payment Page

The `UnifiedPaymentPageViewController` checks for Click to Pay availability:

```
order.embeddedData?.getClickToPayLink() != nil → show Click to Pay option
```

When tapped, `PaymentViewController.initiateClickToPayFromUnifiedPage()` is called. It reuses the already-obtained `accessToken` and `paymentToken` to skip re-authorization.

---

## Important Notes

- **3DS from Click to Pay is NOT yet supported** — marked as TODO in the codebase
- **Token reuse** — when launched from the unified page, tokens from the prior auth step are passed through to avoid double authorization
- **Visa SDK URLs**:
  - Sandbox: `https://sandbox.secure.checkout.visa.com/checkout-widget/resources/js/integration/v2/sdk.js`
  - Production: `https://secure.checkout.visa.com/checkout-widget/resources/js/integration/v2/sdk.js`
- **Discovery** — Click to Pay availability is determined by the presence of a `payment:visa_click_to_pay` link in the order's embedded data
