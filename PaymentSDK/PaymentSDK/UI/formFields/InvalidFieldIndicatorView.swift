import UIKit

class InvalidFieldIndicatorView: UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup()
    {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1
    }
    
    class func updateValidityIndicator(_ indicatorView : InvalidFieldIndicatorView,
                                       for updatedTextFrame: CGRect)
    {
        var frame = updatedTextFrame
        // wrap around text
        let padding : CGFloat = 7
        frame.origin.x      += -padding
        frame.origin.y      += -padding
        frame.size.width    += padding * 2
        frame.size.height   += padding * 2
        indicatorView.frame = frame
    }
}
