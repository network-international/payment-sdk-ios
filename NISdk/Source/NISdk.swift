//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation


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
        
        let paymentViewController = PaymentViewController(order: order, and: cardPaymentDelegate)
        parentViewController.present(paymentViewController, animated: false)
    }
    
    public func testController(overParent parentViewController: UIViewController) {
        let paymentViewController = CardPaymentViewController(makePaymentCallback: {_ in })
        parentViewController.present(paymentViewController, animated: false)
    }
}
