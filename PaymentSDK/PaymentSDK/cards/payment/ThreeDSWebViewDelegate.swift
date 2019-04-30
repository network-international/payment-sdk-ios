import Foundation
import WebKit

final class ThreeDSWebViewDelegate: NSObject, WKNavigationDelegate
{
	var navigationStarted : (() -> Void)?
	var navigationDone    : (() -> Void)?
	var resultRetrieved   : ((Bool) -> Void)?
    private var orderLink : PaymentAuthorizationService.OrderLink?
    
    init(with orderLink: PaymentAuthorizationService.OrderLink) {
        super.init()
        self.orderLink = orderLink
    }
}

// MARK: - WKNavigationDelegate Methods -

extension ThreeDSWebViewDelegate {

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
	{
		log("url:\(webView.url?.absoluteString ?? "" )")
		navigationDone?()
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
	{
		log("url:\(webView.url?.absoluteString ?? "" )")
		navigationStarted?()

		guard let result = ThreeDSURLUtility.result(from: webView.url) else { return }
		webView.alpha = 0

		guard result == "SUCCESS" else
		{
			log("!success result = \(result) \n")
			resultRetrieved?(false)
			return
		}

		webView.stopLoading()
		resultRetrieved?(true)
	}
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        log("Done with 3DS flow")
        webView.stopLoading()
        log("Getting 3DS status")
        guard let orderLink = orderLink else { return }
        PaymentAuthorizationService.getOrderDetails(using: orderLink)
        { [weak self] order in
            DispatchQueue.main.async {
                guard let state = order?.embedded.payment.first?.state, state == "FAILED" else {
                    self?.resultRetrieved?(true)
                    return
                }
                log("3DS failed | Payment status is \(state)")
                self?.resultRetrieved?(false)
            }
        }
    }
}
