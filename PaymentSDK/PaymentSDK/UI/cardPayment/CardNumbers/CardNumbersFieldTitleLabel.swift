import UIKit

class CardNumbersFieldTitleLabel: UILabel
{
    init(frame: CGRect, layoutDirection: UIUserInterfaceLayoutDirection)
    {
        super.init(frame: frame)
        self.setupSubview(layoutDirection: layoutDirection)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setupSubview(layoutDirection: .leftToRight)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Public -
    
    func showTitle(forFieldKind kind: FormField.Kind)
    {
        switch kind
        {
        case .PAN           : self.text = LocalizedString("card_number_label_title", comment: "")
        case .expiryDate    : self.text = LocalizedString("card_exipry_date_label_title", comment: "")
        case .CVV           : self.text = LocalizedString("card_cvv_label_title", comment: "")
        default             : self.text = ""
        }
    }
    
    // MARK: Subviews
    
    private func setupSubview(layoutDirection: UIUserInterfaceLayoutDirection)
    {
        self.backgroundColor = .clear
        self.numberOfLines = 1
        self.textColor = TextColor.formFieldTitle
    }
    
    
}
