//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import os.log
import PassKit

private class NISdkBundleLocator {}

@objc public final class NISdk: NSObject {
    @objc public static let sharedInstance = NISdk()

    var niSdkColors = NISdkColors()
    var sdkLanguage = "en"
    public var shouldShowOrderAmount = true
    public var shouldShowCancelAlert = false

    // Overall wall-clock cap on a single 3DS authentication session. If the flow
    // (fingerprint, authentication calls, ACS challenge render, customer challenge,
    // challenge response) has not completed within this window, the SDK terminates
    // it and delivers a failure callback so the merchant is never left without a
    // result. Generous by default so a slow-but-legitimate OTP entry is not cut off,
    // but well below the server-side 3DS timeout (~10 min). Set to 0 to disable.
    public var threeDSSessionTimeout: TimeInterval = 300.0

    public var version: String = "6.0.0"

    private override init() {
        super.init()
        let bundle = getBundle()
        UIFont.RegisterFont(withFilenameString: "OCRA.otf", in: bundle)
        os_log("[NISdk] SDK initialized — version %{public}@", log: NISdkLogger.sdk, type: .info, version)
    }

    func getBundle() -> Bundle {
        if let bundle = Bundle(path: "NISdk.bundle") {
            return bundle
        } else if let path = Bundle(for: NISdkBundleLocator.self).path(forResource: "NISdk", ofType: "bundle"),
                  let bundle = Bundle(path: path)  {
            return bundle
        } else {
            let bundle = Bundle(for: NISdkBundleLocator.self)
            return bundle
        }
    }

    func getBundleFor(language: String) -> Bundle {
        let sdkResourceBundle = getBundle()
        if let languageFilePath = sdkResourceBundle.path(forResource: language, ofType: "lproj") {
            if let languageFile = Bundle(path: languageFilePath) {
                return languageFile
            }
        }
        return sdkResourceBundle
    }

    @objc public func deviceSupportsApplePay() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments()
    }

    @objc public func setSDKLanguage(language: String) {
        sdkLanguage = language
        let direction = Locale.characterDirection(forLanguage: language)
        if (direction == .rightToLeft) {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
    }

    @objc public func setSDKColors(sdkColors: NISdkColors) {
        self.niSdkColors = sdkColors
    }

    @objc public func showCardPaymentViewWith(cardPaymentDelegate: CardPaymentDelegate,
                                              overParent parentViewController: UIViewController,
                                              for order: OrderResponse) {
        os_log("[NISdk] showCardPaymentView — orderRef: %{public}@", log: NISdkLogger.sdk, type: .info, order.reference ?? "unknown")
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: nil, paymentMedium: .Card)
        let navController = UINavigationController(rootViewController: paymentViewController)

        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        DispatchQueue.main.async {
            parentViewController.present(navController, animated: true)
        }
    }

    @objc public func launchSavedCardPayment(cardPaymentDelegate: CardPaymentDelegate,
                                             overParent parentViewController: UIViewController,
                                             for order: OrderResponse,
                                             with cvv: String?) {
        os_log("[NISdk] launchSavedCardPayment (with cvv) — orderRef: %{public}@", log: NISdkLogger.sdk, type: .info, order.reference ?? "unknown")
        let paymentViewController = PaymentViewController(order: order,
                                                          cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: nil,
                                                          paymentMedium: .SavedCard,
                                                          cvv: cvv)
        let navController = UINavigationController(rootViewController: paymentViewController)

        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        DispatchQueue.main.async {
            parentViewController.present(navController, animated: true)
        }
    }

    @objc public func launchSavedCardPayment(cardPaymentDelegate: CardPaymentDelegate,
                                             overParent parentViewController: UIViewController,
                                             for order: OrderResponse) {
        os_log("[NISdk] launchSavedCardPayment — orderRef: %{public}@", log: NISdkLogger.sdk, type: .info, order.reference ?? "unknown")
        let paymentViewController = PaymentViewController(order: order,
                                                          cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: nil,
                                                          paymentMedium: .SavedCard,
                                                          cvv: nil)
        let navController = UINavigationController(rootViewController: paymentViewController)

        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        DispatchQueue.main.async {
            parentViewController.present(navController, animated: true)
        }
    }

    public func launchAaniPay(aaniPaymentDelegate: AaniPaymentDelegate,
                              overParent parentViewController: UIViewController,
                              orderResponse: OrderResponse,
                              backLink: String) {
        os_log("[NISdk] launchAaniPay — orderRef: %{public}@", log: NISdkLogger.sdk, type: .info, orderResponse.reference ?? "unknown")
        do {
            let aaniPayArgs = try orderResponse.toAaniPayArgs(backLink)
            let paymentViewController = AaniPayViewController(aaniPayArgs: aaniPayArgs) { status in
                aaniPaymentDelegate.aaniPaymentCompleted(with: status)
            }
            let navController = UINavigationController(rootViewController: paymentViewController)

            paymentViewController.view.backgroundColor = .clear
            paymentViewController.modalPresentationStyle = .overCurrentContext
            if #available(iOS 13.0, *) {
                paymentViewController.isModalInPresentation = true
            }
            DispatchQueue.main.async {
                parentViewController.present(navController, animated: true)
            }
        } catch let e {
            os_log("[NISdk] launchAaniPay — invalid order response: %{public}@", log: NISdkLogger.sdk, type: .error, e.localizedDescription)
            aaniPaymentDelegate.aaniPaymentCompleted(with: .invalidRequest)
        }
    }

    @objc public func initiateApplePayWith(applePayDelegate: ApplePayDelegate?,
                                           cardPaymentDelegate: CardPaymentDelegate,
                                           overParent parentViewController: UIViewController,
                                           for order: OrderResponse,
                                           with applePayRequest: PKPaymentRequest) {
        os_log("[NISdk] initiateApplePay — orderRef: %{public}@", log: NISdkLogger.sdk, type: .info, order.reference ?? "unknown")
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: applePayDelegate, paymentMedium: .ApplePay)
        paymentViewController.applePayRequest = applePayRequest
        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        parentViewController.present(paymentViewController, animated: true)
    }

    @objc public func executeThreeDSTwo(cardPaymentDelegate: CardPaymentDelegate,
                                        overParent parentViewController: UIViewController,
                                        for paymentResponse: PaymentResponse) {
        os_log("[NISdk] executeThreeDSTwo — orderRef: %{public}@, state: %{public}@",
               log: NISdkLogger.sdk, type: .info, paymentResponse.orderReference ?? "unknown", paymentResponse.state)
        let paymentViewController = PaymentViewController(paymentResponse: paymentResponse, cardPaymentDelegate: cardPaymentDelegate)
        let navController = UINavigationController(rootViewController: paymentViewController)
        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        DispatchQueue.main.async {
            parentViewController.present(navController, animated: true)
        }
    }
}
