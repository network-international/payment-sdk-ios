//
//  BnplViewController.swift
//  NISdk
//

import Foundation
import UIKit
import WebKit

enum BnplPaymentStatus {
    case success
    case postAuthReview
    /// Carries why, so the merchant can tell a decline from a dropped connection or a
    /// misconfigured order instead of receiving an undifferentiated failure.
    case failed(NIPaymentError)
    /// The checkout never started — the gateway or the provider refused to open one. Nothing was
    /// charged and the order is untouched, so this ends the *option*, not the payment: the payer
    /// goes back to the page with the reason on the row and every other method still open to them.
    /// Reported separately from `failed` because a provider that cannot be reached must not cost
    /// the merchant a sale the payer was willing to complete by card.
    case unavailable(NIPaymentError)
    /// Dismissed before the provider recorded anything against the payment. The order is untouched
    /// and still payable, so the payer can go back and choose another method.
    case dismissed
    /// Cancelled on the provider's own hosted page. The payer backing out is not a payment outcome,
    /// so the SDK returns them to the payment page instead of ending the payment.
    case cancelledOnProvider
}

/// Hosts a buy-now-pay-later checkout — Tamara or Tabby, which share this flow exactly.
///
/// `POST .../{provider}` with the three return URLs answers with the provider's hosted checkout URL
/// and its own reference → the payer approves the instalment plan on the provider's page → the
/// provider redirects to whichever return URL matches the outcome → the SDK intercepts that
/// redirect (it never loads), hands the reference to `POST .../{provider}/accept` so the backend can
/// finalise the payment, then polls the order for the authoritative state.
class BnplViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    /// Which return URL the provider redirected to.
    private enum ReturnLeg {
        case success
        case cancel
        case failure
    }

    private let args: BnplInitArgs
    private let transactionService: TransactionService
    private let accessToken: String
    private let onCompletion: (BnplPaymentStatus) -> Void

    private var didDispatchResult = false
    private var didStartPolling = false
    private var pollAttempt = 0
    /// Set once a return leg has been seen, so backing out afterwards resolves the payment from the
    /// order rather than discarding a checkout the payer may already have completed.
    private var sawReturn = false
    /// The provider's reference for this checkout, captured at initiation. Tamara returns it there
    /// (`tamaraOrderId`), which makes the accept call independent of what the return URL carries.
    private var providerReference: String?

    private var provider: BnplProvider { args.provider }

    private static let maxPollAttempts = 15
    private static let pollInterval: TimeInterval = 2
    /// A page must stay put this long before it is revealed, so redirect hops never flash.
    private static let revealDebounce: TimeInterval = 0.45

    private var revealWorkItem: DispatchWorkItem?

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        // Non-persistent store so a previous (possibly abandoned) checkout never leaks into the next
        // order — both providers keep the shopper signed in across checkouts otherwise.
        config.websiteDataStore = .nonPersistent()
        let wk = WKWebView(frame: .zero, configuration: config)
        wk.accessibilityIdentifier = "sdk_\(provider.rawValue)_webview"
        wk.navigationDelegate = self
        wk.uiDelegate = self
        return wk
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    /// Opaque view above the WebView; while visible the payer sees a spinner instead of whatever
    /// the WebView is rendering mid-redirect.
    private lazy var coverView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "sdk_\(provider.rawValue)_cover"
        return view
    }()

    init(args: BnplInitArgs,
         transactionService: TransactionService,
         accessToken: String,
         onCompletion: @escaping (BnplPaymentStatus) -> Void) {
        self.args = args
        self.transactionService = transactionService
        self.accessToken = accessToken
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubviews()
        startCheckout()
    }

    // MARK: - UI

    private func setupSubviews() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        view.addSubview(coverView)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: view.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        coverView.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: coverView.centerYAnchor)
        ])

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = provider.displayNameKey.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cancel".localized,
            style: .done,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    // MARK: - Flow

    private func startCheckout() {
        activityIndicator.startAnimating()
        transactionService.initBnpl(with: args.checkoutLink,
                                    successUrl: args.successUrl,
                                    cancelUrl: args.cancelUrl,
                                    failureUrl: args.failureUrl,
                                    using: accessToken) { [weak self] data, response, error in
            guard let self = self else { return }
            self.handleInitResponse(data: data, response: response, error: error)
        }
    }

    private func handleInitResponse(data: Data?, response urlResponse: URLResponse?, error: Error?) {
        // These providers refuse checkouts for reasons the SDK cannot see coming — basket below
        // their minimum, an unsupported currency, a shopper they will not lend to — and they all
        // surface here. Log the status and body verbatim; without them a refusal is
        // indistinguishable from a network failure.
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
        guard error == nil,
              let data = data,
              (200...299).contains(statusCode),
              let response = try? JSONDecoder().decode(BnplInitResponse.self, from: data) else {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            print("\(provider.methodName): initiation failed httpStatus=\(statusCode) error=\(error?.localizedDescription ?? "none") body=\(body)")
            // A transport error means the request never got an answer; a 4xx means the gateway
            // refused this order, which is the integration's problem and will not come right on a
            // retry. A 5xx is the gateway or the provider failing on their own terms.
            let category: NIPaymentErrorCategory = {
                if error != nil { return .network }
                return (400...499).contains(statusCode) ? .configuration : .provider
            }()
            DispatchQueue.main.async {
                self.dispatch(.unavailable(NIPaymentError(category: category,
                                                          message: error?.localizedDescription ?? body,
                                                          paymentMethod: self.provider.methodName)))
            }
            return
        }

        // The gateway abandoned the checkout on the payer's behalf — nothing was charged, so they
        // keep their other options.
        if response.cancelled == true {
            print("\(provider.methodName): gateway reported the checkout as cancelled")
            DispatchQueue.main.async { self.dispatch(.dismissed) }
            return
        }

        guard let checkoutUrl = response.checkoutUrl, let url = URL(string: checkoutUrl) else {
            print("\(provider.methodName): no checkout URL in the response httpStatus=\(statusCode) error=\(response.errorMessage ?? "<none>")")
            DispatchQueue.main.async {
                self.dispatch(.unavailable(NIPaymentError(
                    category: .provider,
                    message: response.errorMessage ?? "\(self.provider.methodName) did not return a checkout URL",
                    paymentMethod: self.provider.methodName)))
            }
            return
        }

        DispatchQueue.main.async {
            self.providerReference = response.providerReference
            self.webView.load(URLRequest(url: url))
        }
    }

    /// Hands the provider's outcome to the backend, then reads the result off the order. The accept
    /// call is what moves the payment out of PENDING, so a failure to reach it is not treated as a
    /// declined payment: the order is polled either way and has the final say.
    private func finaliseReturn(_ leg: ReturnLeg, referenceFromUrl: String?) {
        guard !didDispatchResult, !didStartPolling else { return }
        showCover()

        if leg == .cancel {
            print("\(provider.methodName): payer cancelled on the provider's page — returning to the payment page")
            dispatch(.cancelledOnProvider)
            return
        }

        // The reference captured at initiation is the provider's own and is known to be the one the
        // accept endpoint wants; the return URL is only a fallback for a provider that does not
        // hand it back up front.
        guard let reference = providerReference ?? referenceFromUrl, !reference.isEmpty else {
            // The providers notify the gateway server to server as well, so a return without a
            // reference is still worth resolving from the order rather than failing outright.
            print("\(provider.methodName): no provider reference available — polling the order without accepting")
            startPollingIfNeeded()
            return
        }

        transactionService.acceptBnpl(with: args.acceptLink,
                                      idField: provider.acceptIdField,
                                      idValue: reference,
                                      using: accessToken) { [weak self] data, response, error in
            guard let self = self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if error != nil || !(200...299).contains(status) {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                print("\(self.provider.methodName): accept failed httpStatus=\(status) error=\(error?.localizedDescription ?? "none") body=\(body)")
            }
            DispatchQueue.main.async { self.startPollingIfNeeded() }
        }
    }

    /// The gateway may still be finalising the payment when the redirect lands, so the order is
    /// polled until it reports a terminal state.
    private func pollOrderState() {
        pollAttempt += 1
        transactionService.getOrder(for: args.orderLink, using: accessToken) { [weak self] data, _, error in
            guard let self = self else { return }
            guard error == nil,
                  let data = data,
                  let order = try? OrderResponse.decodeFrom(data: data) else {
                self.retryOrFail()
                return
            }
            let state = order.embeddedData?.payment?.first?.state.uppercased() ?? ""
            print("\(self.provider.methodName): poll attempt=\(self.pollAttempt) state=\(state)")
            switch state {
            case "AUTHORISED", "PURCHASED", "CAPTURED", "VERIFIED":
                DispatchQueue.main.async { self.dispatch(.success) }
            case "POST_AUTH_REVIEW":
                DispatchQueue.main.async { self.dispatch(.postAuthReview) }
            case "FAILED", "DECLINED", "CANCELLED", "REVERSED":
                DispatchQueue.main.async {
                    self.dispatch(.failed(NIPaymentError(category: .declined,
                                                         message: "Payment \(state.lowercased())",
                                                         paymentMethod: self.provider.methodName)))
                }
            default:
                // Still STARTED or an in-flight state — give the backend more time.
                self.retryOrFail()
            }
        }
    }

    private func retryOrFail() {
        guard pollAttempt < BnplViewController.maxPollAttempts else {
            // The payment never reached a final state in the time allowed, so its real outcome is
            // unknown rather than known-bad. Reported as a timeout so the merchant reconciles from
            // the order instead of telling the payer it failed.
            let waited = Int(Double(BnplViewController.maxPollAttempts) * BnplViewController.pollInterval)
            DispatchQueue.main.async {
                self.dispatch(.failed(NIPaymentError(
                    category: .timeout,
                    message: "The payment did not reach a final state within \(waited)s; confirm it from the order",
                    paymentMethod: self.provider.methodName)))
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BnplViewController.pollInterval) { [weak self] in
            self?.pollOrderState()
        }
    }

    private func startPollingIfNeeded() {
        guard !didStartPolling, !didDispatchResult else { return }
        didStartPolling = true
        showCover()
        pollOrderState()
    }

    private func dispatch(_ status: BnplPaymentStatus) {
        guard !didDispatchResult else { return }
        didDispatchResult = true
        activityIndicator.stopAnimating()

        // A result can land before the sheet has finished animating in — an init that fails fast
        // beats the presentation. UIKit drops a dismissal issued mid-transition, which would strand
        // the payer on a blank sheet with no way back, so wait for the transition to settle first.
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.finish(with: status)
            }
        } else {
            finish(with: status)
        }
    }

    private func finish(with status: BnplPaymentStatus) {
        dismiss(animated: true) { [onCompletion] in
            onCompletion(status)
        }
    }

    @objc private func cancelTapped() {
        webView.stopLoading()
        // A cancel after the return leg would discard a checkout that already went through.
        if sawReturn {
            startPollingIfNeeded()
            return
        }
        // Backing out from our own toolbar before the provider recorded anything leaves the order
        // untouched, so the payer keeps their other options.
        dispatch(.dismissed)
    }

    // MARK: - Cover (hide intermediate redirect pages)

    private func showCover() {
        revealWorkItem?.cancel()
        revealWorkItem = nil
        coverView.isHidden = false
        activityIndicator.startAnimating()
    }

    /// Reveals the WebView only if no further navigation starts within `revealDebounce`. A redirect
    /// chain begins its next hop well inside that window, which re-covers and cancels this.
    private func scheduleReveal() {
        revealWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.coverView.isHidden = true
        }
        revealWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + BnplViewController.revealDebounce, execute: item)
    }

    // MARK: - Return legs

    /// Which return URL, if any, a navigation is heading to. Matching is on the marker parameter the
    /// SDK put there rather than on the whole URL, because the providers append their own
    /// parameters to the address they were given.
    private func returnLeg(for url: URL?) -> ReturnLeg? {
        guard let url = url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let marker = components.queryItems?.first(where: { $0.name == BnplInitArgs.resultParam })?.value
        else { return nil }
        switch marker {
        case "success": return .success
        case "cancel": return .cancel
        case "failure": return .failure
        default: return nil
        }
    }

    /// The provider's identifier for the checkout, read off the return URL. Used only when the
    /// initiation response did not already carry one, and every name either provider has been seen
    /// to use is accepted.
    private func reference(from url: URL?) -> String? {
        guard let url = url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }
        let names = [provider.acceptIdField, "orderId", "order_id", "paymentId", "payment_id", "checkoutId"]
        for name in names {
            if let value = items.first(where: { $0.name == name })?.value, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    /// Catches a return leg wherever it surfaces — a navigation the policy delegate sees, or a
    /// server-side redirect it never does. The paypage the URL points at is meaningless for an
    /// SDK-hosted payment (its session was consumed when the payment started here rather than
    /// there, so it renders a dead "payment link is not exist" page), which is why the navigation is
    /// stopped rather than allowed.
    @discardableResult
    private func handleIfReturn(_ url: URL?) -> Bool {
        guard let leg = returnLeg(for: url) else { return false }
        sawReturn = true
        webView.stopLoading()
        showCover()
        finaliseReturn(leg, referenceFromUrl: reference(from: url))
        return true
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        print("\(provider.methodName): navigating to \(url?.absoluteString ?? "<nil>")")
        if handleIfReturn(url) {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showCover()
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // A redirect taken mid-navigation lands here instead of in `decidePolicyFor`, so this is the
        // other place the return has to be caught — otherwise the paypage loads behind the cover.
        print("\(provider.methodName): server redirect to \(webView.url?.absoluteString ?? "<nil>")")
        if handleIfReturn(webView.url) { return }
        showCover()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if handleIfReturn(webView.url) { return }
        scheduleReveal()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(error)
    }

    /// Once a return leg has been seen the payment is already decided server-side, so a failure
    /// loading whatever came next must not be reported as a failed payment.
    private func handleNavigationFailure(_ error: Error) {
        print("\(provider.methodName): navigation failed - \(error.localizedDescription)")

        // Cancelling the return navigation above is our own doing, and WebKit reports that as a
        // failure. The payment is already being resolved, so it must never be mistaken for the page
        // failing to load.
        let nsError = error as NSError
        let isSelfInflicted = nsError.code == NSURLErrorCancelled
            || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102)
        if isSelfInflicted || didStartPolling || didDispatchResult {
            return
        }

        if sawReturn {
            startPollingIfNeeded()
            return
        }
        // The hosted page never loaded. Connectivity errors are worth a retry; anything else is the
        // provider's page failing on its own terms.
        let isOffline = [NSURLErrorNotConnectedToInternet,
                         NSURLErrorNetworkConnectionLost,
                         NSURLErrorTimedOut,
                         NSURLErrorCannotFindHost,
                         NSURLErrorCannotConnectToHost].contains(nsError.code)
        dispatch(.unavailable(NIPaymentError(category: isOffline ? .network : .provider,
                                             message: error.localizedDescription,
                                             paymentMethod: provider.methodName)))
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
