import UIKit


final class PaymentAuthorizationViewController : UIViewController
{
    private(set) var completion : VoidBlock?
    private var background : UIView?
    private var activityIndicator: UIActivityIndicatorView?
    
    // MARK: - Rotation -
    
    override var shouldAutorotate: Bool { get { return false } }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { get { return .portrait } }
    
    // MARK: - Init -
    
    init(withShowCompletion completion: VoidBlock?)
    {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle   = .coverVertical
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View loading -
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupSubviews()
    }
    
    override public func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
//        self.animateBackground()
    }
    
    // MARK: - Content loading/animation -
    
    func animateContent(withDataCollectionManager manager  : CardDataCollectionManager)
    {
        setupActivityIndicator()

        manager.createOrderOnInitialisation { [weak self] in
            DispatchQueue.main.async {
                self?.activityIndicator?.stopAnimating()
                self?.animateBackground()

                let content = PaymentAuthorizationContentVC(withDataCollectionManager: manager, startDismissingAction:
                {
                    self?.hideBackground()
                },
                closeAction:
                {
                    self?.dismiss(animated: false, completion: nil)
                })

                self?.present(content, animated: true, completion: self?.completion)
            }
        }
    }
    
    private func setupSubviews()
    {
        self.view.backgroundColor = .clear
        let background = self.backgroundView()
        self.background = background
        self.view.addSubview(background)
        UIView.constrain(view: background, toParent: self.view)
    }
    
    // MARK: - Background animation -
    
    private func backgroundView() -> UIView
    {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.alpha = 0
        return view
    }
    
    private func animateBackground()
    {
        UIView.customAnimation(withDuration: 1.53, animations: { self.background?.alpha = 1 })
    }
    
    private func hideBackground()
    {
        UIView.customAnimation(withDuration: 1.53, animations: { self.background?.alpha = 0 })
    }
    
    private func setupActivityIndicator()
    {
        log("")
        self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator = type(of: self).activityIndicator()
        guard let activityIndicator = self.activityIndicator else { return }
        self.view.addSubview(activityIndicator)
        UIView.centerFixedSizeView(activityIndicator, in: self.view)
        activityIndicator.startAnimating()
    }
    
    private class func activityIndicator() -> UIActivityIndicatorView
    {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        return indicator
    }
}
