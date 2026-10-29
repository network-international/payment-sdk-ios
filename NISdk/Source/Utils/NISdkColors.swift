//
//  SDKColors.swift
//  NISdk
//
//  Created by Gautam Chibde on 09/11/23.
//

import Foundation

// @objcMembers so Objective-C callers (the React Native bridge, an Objective-C AppDelegate)
// can set these, not just Swift.
// Defaults follow the system light/dark appearance; a colour set here is used as given.
@objcMembers public class NISdkColors: NSObject {
    public var cardPreviewColor = UIColor(hexString: "#171618")
    public var cardPreviewLabelColor = UIColor.white
    public var payPageBackgroundColor = ColorCompatibility.systemBackground
    public var payPageLabelColor = ColorCompatibility.label
    public var textFieldLabelColor = ColorCompatibility.label
    public var textFieldPlaceholderColor = ColorCompatibility.dynamic(light: .gray, dark: UIColor(hexString: "#98989F"))
    public var payPageDividerColor = ColorCompatibility.dynamic(light: UIColor(hexString: "#dbdbdc"), dark: UIColor(hexString: "#38383A"))
    public var payButtonBackgroundColor = ColorCompatibility.link
    public var payButtonTitleColor = UIColor.white
    public var payButtonTitleColorHighlighted = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6)
    public var payButtonActivityIndicatorColor = UIColor.white
    public var payPageTitleColor = ColorCompatibility.label

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
    /// Pay button background while disabled (form incomplete or payment in progress).
    /// nil keeps the current look: the normal background, faded.
    /// Android: `payment_sdk_pay_button_disabled_background_color`.
    public var payButtonDisabledBackgroundColor: UIColor?
    /// Pay button title while disabled. nil keeps the current look: the normal title, faded.
    /// Android: `payment_sdk_pay_button_disabled_text_color`.
    public var payButtonDisabledTitleColor: UIColor?

    public override init() {
        super.init()
    }

    func titleColorForPayButton(enabled: Bool) -> UIColor {
        enabled ? payButtonTitleColor : (payButtonDisabledTitleColor ?? payButtonTitleColor)
    }

    /// Colours the pay button's background for its state; the title colours are per state.
    /// With no disabled colour set, a disabled button keeps the previous look: the button faded
    /// to `fadedButtonAlpha`, or only its background to `fadedBackgroundAlpha`.
    func applyPayButtonColors(_ button: UIButton, enabled: Bool, fadedButtonAlpha: CGFloat = 1,
                              fadedBackgroundAlpha: CGFloat = 1) {
        let customDisabled = payButtonDisabledBackgroundColor != nil || payButtonDisabledTitleColor != nil
        if enabled || !customDisabled {
            button.backgroundColor = payButtonBackgroundColor.withAlphaComponent(enabled ? 1 : fadedBackgroundAlpha)
            button.alpha = enabled ? 1 : fadedButtonAlpha
        } else {
            button.backgroundColor = payButtonDisabledBackgroundColor ?? payButtonBackgroundColor
            button.alpha = 1
        }
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
