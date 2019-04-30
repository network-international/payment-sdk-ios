import UIKit

class CardPreviewBackView: UIView, CardPreviewProtocol
{
    private var backgroundView  : UIImageView?
    
    init()
    {
        super.init(frame: CardPreviewFrontView.K.fixedFrame)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: CardPreviewFrontView.K.fixedFrame)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Subviews -
    
    private func addBackgroundImage(_ name: String)
    {
        guard let image = UIImage.paymentSDKImageNamed(name) else { return }
        let background  = UIImageView(image: image)
        
        self.addSubview(background)
        UIView.constrain(view: background, toParent: self)
        self.backgroundView = background
    }
    
    
    private func updateBackgroundImage(_ name: String?)
    {
        let imageName = name ?? "card_bg_back_generic"
        
        if self.backgroundView == nil
        {
            addBackgroundImage(imageName)
            return
        }
        
        guard let image = UIImage.paymentSDKImageNamed(imageName) else { return }
        self.backgroundView?.image = image
    }
    
    // MARK: - CardPreviewProtocol -
    
    func update(for card: CardIdentity?, from fieldKind: FormField.Kind, with string: String)
    {
        switch fieldKind
        {
        case .PAN         : log("pan \(string)")
        case .expiryDate  : log("date \(string)")
        case .holderName  : log("holder \(string)")
        default           : break
        }
    }
    
    func updateCVVLocation(for card: CardIdentity, showing: Bool)
    {
        guard let description = card.description else { return }
        guard description.CVV.location == .back else
        {
            log("do nothing if card front is showing")
            return
        }
        
        if showing
        {
            guard let cardImage = description.CVV.image else { return }
            self.updateBackgroundImage(cardImage)
            return
        }
    }
}
