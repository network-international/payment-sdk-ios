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
    
    private override init() { super.init() }
    
    public func showCardPaymentView(withDelegate: NICardPaymentDelegate,
                             overParent parentViewController: UIViewController,
                             for order: NIOrder) {
        let cardPaymentViewController = NICardPaymentViewController()
        parentViewController.present(cardPaymentViewController, animated: false)
    }
}
