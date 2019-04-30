import Foundation

struct KeyboardAnimationUtility
{
    static func keyboardShowingInfo(for keyboardShowingNotification : Notification?) -> KeyboardShowingInfo?
    {
        guard let userInfo   = keyboardShowingNotification?.userInfo else { return nil }
        guard let startFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else { return nil }
        guard let endFrame   = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return nil }
        guard let duration   = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else { return nil }
        guard let curve      = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return nil }
        guard let animationCurve = UIView.AnimationCurve(rawValue: curve.intValue )  else { return nil }
        
        let frame = KeyboardShowingInfo.Frame(start: startFrame,
                                              end  : endFrame)
        let animation = KeyboardShowingInfo.Animation(duration: duration.doubleValue,
                                                      curve   : animationCurve )
        return KeyboardShowingInfo(frame: frame, animation: animation)
    }
}
