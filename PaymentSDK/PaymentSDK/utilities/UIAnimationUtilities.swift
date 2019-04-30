import UIKit

extension UIView
{
    class func customAnimation(withDuration duration: TimeInterval,
                               animations: @escaping () -> Void,
                               completion: ((Bool) -> Void)? = nil)
    {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.51,
                       initialSpringVelocity: 1,
                       options: [.allowUserInteraction, .curveEaseInOut],
                       animations:animations,
                       completion:completion)
    }
    
    class func customLabelAnimation(withDuration duration: TimeInterval,
                                    animations: @escaping () -> Void,
                                    completion: ((Bool) -> Void)? = nil)
    {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.81,
                       initialSpringVelocity: 0.1,
                       options: [.allowUserInteraction, .curveEaseInOut],
                       animations:animations,
                       completion:completion)
    }
}
