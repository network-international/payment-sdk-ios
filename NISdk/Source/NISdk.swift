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
    var sdkLanguage: String
    public var shouldShowOrderAmount = true
    public var shouldShowCancelAlert = false
    public var merchantLogo: UIImage?

    private static let supportedLanguages: Set<String> = ["en", "ar", "fr"]

    public var isLoggingEnabled: Bool {
        get { NILogger.shared.isEnabled }
        set { NILogger.shared.isEnabled = newValue }
    }

    public var version: String = "7.0.0"

    private override init() {
        let deviceLanguage = Locale.current.languageCode ?? "en"
        sdkLanguage = NISdk.supportedLanguages.contains(deviceLanguage) ? deviceLanguage : "en"
        super.init()
        let bundle = getBundle()
        UIFont.RegisterFont(withFilenameString: "OCRA.otf", in: bundle)
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
        showCardPaymentViewWith(cardPaymentDelegate: cardPaymentDelegate,
                                applePayDelegate: nil,
                                overParent: parentViewController,
                                for: order,
                                with: nil,
                                clickToPayConfig: nil)
    }

    public func showCardPaymentViewWith(cardPaymentDelegate: CardPaymentDelegate,
                                        applePayDelegate: ApplePayDelegate?,
                                        overParent parentViewController: UIViewController,
                                        for order: OrderResponse,
                                        with applePayRequest: PKPaymentRequest?,
                                        clickToPayConfig: ClickToPayConfig?,
                                        aaniBackLink: String? = nil,
                                        orderItems: [OrderItem] = [],
                                        savedCards: [SavedCard] = []) {
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: applePayDelegate, paymentMedium: .Card)
        paymentViewController.applePayRequest = applePayRequest
        paymentViewController.clickToPayConfig = clickToPayConfig
        paymentViewController.aaniBackLink = aaniBackLink
        paymentViewController.orderItems = orderItems
        paymentViewController.savedCards = savedCards
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
    
    @available(iOS 14.0, *)
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
    
    public func launchClickToPay(clickToPayDelegate: ClickToPayDelegate,
                                 overParent parentViewController: UIViewController,
                                 for order: OrderResponse,
                                 with config: ClickToPayConfig) {
        // Accept either a resolved dpaId or a merchantId we can use to fetch one mid-launch.
        // ClickToPayViewController resolves the merchant config from the gateway once it has
        // the access token from order authorization.
        if config.dpaId == nil && (config.merchantId?.isEmpty ?? true) {
            print("ClickToPay: ClickToPayConfig has neither dpaId nor merchantId. Set one to launch.")
            clickToPayDelegate.clickToPayDidComplete(with: .failed)
            return
        }
        do {
            let args = try order.toClickToPayArgs()

            let clickToPayVC = ClickToPayViewController(
                clickToPayConfig: config,
                clickToPayArgs: args,
                orderReference: order.reference,
                onCompletion: { status in
                    clickToPayDelegate.clickToPayDidComplete(with: status)
                }
            )
            let navController = UINavigationController(rootViewController: clickToPayVC)

            clickToPayVC.view.backgroundColor = .white
            clickToPayVC.modalPresentationStyle = .overCurrentContext
            if #available(iOS 13.0, *) {
                clickToPayVC.isModalInPresentation = true
            }
            DispatchQueue.main.async {
                parentViewController.present(navController, animated: true)
            }
        } catch {
            clickToPayDelegate.clickToPayDidComplete(with: .failed)
        }
    }

    public func launchQPay(qpayDelegate: QPayPaymentDelegate,
                           overParent parentViewController: UIViewController,
                           orderResponse: OrderResponse) {
        guard let currency = orderResponse.amount?.currencyCode,
              currency.uppercased() == "QAR" else {
            qpayDelegate.qpayPaymentCompleted(with: .invalidRequest)
            return
        }

        let args: QPayInitArgs
        do {
            args = try orderResponse.toQPayInitArgs()
        } catch {
            qpayDelegate.qpayPaymentCompleted(with: .invalidRequest)
            return
        }

        let transactionService = TransactionServiceAdapter()
        transactionService.authorizePayment(for: args.authCode, using: args.authUrl) { tokens in
            guard let token = tokens["access-token"], !token.isEmpty else {
                DispatchQueue.main.async {
                    qpayDelegate.qpayPaymentCompleted(with: .failed)
                }
                return
            }
            DispatchQueue.main.async {
                let qpayVC = QPayViewController(
                    args: args,
                    transactionService: transactionService,
                    accessToken: token
                ) { status in
                    qpayDelegate.qpayPaymentCompleted(with: status)
                }
                let navController = UINavigationController(rootViewController: qpayVC)
                qpayVC.view.backgroundColor = .white
                qpayVC.modalPresentationStyle = .overCurrentContext
                if #available(iOS 13.0, *) {
                    qpayVC.isModalInPresentation = true
                }
                parentViewController.present(navController, animated: true)
            }
        }
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
