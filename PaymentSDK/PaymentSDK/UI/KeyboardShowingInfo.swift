import Foundation

struct KeyboardShowingInfo
{
    let frame     : Frame
    let animation : Animation
    
    struct Animation
    {
        let duration : TimeInterval
        let curve    : UIView.AnimationCurve
    }
    
    struct Frame
    {
        let start : CGRect
        let end   : CGRect
    }
}
