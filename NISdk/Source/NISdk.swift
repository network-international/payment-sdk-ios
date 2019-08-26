//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit


@objc public final class NISdk: NSObject {
    @objc public static let sharedInstance = NISdk()
    
    private override init() {
        super.init()
        if let bundle = Bundle(identifier: "ae.network.gateway.sdk") {
            UIFont.RegisterFont(withFilenameString: "OCRA.otf", in: bundle)
        }
    }
    
    public func showCardPaymentViewWith(cardPaymentDelegate: CardPaymentDelegate,
                             overParent parentViewController: UIViewController,
                             for order: OrderResponse) {
        
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: nil, paymentMedium: .Card)
        parentViewController.present(paymentViewController, animated: true)
    }
    
    public func initiateApplePayWith(applePayDelegate: ApplePayDelegate?,
                                     cardPaymentDelegate: CardPaymentDelegate,
                                     overParent parentViewController: UIViewController,
                                     for order: OrderResponse,
                                     with applePayRequest: PKPaymentRequest) {
        
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: applePayDelegate, paymentMedium: .ApplePay)
        paymentViewController.applePayRequest = applePayRequest
        parentViewController.present(paymentViewController, animated: true)
    }    
}
