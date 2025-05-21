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
    public var payPageTitleColor = UIColor.black
    public var inputFieldsBackgroundColor = ColorCompatibility.systemBackground
    public var authorizationViewBackgroundColor = UIColor.white
    public var authorizationViewActivityIndicatorColor = UIColor.gray
    public var authorizationViewLabelColor = UIColor.black
    public var threeDSViewBackgroundColor = UIColor.white
    public var threeDSViewLabelColor = UIColor.black
    public var threeDSViewActivityIndicatorColor = UIColor.gray
    public var payButtonDisabledBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    
    public override init() {
        super.init()
    }
}
