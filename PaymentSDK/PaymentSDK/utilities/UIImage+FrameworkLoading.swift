import UIKit

fileprivate let localBundle = Bundle(for: Interface.self)

extension UIImage
{
    class func paymentSDKImageNamed(_ name: String) -> UIImage?
    {
        return UIImage.init(named: name, in: localBundle, compatibleWith: nil)
    }
}
