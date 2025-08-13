//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import PassKit

private class NISdkBundleLocator {}

@objc public final class NISdk: NSObject {
    @objc public static let sharedInstance = NISdk()
    
    var niSdkColors = NISdkColors()
    var sdkLanguage = "en"
    public var shouldShowOrderAmount = true
    public var shouldShowCancelAlert = false
    
    public var version: String = "6.0.0"
    
    private override init() {
        super.init()
        let bundle = getBundle()
        UIFont.RegisterFont(withFilenameString: "OCRA.otf", in: bundle)
    }
    
    func getBundle() -> Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        if let bundle = Bundle(path: "NISdk.bundle") {
            return bundle
        } else if let path = Bundle(for: NISdkBundleLocator.self).path(forResource: "NISdk", ofType: "bundle"),
                  let bundle = Bundle(path: path)  {
            return bundle
        } else {
            let bundle = Bundle(for: NISdkBundleLocator.self)
            return bundle
        }
#endif
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
            aaniPaymentDelegate.aaniPaymentCompleted(with: .invalidRequest)
        }
    }
    
    @objc public func initiateApplePayWith(applePayDelegate: ApplePayDelegate?,
                                           cardPaymentDelegate: CardPaymentDelegate,
                                           overParent parentViewController: UIViewController,
                                           for order: OrderResponse,
                                           with applePayRequest: PKPaymentRequest) {
        
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
