//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

private class NISdkBundleLocator {}

@objc public final class NISdk: NSObject {
    @objc public static let sharedInstance = NISdk()
    
    private override init() {
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
    
    @objc public func deviceSupportsApplePay() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments()
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
            navController.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }

        parentViewController.present(navController, animated: true)
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
        parentViewController.present(paymentViewController, animated: true)
    }
}
