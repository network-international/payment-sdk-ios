import UIKit

class OngoingPaymentMessageView: UIView
{
    private var messageIcon         : UIImageView!
    private var activityIndicator   : UIActivityIndicatorView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setupSubview()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    func showFailure()
    {
        self.showStatus(.failure)
    }
    
    func showSuccess()
    {
        self.showStatus(.success)
    }
    
    private func showStatus(_ status: Status)
    {
        self.activityIndicator.stopAnimating()
        self.messageIcon.image = self.image(for: status)
        self.messageIcon.alpha = 1
    }
    
    // MARK: - Subviews -
    
    private func setupSubview()
    {
        log("")
        self.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        self.activityIndicator = type(of: self).activityIndicator()
        self.messageIcon = type(of: self).icon()
        
        self.addSubview(self.messageIcon)
        self.addSubview(self.activityIndicator)
        
        UIView.center(view: self.messageIcon, ofSize: self.messageIcon.frame.size, in: self)
        UIView.centerFixedSizeView(self.activityIndicator, in: self)
        
        self.activityIndicator.startAnimating()
    }
    
    private class func activityIndicator() -> UIActivityIndicatorView
    {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.hidesWhenStopped = true
        return indicator
    }
    
    private class func icon() -> UIImageView
    {
        let frame = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
        let view = UIImageView(frame: frame)
        view.alpha = 0
        return view
    }
}

// MARK: - Success / Failure messages -

extension OngoingPaymentMessageView
{
    private enum Status
    {
        case success
        case failure
    }
    
    private func image(for status: Status) -> UIImage?
    {
        switch status
        {
        case .success  : return UIImage.paymentSDKImageNamed("payment_success")
        case .failure  : return UIImage.paymentSDKImageNamed("payment_failure")
        }
    }
}
