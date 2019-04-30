import UIKit

class CardPreviewFrontView: UIView, CardPreviewProtocol
{
    private var backgroundView  : UIImageView?
    private var PANView         : CardPreviewDigitsView!
    private var dateView        : CardPreviewDigitsView!
    private var cardholderView  : CardPreviewDigitsView!
    
    private var cardImage       : String?
    
    init()
    {
        super.init(frame: K.fixedFrame)
        setupSubviews()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: K.fixedFrame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Subviews -
    
    override func layoutSubviews()
    {
        log("frame:\(self.frame)")
    }
    
    private func setupSubviews()
    {
        log("frame:\(self.frame)")
        addBackgroundImage()
        
        self.PANView = CardPreviewDigitsView(frame: K.panFrame)
        self.dateView = CardPreviewDigitsView(frame: K.dateFrame)
        self.dateView.scale = K.dateSizeScale
        self.cardholderView = CardPreviewDigitsView(frame: K.holderFrame)
        self.cardholderView.scale = K.holderSizeScale
        
        self.addSubview(self.PANView)
        self.addSubview(self.dateView)
        self.addSubview(self.cardholderView)
    }
    
    private func addBackgroundImage()
    {
        let imageName   = "card_bg_front_generic"
        guard let image = UIImage.paymentSDKImageNamed(imageName) else { return }
        let background  = UIImageView(image: image)
        
        self.addSubview(background)
        UIView.constrain(view: background, toParent: self)
        self.backgroundView = background
    }
    
    private func updateBackgroundImage(_ name: String?)
    {
        let imageName = name ?? "card_bg_front_generic"
        guard let image = UIImage.paymentSDKImageNamed(imageName) else { return }
        self.backgroundView?.image = image
    }
    
    // MARK: - CardPreviewProtocol -
    
    func update(for card: CardIdentity?, from fieldKind: FormField.Kind, with string: String)
    {
        switch fieldKind
        {
        case .PAN         : self.handlePANUpdate(for: card, from: fieldKind, with: string)
        case .expiryDate  : log("date \(string)"); self.dateView.update(forText: string)
        case .holderName  : log("holder \(string)"); self.cardholderView.update(forText: string)
        default           : break
        }
    }
    
    func updateCVVLocation(for card: CardIdentity, showing: Bool)
    {
        guard let description = card.description else { return }
        guard description.CVV.location == .front else
        {
            log("do nothing if card back is showing")
            return
        }
        
        if showing
        {
            guard let cardImage = description.CVV.image else { return }
            self.updateBackgroundImage(cardImage)
            return
        }
        guard let cardImage = description.image else { return }
        self.updateBackgroundImage(cardImage)
    }
}

extension CardPreviewFrontView
{
    private func handlePANUpdate(for card: CardIdentity?, from fieldKind: FormField.Kind, with string: String)
    {
        log("pan \(string)")
        
        self.PANView.update(forText: (string != "") ? string : PreviewDefault.PAN)
        
        guard card?.certainty != CardIdentity.MatchCertainty.none  else
        {
            if self.cardImage != nil
            {
                self.updateBackgroundImage(nil)
                self.cardImage = nil
            }
            return
        }
        
        guard let cardImage = card?.description?.image else { return }
        guard self.cardImage != cardImage else { return }
        log("Update front image to \(cardImage)")
        
        self.updateBackgroundImage(cardImage)
        self.cardImage = cardImage
    }
}


extension CardPreviewFrontView
{
    struct K
    {
        static let dateSizeScale : CGFloat = 0.8
        static let holderSizeScale : CGFloat = 0.75
        static let fixedSize = CGSize(width: 345, height: 217)
        static let fixedFrame = CGRect(origin: .zero, size: fixedSize)
        static let padding : CGFloat = 25.0
        static let digitsHeigth = PreviewDigits.K.digitSize.height
        
        static let panFrame = CGRect(x: padding, y: 110,
                                     width: fixedSize.width - (padding * 2), height: digitsHeigth)
        
        static let dateFrame = CGRect(x: 140, y: 148,
                                     width: 65, height: digitsHeigth * dateSizeScale)
        
        static let holderFrame = CGRect(x: padding, y: 184,
                                        width: panFrame.size.width, height: digitsHeigth * holderSizeScale)
    }
}
