//
//  UIView+KeyboardDismissal.swift
//  NISdk
//
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

extension UITextField {
    /// Adds a "Done" bar above the keyboard.
    ///
    /// `.numberPad` and `.asciiCapableNumberPad` draw a ten-key pad with no
    /// Return key, so a field using one cannot be dismissed from the keyboard
    /// itself. On the saved-card screen the CVV field is the only field, which
    /// left the pad open over the Pay button with no way out. Every numeric
    /// field in the SDK carries this accessory.
    func addNumericDoneAccessory() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done".localized,
                            style: .done,
                            target: self,
                            action: #selector(niDismissKeyboard)),
        ]
        toolbar.items?.last?.accessibilityIdentifier = "sdk_keyboard_button_done"
        inputAccessoryView = toolbar
    }

    @objc func niDismissKeyboard() {
        resignFirstResponder()
    }
}

extension UIView {
    /// The first responder inside this view's subtree, if any.
    ///
    /// Used to scroll the field the user is typing in back into view once the
    /// keyboard has taken the bottom of the screen.
    var niFirstResponder: UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.niFirstResponder { return found }
        }
        return nil
    }

    /// Installs a tap recogniser that ends editing anywhere in this view.
    ///
    /// `cancelsTouchesInView` stays false so the tap still reaches buttons and
    /// rows underneath — dismissing the keyboard must not swallow the tap that
    /// was meant for the Pay button.
    func addTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(niEndEditing))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }

    @objc func niEndEditing() {
        endEditing(true)
    }
}
