import UIKit
import SwiftUI

/// Replaces the currency codes `"AED"` and `"SAR"` in a string with the UAE Dirham and
/// Saudi Riyal symbol images (assets `aed` and `riyal` in `CurrencySymbols.xcassets`).
/// All other text is left as-is and rendered with the supplied font/color.
///
/// Use from any `UILabel`/`UIButton` that would otherwise show `"AED 1,234.56"` or
/// `"Pay SAR 1,234.56"`, and from SwiftUI `Text` via `swiftUIText`.
enum CurrencySymbol {

    private static let assets = ["AED": "aed", "SAR": "riyal"]

    static func attributed(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let result = NSMutableAttributedString()
        for segment in segments(of: text) {
            switch segment {
            case .text(let string):
                result.append(NSAttributedString(string: string, attributes: attributes))
            case .symbol(let code, let asset):
                if let image = image(asset) {
                    result.append(attachment(for: image.tinted(with: color), font: font))
                } else {
                    result.append(NSAttributedString(string: code, attributes: attributes))
                }
            }
        }
        return result
    }

    /// Sets the pay button's title for its normal, highlighted and disabled states with the
    /// pay button colours. `disabledText` replaces the title while disabled (for example
    /// "Processing Payment"); by default the disabled title is the same text.
    static func setPayButtonTitle(_ text: String, on button: UIButton, disabledText: String? = nil) {
        let colors = NISdk.sharedInstance.niSdkColors
        let font = button.titleLabel?.font ?? UIFont.systemFont(ofSize: 20, weight: .medium)
        button.setAttributedTitle(attributed(text, font: font, color: colors.payButtonTitleColor), for: .normal)
        button.setAttributedTitle(attributed(text, font: font, color: colors.payButtonTitleColorHighlighted), for: .highlighted)
        button.setAttributedTitle(attributed(disabledText ?? text, font: font,
                                             color: colors.titleColorForPayButton(enabled: false)), for: .disabled)
    }

    /// SwiftUI variant: one `Text` with each currency code replaced by an inline template
    /// image, so the symbol takes the text's foreground colour.
    static func swiftUIText(_ text: String, fontSize: CGFloat) -> Text {
        var combined = Text("")
        for segment in segments(of: text) {
            switch segment {
            case .text(let string):
                combined = combined + Text(string)
            case .symbol(let code, let asset):
                if let image = image(asset)?.resized(toHeight: fontSize * 0.75) {
                    combined = combined + Text(Image(uiImage: image).renderingMode(.template))
                } else {
                    combined = combined + Text(code)
                }
            }
        }
        return combined
    }

    private enum Segment {
        case text(String)
        case symbol(code: String, asset: String)
    }

    private static func segments(of text: String) -> [Segment] {
        var result: [Segment] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            let next = assets.keys
                .compactMap { code in text.range(of: code, range: cursor..<text.endIndex).map { (code, $0) } }
                .min { $0.1.lowerBound < $1.1.lowerBound }
            guard let (code, range) = next else { break }
            if cursor < range.lowerBound {
                result.append(.text(String(text[cursor..<range.lowerBound])))
            }
            result.append(.symbol(code: code, asset: assets[code]!))
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            result.append(.text(String(text[cursor..<text.endIndex])))
        }
        return result
    }

    private static func image(_ asset: String) -> UIImage? {
        UIImage(named: asset, in: NISdk.sharedInstance.getBundle(), compatibleWith: nil)
    }

    private static func attachment(for image: UIImage, font: UIFont) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        // Size against cap-height so the symbol sits on the digits' baseline.
        let height = font.capHeight
        let width = height * image.size.width / max(image.size.height, 1)
        attachment.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        return NSAttributedString(attachment: attachment)
    }
}

private extension UIImage {
    /// The image's shape filled with `color`, so the symbol matches the text around it.
    func tinted(with color: UIColor) -> UIImage {
        withTintColor(color, renderingMode: .alwaysOriginal)
    }

    func resized(toHeight height: CGFloat) -> UIImage {
        let target = CGSize(width: height * size.width / max(size.height, 1), height: height)
        return UIGraphicsImageRenderer(size: target).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
