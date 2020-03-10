//
//  NISdkTests.swift
//  NISdkTests
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Quick
import Nimble
@testable import NISdk

class TestCardPaymentDelegate: CardPaymentDelegate {
    func paymentDidComplete(with status: PaymentStatus) {
        print("Payment did complete called")
    }
    
    
}

class NISdkTests: QuickSpec {
    override func spec() {
        describe("SDK Tests") {
            let vc = UIViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.makeKeyAndVisible()
            window.rootViewController = vc
            beforeEach {
                let orderResponse = OrderResponse.Builder()
                    .withId(_id: "aabc")
                    .withAction(action: "sale")
                    .build()
                let cardPaymentDelegate = TestCardPaymentDelegate()
                NISdk.sharedInstance.showCardPaymentViewWith(cardPaymentDelegate: cardPaymentDelegate,
                                                             overParent: vc,
                                                             for: orderResponse)
                let _ = vc.view
            }
            
            it("Should load and show the authorization label") {
                // Navigation controller is the presentedViewController
                let paymentViewController: PaymentViewController = (
                    (vc.presentedViewController as! UINavigationController)
                        .visibleViewController as! PaymentViewController);
                let authorizationViewController = paymentViewController.children[0] as! AuthorizationViewController
                expect(authorizationViewController.authorizationLabel.text).to(equal("Authenticating Payment"))
            }
            
        }
    }
}
