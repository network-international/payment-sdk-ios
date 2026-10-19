//
//  SDKColors.swift
//  NISdk
//
//  Created by Gautam Chibde on 09/11/23.
//

import Foundation

// @objcMembers so Objective-C callers (the React Native bridge, an Objective-C AppDelegate)
// can set these, not just Swift.
@objcMembers public class NISdkColors: NSObject {
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

    // Options matching the Android SDK's colour resources. nil keeps the current look.

    /// Typed text in the input fields. nil uses `textFieldLabelColor`, as before.
    /// Android: `payment_sdk_text_field_text_color`.
    public var textFieldTextColor: UIColor?
    /// Card preview gradient, left to right. Used instead of `cardPreviewColor` when both
    /// start and end are set; center is optional.
    /// Android: `payment_sdk_card_start_color` / `_center_color` / `_end_color`.
    public var cardPreviewStartColor: UIColor?
    public var cardPreviewCenterColor: UIColor?
    public var cardPreviewEndColor: UIColor?
    /// Navigation bar background. Android: `payment_sdk_toolbar_color`.
    public var navigationBarColor: UIColor?
    /// Navigation bar buttons (Cancel). Android: `payment_sdk_toolbar_icon_color`.
    public var navigationBarButtonColor: UIColor?
    /// Full-screen loaders (loading the order, 3-D Secure).
    /// Android: `payment_sdk_progress_loader_color`.
    public var progressLoaderColor: UIColor?

    public override init() {
        super.init()
    }

    var cardPreviewGradient: [UIColor]? {
        guard let start = cardPreviewStartColor, let end = cardPreviewEndColor else { return nil }
        return [start, cardPreviewCenterColor, end].compactMap { $0 }
    }

    /// Applies the navigation bar colours, if set, to the SDK's own navigation controller.
    func applyNavigationBarColors(to navigationBar: UINavigationBar?) {
        guard let navigationBar = navigationBar else { return }
        if let buttonColor = navigationBarButtonColor {
            navigationBar.tintColor = buttonColor
        }
        if let barColor = navigationBarColor {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = barColor
            appearance.titleTextAttributes = [.foregroundColor: payPageTitleColor]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
    }
}
