import UIKit


final class PaymentAuthorizationContentVC : UIViewController
{
    private var closeAction      : VoidBlock?
    private var startCloseAction : VoidBlock?
    private let manager          : CardDataCollectionManager!
    private var keyboardHandler  : ScrollViewKeyboardHandler!
    
    private var scrollView          : UIScrollView!
    private var topBar              : UIVisualEffectView!
    private var cardForm            : CardDetailsView!
    private var ongoingPaymentView  : OngoingPaymentMessageView?

	private var presented3DSView    : Bool = false // used to avoid making fields first responder after 3DS view dismissed
    
    init(withDataCollectionManager manager  : CardDataCollectionManager,
         startDismissingAction              : @escaping VoidBlock,
         closeAction                        : @escaping VoidBlock)
    {
        self.startCloseAction = startDismissingAction
        self.closeAction      = closeAction
        self.manager          = manager
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle   = .coverVertical
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.manager = CardDataCollectionManager()
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad()
    {
        super.viewDidLoad()
        let layoutDirection = type(of: self).layoutDirection(forView: self.view)
        if layoutDirection == .rightToLeft { log("right to left") }
        self.setupSubviews(layoutDirection: layoutDirection,
                           manager: self.manager)
        self.addRemoveActions()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

		if presented3DSView {
			self.presented3DSView = false
			return
		}
        _ = self.cardForm.becomeFirstResponder()
    }
    
    private class func layoutDirection(forView view: UIView) -> UIUserInterfaceLayoutDirection
    {
        return UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute)
    }
    
    // MARK: - Remove Actions -
    
    private func addRemoveActions()
    {
        self.manager.paymentSuccessAction = {
            DispatchQueue.main.async
            {
                self.ongoingPaymentView?.showSuccess()
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0)
            {
                self.closeButtonAction(sender:nil)
            }
        }
        self.manager.failedPaymentAction = {
            DispatchQueue.main.async
            {
                self.ongoingPaymentView?.showFailure()
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0)
            {
                self.closeButtonAction(sender:nil)
            }
        }

		self.manager.cardVerificationAction = { [weak self] payload3DS, completion in
            guard let orderLink = self?.manager.orderLink else { return }
			let view = ThreeDSViewController(with: payload3DS, orderLink: orderLink, completion: completion)
			DispatchQueue.main.async
			{
				self?.present(view, animated: true, completion: { self?.presented3DSView = true})
			}
		}
    }
    
    // MARK: - Subviews -
    
    private func setupSubviews(layoutDirection  : UIUserInterfaceLayoutDirection,
                               manager : CardDataCollectionManager)
    {
        self.view.backgroundColor = .clear
        
        let blurView = self.blurView()
        self.view.addSubview(blurView)
        
        self.scrollView = addContentScrollView()
        self.keyboardHandler = ScrollViewKeyboardHandler(with: self.scrollView)
        
        self.cardForm = self.addCardDetailsView(inScrollView     : self.scrollView,
                                                layoutDirection  : layoutDirection,
                                                manager          : manager)
        manager.cardDataForm = cardForm

        let topBar = self.blurView()
        self.view.addSubview(topBar)
        self.addLine(to: topBar)
        
        self.addConstraints(forTopBar: topBar, parent: self.view)
        
        let closeButton = self.closeButton()
        self.view.addSubview(closeButton)
        
        UIView.constrain(view: blurView, toParent: self.view, padding: K.backgroundPadding)
        self.addConstraints(forCloseButton: closeButton, parent: self.view)
    }
    
    // MARK: - ScrollView -
    
    private func addContentScrollView() -> UIScrollView
    {
        let scrollView = self.scrollView(withFrame:self.view.bounds)
        self.view.addSubview(scrollView)
        UIView.constrain(view: scrollView, toParent: self.view, padding: K.backgroundPadding)
        return scrollView
    }
    
    private func scrollView(withFrame frame: CGRect) -> UIScrollView
    {
        let view = UIScrollView(frame: frame)
        view.contentInset = K.scrollViewInsets
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = true // contentInset does not work without this
        return view
    }
    
    // MARK: - Background -
    
    private func blurView() -> UIVisualEffectView
    {
        let effect   = UIBlurEffect(style: .extraLight)
        let blurView = UIVisualEffectView(effect: effect)
        return blurView
    }
    
    // MARK: - Line -
    
    private func addLine(to view: UIVisualEffectView)
    {
        let line = UIView(frame: view.frame)
        line.backgroundColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2170911815)
        view.contentView.addSubview(line)
        let padding = UIEdgeInsets(top: K.topBarHeigth - K.topBarBottomLineThickness, left: 0, bottom: 0, right: 0)
        UIView.constrain(view: line, toParent: view, padding: padding)
    }
    
    // MARK: - Close -
    
    private func closeButton() -> UIButton
    {
        let button = UIButton(type: .roundedRect)
        button.setTitle(LocalizedString("cancel_button", comment: "Button used to cancel the payment process and close(dismiss) the payment view."),
                        for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        return button
    }
    
    @objc private func closeButtonAction(sender: UIButton?)
    {
        self.startCloseAction?()
        self.dismiss(animated: true, completion: self.closeAction)
    }
    
    // MARK: - Card Details form -
    
    private func addCardDetailsView(inScrollView scrollView: UIScrollView,
                                    layoutDirection        : UIUserInterfaceLayoutDirection,
                                    manager                : CardDataCollectionManager) -> CardDetailsView
    {
        let view = CardDetailsView(frame            : scrollView.bounds,
                                   layoutDirection  : layoutDirection,
                                   manager          : manager,
                                   payAction        : self.payAction())
        scrollView.addSubview(view)
        UIView.constrain(stackView: view, toScrollView: scrollView)
        return view
    }
    
    // MARK: - Payment Action -
    
    private func payAction() -> VoidBlock
    {
        return { log("PAY action")
            
            guard case .valid = self.manager.valid(inContext: .final) else
            {
                // show invalid form message to user or other feedback
                log("🛑 Form not valid! ABORT!")
                self.cardForm.showValidity(inContext: .final)
                return
            }
            
            self.showOngoingPayment()
            // make payment attempt
            log("💳💰 Make Payment!")
            self.view.endEditing(true)
            
            self.manager.attemptPayment()
            // react on failure and success
            // disable UI while dismissing
        }
    }
}

// MARK: - Ongoing payment -

private extension PaymentAuthorizationContentVC
{
    private func showOngoingPayment()
    {
        let view = OngoingPaymentMessageView(frame: self.view.bounds)
        self.view.addSubview(view)
        UIView.constrain(view: view, toParent: self.view)
        self.ongoingPaymentView = view
    }
}

// MARK: - Layout -

private extension PaymentAuthorizationContentVC
{
    private struct K
    {
        static let topBarBottomLineThickness : CGFloat = 0.5
        static let backgroundPadding = UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0)
        static let closeButtonPadding = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: -15)
        static let topBarHeigth : CGFloat = 44
        static let scrollViewInsets = UIEdgeInsets(top: topBarHeigth + 15, left: 0, bottom: 15, right: 0)
    }
    
    private func addConstraints(forCloseButton button: UIButton, parent: UIView)
    {
        let padding = K.closeButtonPadding
        button.translatesAutoresizingMaskIntoConstraints = false
        button.topAnchor.constraint(equalTo: parent.topAnchor, constant: padding.top).isActive = true
        button.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: padding.right).isActive = true
    }
    
    private func addConstraints(forTopBar bar: UIView, parent: UIView)
    {
        let padding = K.backgroundPadding
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.topAnchor.constraint(equalTo: parent.topAnchor, constant: padding.top).isActive = true
        bar.widthAnchor.constraint(equalTo: parent.widthAnchor).isActive = true
        bar.heightAnchor.constraint(equalToConstant: K.topBarHeigth).isActive = true
    }
}
