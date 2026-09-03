import UIKit

/// Replaces every occurrence of `"AED"` in the input string with the UAE Dirham
/// symbol image (asset `aed` in `CurrencySymbols.xcassets`). All other text — including
/// any other currency codes — is left as-is and rendered with the supplied font/color.
///
/// Use this from any `UILabel`/`UIButton` that would otherwise show `"AED 1,234.56"`
/// or `"Pay AED 1,234.56"` so the symbol replaces the literal text.
enum AedSymbol {

    private static let token = "AED"

    static func attributed(_ text: String,
                           font: UIFont,
                           color: UIColor,
                           additionalAttributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
        var baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        baseAttributes.merge(additionalAttributes) { _, new in new }

        guard text.range(of: token) != nil,
              let image = symbolImage(tinted: color) else {
            return NSAttributedString(string: text, attributes: baseAttributes)
        }

        let result = NSMutableAttributedString()
        var cursor = text.startIndex
        while let range = text.range(of: token, range: cursor..<text.endIndex) {
            // Text before the match.
            if cursor < range.lowerBound {
                result.append(NSAttributedString(string: String(text[cursor..<range.lowerBound]),
                                                 attributes: baseAttributes))
            }
            result.append(attachment(for: image, font: font))
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            result.append(NSAttributedString(string: String(text[cursor..<text.endIndex]),
                                             attributes: baseAttributes))
        }
        return result
    }

    private static func attachment(for image: UIImage, font: UIFont) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        // Size against cap-height so the symbol sits on the digits' baseline rather than
        // overshooting like an emoji would. Width preserves the source aspect ratio.
        let height = font.capHeight
        let aspect = image.size.width / max(image.size.height, 1)
        let width = height * aspect
        let yOffset = (font.capHeight - height) / 2
        attachment.bounds = CGRect(x: 0, y: yOffset, width: width, height: height)
        return NSAttributedString(attachment: attachment)
    }

    private static func symbolImage(tinted color: UIColor) -> UIImage? {
        let bundle = NISdk.sharedInstance.getBundle()
        guard let base = UIImage(named: "aed", in: bundle, compatibleWith: nil) else { return nil }
        return base.withRenderingMode(.alwaysTemplate).tinted(with: color) ?? base
    }
}

private extension UIImage {
    /// Renders the template image filled with `color`. Used so the inline AED symbol
    /// follows whatever text color its label/button is using.
    func tinted(with color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.clip(to: CGRect(origin: .zero, size: size), mask: cgImage!)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }

    func resized(toHeight height: CGFloat) -> UIImage {
        let aspect = size.width / max(size.height, 1)
        let target = CGSize(width: height * aspect, height: height)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

import SwiftUI

extension AedSymbol {
    /// SwiftUI variant — returns a single `Text` value built by concatenating segments
    /// of the input with an inline `Image` for the AED token. Use from `Text` contexts
    /// in SwiftUI screens (Aani, PaymentResult, etc.).
    @available(iOS 13.0, *)
    static func swiftUIText(_ text: String, fontSize: CGFloat, tint: UIColor? = nil) -> Text {
        let parts = text.components(separatedBy: "AED")
        guard parts.count > 1 else { return Text(text) }
        let bundle = NISdk.sharedInstance.getBundle()
        guard let base = UIImage(named: "aed", in: bundle, compatibleWith: nil) else {
            return Text(text)
        }
        // Resize so the inline image aligns with text capHeight rather than coming in
        // at its native pixel dimensions and overshooting the line height.
        var scaled = base.resized(toHeight: fontSize * 0.8)
        if let tint = tint {
            // SwiftUI's `Text(Image)` ignores `.foregroundColor` on the embedded image, so
            // bake the tint into the bitmap before handing it back.
            scaled = scaled.withRenderingMode(.alwaysTemplate).tinted(with: tint) ?? scaled
        }
        var combined = Text(parts[0])
        for i in 1..<parts.count {
            combined = combined + Text(Image(uiImage: scaled)) + Text(parts[i])
        }
        return combined
    }
}
