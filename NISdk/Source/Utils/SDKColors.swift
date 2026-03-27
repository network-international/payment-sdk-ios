//
//  SDKColors.swift
//  NISdk
//
//  Created by Gautam Chibde on 09/11/23.
//

import Foundation

@objc public class NISdkColors: NSObject {
    public var cardPreviewColor = UIColor(hexString: "#171618")
    public var cardPreviewLabelColor = UIColor.white
    public var payPageBackgroundColor = ColorCompatibility.systemBackground
    public var payPageLabelColor = UIColor.black
    public var textFieldLabelColor = UIColor.black
    public var textFieldPlaceholderColor = UIColor.gray
    public var payPageDividerColor = UIColor(hexString: "#dbdbdc")
    public var payButtonBackgroundColor = ColorCompatibility.link
    public var payButtonTitleColor = UIColor.white
    public var payButtonTitleColorHighlighted = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6)
    public var payButtonActivityIndicatorColor = UIColor.white
    public var payButtonDisabledBackgroundColor = UIColor(hexString: "#d1d1d6")
    public var payButtonDisabledTitleColor = UIColor(hexString: "#8e8e93")
    public var payPageTitleColor = UIColor.black
    public var payButtonGoldColor = UIColor(hexString: "#FFD882")
    public var payButtonGoldTextColor = UIColor(hexString: "#5C3F00")
    public var inputFieldBackgroundColor = ColorCompatibility.systemBackground
    public var authorizationViewBackgroundColor = UIColor.white
    public var authorizationViewActivityIndicatorColor = UIColor.gray
    public var authorizationViewLabelColor = UIColor.black
    public var threeDSViewBackgroundColor = UIColor.white
    public var threeDSViewLabelColor = UIColor.black
    public var threeDSViewActivityIndicatorColor = UIColor.gray

    public override init() {
        super.init()
    }
}
