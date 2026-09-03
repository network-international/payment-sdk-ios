# Agent handoff — standalone Apple Pay (iOS)

Branch: `feature/standalone-wallet-launchers`  
Sister branch (Android): `network-international/payment-sdk-android` → `feature/standalone-wallet-launchers`

Apple Pay already had a standalone entry (`NISdk.initiateApplePayWith`). This branch documents enable/disable and reports a missing `applePayLink` as `.InValidRequest`.

Read this file before changing Apple Pay or unified-page wallet rows. Integrator docs: [README.md](../README.md) → Apple Pay.

## What is done

| Item | Status |
|---|---|
| No new public method (keep `initiateApplePayWith`) | Done |
| Missing `applePayLink` on standalone path → `.InValidRequest` (W3) | Done |
| Example comment: `with: nil` hides Apple Pay on the unified page | Done |
| README: enable on UPP, disable by omitting request, standalone, hybrid | Done |

## Enable / disable (do not add a second switch)

- **UPP on:** pass `applePayRequest` + `applePayDelegate` into `showCardPaymentViewWith`
- **UPP off:** `with: nil` and `applePayDelegate: nil`
- **Standalone:** `deviceSupportsApplePay()` then `initiateApplePayWith`
- **Hybrid:** standalone Apple Pay button + omit the request on the unified page

The order must have `payment:apple_pay` (`applePayLink`). Device support alone is not enough.

## Key files

```
NISdk/Source/NISdk.swift                                      # initiateApplePayWith
NISdk/Source/UI Components/PaymentViewController.swift        # W3 InValidRequest
Examples/Simple Integration/Source/StoreFrontViewController.swift
README.md
```

## How to continue

1. Keep Android and iOS enable/disable models aligned (omit config vs pass config).
2. Do not rename `initiateApplePayWith`.
3. Do not add `NISdk` flags like `isApplePayEnabled`.
4. Manual: device with Apple Pay + merchant ID entitlement + order with `applePayLink`.
5. Remaining known issue (out of scope): unimplemented `ApplePayDelegate` methods still answer with empty `paymentSummaryItems` (W4).

Google Pay and Samsung Pay live only on the Android sister branch.
