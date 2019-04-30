import Foundation

enum Padding
{
    static let form : UIEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
}

enum Size
{
    enum Form
    {
        enum Field
        {
            static let titleHeight : CGFloat = 30
            static let fieldHeight : CGFloat = 50
            static let totalHeight : CGFloat = titleHeight + fieldHeight
            static let cardNumbersPANLabel : CGSize = CGSize(width: 300, height: titleHeight)
            static let cardNumbersDateLabel : CGSize = CGSize(width: 150, height: titleHeight)
            static let cardNumbersCVVLabel : CGSize = CGSize(width: 60, height: titleHeight)
            static let PAN : CGSize = CGSize(width: 210, height: fieldHeight)
            static let expiry : CGSize = CGSize(width: 60, height: fieldHeight)
            static let CVV : CGSize = CGSize(width: 60, height: fieldHeight)
        }
    }
}

enum TextColor
{
    static let formFieldTitle : UIColor = .darkGray
    static let formFieldPlaceholder : UIColor = .gray
    static let formFieldText : UIColor = .black
}

enum FontSize
{
    static let formField : CGFloat = 17.0
}

enum BackgroundColor
{
    static let formField : UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7005565068)
}


struct UIFrameUtitlity
{
    static func frame(forOriginal originalFrame: CGRect, withPadding padding: CGFloat, height: CGFloat) -> CGRect
    {
        let origin = CGPoint(x: originalFrame.origin.x + padding,
                             y: originalFrame.origin.x + padding)
        
        let size = CGSize(width: originalFrame.size.width - (padding * 2),
                          height: height)
        return CGRect(origin: origin, size: size)
    }
}


enum PreviewDefault
{
    static let PAN      = "0000 0000 0000 0000"
    static let endDate  = "MM/YY"
    static let CVV3     = "000"
    static let CVV4     = "0000"
    static let name     = "CARDHOLDER NAME"
}
