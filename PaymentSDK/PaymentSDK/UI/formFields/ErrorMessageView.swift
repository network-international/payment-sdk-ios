import UIKit


class ErrorMessageView: UIView
{
    private var label : UILabel!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setupSubview(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var text : String? {
        set { self.label.text = newValue }
        get { return self.label.text }
    }
    
    // MARK: Subviews
    
    private func setupSubview(frame: CGRect)
    {
        self.backgroundColor = .clear
        self.isHidden        = true
        
        self.label = UILabel(frame: CGRect(origin: .zero, size: frame.size))
        self.label.numberOfLines = 0
        self.label.textColor = .white
        self.label.textAlignment = .center
        
        let background = ErrorViewBackground(frame: self.bounds)
        background.isOpaque = false
        self.addSubview(background)
        self.addSubview(self.label)
        self.clipsToBounds = true
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: frame.size.height).isActive = true
        self.widthAnchor.constraint(equalToConstant: frame.size.width).isActive = true
    }
    
    // MARK: - Show/hide -
    
    func update(text: String?)
    {
        guard let updatedText = text else
        {
            log("will hide 🔵")
            let originalFrame = self.frame
            var hiddenframe = originalFrame
            hiddenframe.size.height = 0
            UIView.customErrorHideAnimation(frameHideAimations:
            {
                self.frame = hiddenframe
                self.alpha = 0
                log("Reduced frame.🔵")
            },
                                            hideAimations:
            {
                self.isHidden = true
                if self.isHidden != true // due to bug in iOS had to do this
                {
                    self.isHidden = true
                }
                log("View hidden.🔵")
            })
            {
                (done) in
                self.frame = originalFrame
                self.text = nil
                log("Alpha set to 1. But should be hidden:\(self)🔵")
            }
            return
        }
        
        log("will show 🔴")
        self.text = updatedText
        self.alpha = 1
        UIView.customErrorShowAnimation {
            self.isHidden = false
            log("show view \(self)🔴")
            if self.isHidden
            {
                self.isHidden = false // due to bug in iOS had to do this
                //🌕 📚ErrorMessageView ✳️ update(text:) #️⃣[82]: show view <PaymentSDK.ErrorMessageView: 0x151da98b0; frame = (15 80; 384 50); clipsToBounds = YES; hidden = YES; layer = <CALayer: 0x1c4436280>>🔴
                //🌕 📚ErrorMessageView ✳️ update(text:) #️⃣[86]: show view <PaymentSDK.ErrorMessageView: 0x151da98b0; frame = (15 80; 384 50); clipsToBounds = YES; layer = <CALayer: 0x1c4436280>>🔴
                log("show view \(self)🔴")
            }
        }
    }
}


extension UIView
{
    class func customErrorHideAnimation(frameHideAimations      : @escaping () -> Void,
                                        hideAimations           : @escaping () -> Void,
                                        resetFrameAimations     : @escaping ((Bool) -> Void))
    {
        log("")
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseOut],
                       animations:frameHideAimations,
                       completion:
        { (done) in
            
            log("frame animation done")
            if done == false { log("NOT DONE!") }
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.71,
                           initialSpringVelocity: 0.33,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations:hideAimations,
                           completion:resetFrameAimations)
                        
        })
    }
    
    class func customErrorShowAnimation(animations: @escaping () -> Void)
    {
        log("show error view start")
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.71,
                       initialSpringVelocity: 0.33,
                       options: [.beginFromCurrentState, .curveEaseInOut],
                       animations:animations,
                       completion:nil)
    }
}

class ErrorViewBackground: UIView
{
    override func draw(_ rect: CGRect)
    {
        let cornerRadius : CGFloat = 10
        let cornerPointDelta : CGFloat = 0.448 * cornerRadius
        let size = rect.size
        let context = UIGraphicsGetCurrentContext()!
        
        let rectangle = UIBezierPath()
        rectangle.move(to: CGPoint.zero)
        
        rectangle.addLine(to: CGPoint(x: size.width, y: 0))
        rectangle.addLine(to: CGPoint(x: size.width, y: size.height - cornerRadius))
        
        rectangle.addCurve(to           : CGPoint(x: size.width - cornerRadius, y: size.height),
                           controlPoint1: CGPoint(x: size.width, y: size.height - cornerPointDelta),
                           controlPoint2: CGPoint(x: size.width - cornerPointDelta, y: size.height))
        
        rectangle.addLine(to: CGPoint(x: cornerRadius, y: size.height))
        
        rectangle.addCurve(to           : CGPoint(x: 0, y: size.height - cornerRadius),
                           controlPoint1: CGPoint(x: cornerPointDelta, y: size.height),
                           controlPoint2: CGPoint(x: 0, y: size.height - cornerPointDelta))
        
        rectangle.addLine(to: CGPoint.zero)
        
        rectangle.close()
        
        rectangle.move(to: CGPoint.zero)
        context.saveGState()
        rectangle.usesEvenOddFillRule = true
        UIColor(hue: 1, saturation: 1, brightness: 0.719, alpha: 0.95).setFill()
        rectangle.fill()
        context.restoreGState()
    }
}
