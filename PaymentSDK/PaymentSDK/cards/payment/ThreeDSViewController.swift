import UIKit
import WebKit

final class ThreeDSViewController: UIViewController
{
	private var webView: WKWebView!
	private var activityIndicator: UIActivityIndicatorView?
	let request: URLRequest?
	private let delegate: ThreeDSWebViewDelegate

	private let completion: (Bool)->Void

	init(with payload : CardPaymentStatus.Payload3DS,
         orderLink    : PaymentAuthorizationService.OrderLink,
		 completion   : @escaping (Bool)->Void)
	{
		self.completion = completion
		self.request = ThreeDSWebViewRequest.request(from: payload)
		self.delegate = ThreeDSWebViewDelegate(with: orderLink)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { return nil }

	override func viewDidLoad()
	{
		super.viewDidLoad()

		setupSubviews()
		configureDelegate()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		guard let request = request else
		{
			log("Not valid URL")
			return
		}
		webView.load(request)
		showOngoingActivity()
	}

	private func setupSubviews()
	{
		self.view.backgroundColor = .white
		self.webView = type(of: self).addWebView(to: self.view)
		webView.alpha = 0
		webView.navigationDelegate = delegate
	}

	private func configureDelegate()
	{
		delegate.navigationStarted = { [weak self] in self?.showOngoingActivity() }
		delegate.navigationDone = { [weak self] in self?.removeOngoingActivityView() }
		delegate.resultRetrieved = resultRetrievedAction()
	}

	private func resultRetrievedAction() -> (Bool) -> Void
	{
		return { [weak self] success in

			log("❌✅ 3DS result success = \(success) ✅❌")
			self?.removeOngoingActivityView()
			self?.dismiss(animated: true,
						  completion:
			{
				log("DONE DISMISS 3DS")
				self?.completion(success)
			})}
	}

	// MARK: - Show Progress -

	private func showOngoingActivity()
	{
		log("")
		if activityIndicator != nil
		{
			self.activityIndicator?.alpha = 1
			self.activityIndicator?.startAnimating()
			return
		}
		self.activityIndicator = type(of: self).addActivityIndicator(to: self.view)
		self.activityIndicator?.startAnimating()
	}

	private func removeOngoingActivityView()
	{
		log("")
		UIView.animate(withDuration	: 0.4,
					   animations	: { self.webView.alpha = 1; self.activityIndicator?.alpha = 0 },
					   completion	:
		{ _ in
			self.activityIndicator?.stopAnimating()
		})
	}
}


extension ThreeDSViewController
{
	private static func addActivityIndicator(to parent: UIView) -> UIActivityIndicatorView
	{
		let indicator = UIActivityIndicatorView(style: .gray)
		indicator.hidesWhenStopped = true

		parent.addSubview(indicator)
		UIView.centerFixedSizeView(indicator, in: parent)

		return indicator
	}

	private static func addWebView(to parent: UIView) -> WKWebView
	{
		let frame = parent.bounds
		let view = WKWebView(frame: frame)

		parent.addSubview(view)
		UIView.constrain(view:view, toParent: parent)

		return view
	}
}
