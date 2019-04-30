import UIKit

class CardPreviewDigitsView: UIView
{
    var scale : CGFloat = 1
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Subviews -
    
    private func setupSubviews()
    {
        self.backgroundColor = .clear
    }
    
    // MARK: - Public -
    
    func update(forText text: String)
    {
        for view in self.subviews
        {
            view.removeFromSuperview()
        }
        
        let updatedViews = type(of: self).views(forText: text, scale: self.scale)
        for (index, view) in updatedViews.enumerated()
        {
            view.center = type(of: self).digitCenter(forIndex: index, scale: self.scale)
            self.addSubview(view)
        }
    }
    
    private class func digitCenter(forIndex index: Int, scale: CGFloat) -> CGPoint
    {
        let y = (PreviewDigits.K.digitSize.height * scale) / 2.0
        let x = (PreviewDigits.K.digitSize.width * scale) / 2.0 + ( CGFloat(index) * (PreviewDigits.K.digitSize.width * scale))
        return CGPoint(x: x, y: y)
    }
    
    private class func views(forText text: String, scale: CGFloat) -> [UIView]
    {
        var digits : [UIView] = []
        
        for char in text
        {
            if let view = PreviewDigits.digitView(forCharacter: String(char), scale: scale) //TODO: use char instead?
            {
                digits.append(view)
            }
        }
        
        return digits
    }
}


struct PreviewDigits
{
    struct K
    {
        static let digitSize    = CGSize(width: 15.4, height: 21)
        static let digitFrame   = CGRect(origin: .zero, size: K.digitSize)
    }
    
    static func digitView(forCharacter char: String, scale: CGFloat) -> UIView?
    {
        guard let image = self.digitImage(forCharacter: char) else { return nil }
        
        let view = UIImageView(image: image)
        view.frame =  scale == 1.0 ? K.digitFrame : CGRect(origin: .zero, size: CGSize(width : K.digitSize.width * scale,
                                                                                       height: K.digitSize.height * scale))
        return view
    }
    
    static func digitImage(forCharacter char: String) -> UIImage?
    {
        guard let validName = self.validCharacterName(forCharacter: char) else { return nil }
        return UIImage.paymentSDKImageNamed(validName)
    }
    
    static func validCharacterName(forCharacter char: String) -> String?
    {
        let decimalDigits = CharacterSet.decimalDigits
        
        if char.unicodeScalars.filter(decimalDigits.contains).count > 0
        {
            return "digit_" + char
        }
        
        let validCharacters = CharacterSet(charactersIn: " .-'/")
        
        if char.unicodeScalars.filter(validCharacters.contains).count > 0
        {
            let prefix = "character_"
            switch char
            {
            case " "  : return prefix + "space"
            case "/"  : return prefix + "slash"
            case "'"  : return prefix + "apostrophe"
            case "."  : return prefix + "period"
            case "-"  : return prefix + "dash"
            default   : return nil
            }
        }
        
        let validLetters =  CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        
        if char.unicodeScalars.filter(validLetters.contains).count > 0
        {
            return "letter_" + char
        }
        
        return nil
    }
}
