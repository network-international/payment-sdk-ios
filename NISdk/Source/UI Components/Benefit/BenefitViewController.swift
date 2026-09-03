//
//  BenefitViewController.swift
//  NISdk
//

import Foundation
import UIKit
import WebKit

enum BenefitPaymentStatus {
    case success
    case postAuthReview
    /// Carries why, so the merchant can tell a decline from a dropped connection or a
    /// misconfigured order instead of receiving an undifferentiated failure.
    case failed(NIPaymentError)
    /// Dismissed before Benefit recorded anything against the payment. The order is untouched and
    /// still payable, so the payer can go back and choose another method.
    case dismissed
    /// Cancelled on Benefit's own hosted page, after the gateway had already marked this attempt
    /// FAILED. Reported separately from `dismissed` because that attempt is spent, but it is still
    /// the payer backing out rather than a payment outcome, so the SDK returns them to the payment
    /// page instead of ending the payment.
    case cancelledOnProvider
}

/// Hosts the Benefit (Bahrain debit) hosted payment page.
///
/// Flow: `POST .../benefit` returns a hosted `paymentUrl` → the payer authenticates on Benefit's
/// page → Benefit form-POSTs back to `.../benefit/Response/accept` (or `/Error/accept`) on our
/// gateway, which processes the result and answers `303` to the paypage. That paypage hop is
/// meaningless for an SDK-hosted payment, so the WebView stays covered and the order is polled for
/// the authoritative payment state instead of reading anything off the page.
class BenefitViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private let args: BenefitInitArgs
    private let transactionService: TransactionService
    private let accessToken: String
    private let onCompletion: (BenefitPaymentStatus) -> Void

    private var didDispatchResult = false
    /// Set once the gateway's own accept callback is reached, which means the payment result has
    /// been handed to the backend and the order is worth polling.
    private var sawReturnCallback = false
    private var didStartPolling = false
    private var pollAttempt = 0
    /// Set when the payer is seen hitting Benefit's cancel page. Distinguishes "the payer backed
    /// out" from "the payment was declined" — the order reports `FAILED` for both.
    private var payerCancelled = false
    /// Set once the WebView has actually reached Benefit's own site, so leaving it can be read as
    /// the payer returning rather than as the flow still starting up.
    private var didReachBenefitHost = false
    /// Host of the hosted page the gateway handed us, e.g. `test.benefit-gateway.bh`.
    private var benefitHost: String?

    /// Names the method on any error handed to the merchant.
    static let methodName = "BENEFIT"

    private static let maxPollAttempts = 15
    private static let pollInterval: TimeInterval = 2
    /// A page must stay put this long before it is revealed, so redirect hops never flash.
    private static let revealDebounce: TimeInterval = 0.45

    private var revealWorkItem: DispatchWorkItem?

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        // Non-persistent store so a previous (possibly failed) Benefit session never leaks into the
        // next order — the hosted page and gateway both set cookies keyed to the payment.
        config.websiteDataStore = .nonPersistent()
        let wk = WKWebView(frame: .zero, configuration: config)
        wk.accessibilityIdentifier = "sdk_benefit_webview"
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
    private let coverView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "sdk_benefit_cover"
        return view
    }()

    init(args: BenefitInitArgs,
         transactionService: TransactionService,
         accessToken: String,
         onCompletion: @escaping (BenefitPaymentStatus) -> Void) {
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
        navigationItem.title = "Benefit".localized
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
        transactionService.initBenefit(with: args.benefitLink, using: accessToken) { [weak self] data, response, error in
            guard let self = self else { return }
            self.handleInitResponse(data: data, response: response, error: error)
        }
    }

    private func handleInitResponse(data: Data?, response urlResponse: URLResponse?, error: Error?) {
        // The gateway rejects Benefit for several reasons that all surface here (order not flagged
        // GCC, action not PURCHASE, currency not BHD, payment already processed). Log the status and
        // body verbatim — without them a rejection is indistinguishable from a network failure.
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
        guard error == nil,
              let data = data,
              let response = try? JSONDecoder().decode(BenefitInitResponse.self, from: data) else {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            print("Benefit: initiation failed httpStatus=\(statusCode) error=\(error?.localizedDescription ?? "none") body=\(body)")
            // A transport error means the request never got an answer; a 4xx means the gateway
            // refused this order (not GCC, wrong action or currency, payment already processed),
            // which is the integration's problem and will not come right on a retry.
            let category: NIPaymentErrorCategory = {
                if error != nil { return .network }
                return (400...499).contains(statusCode) ? .configuration : .provider
            }()
            let detail = error?.localizedDescription ?? body
            DispatchQueue.main.async {
                self.dispatch(.failed(NIPaymentError(category: category,
                                                     message: detail,
                                                     paymentMethod: Self.methodName)))
            }
            return
        }
        guard response.isInitiated,
              let paymentUrl = response.paymentUrl,
              let url = URL(string: paymentUrl) else {
            print("Benefit: initiation rejected httpStatus=\(statusCode) status=\(response.status ?? "<nil>") error=\(response.errorMessage ?? "<none>")")
            // Answered, but Benefit would not start the payment — their problem, not the payer's.
            DispatchQueue.main.async {
                self.dispatch(.failed(NIPaymentError(
                    category: .provider,
                    message: response.errorMessage ?? "Benefit did not accept the payment (status \(response.status ?? "unknown"))",
                    paymentMethod: Self.methodName)))
            }
            return
        }
        DispatchQueue.main.async {
            self.benefitHost = url.host?.lowercased()
            self.webView.load(URLRequest(url: url))
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
            print("Benefit: poll attempt=\(self.pollAttempt) state=\(state)")
            switch state {
            case "AUTHORISED", "PURCHASED", "CAPTURED", "VERIFIED":
                DispatchQueue.main.async { self.dispatch(.success) }
            case "POST_AUTH_REVIEW":
                DispatchQueue.main.async { self.dispatch(.postAuthReview) }
            case "FAILED", "DECLINED", "CANCELLED", "REVERSED":
                // A failure that followed the error callback is the payer backing out, not a
                // decline, so it hands them back to the payment page rather than ending the payment.
                DispatchQueue.main.async {
                    self.dispatch(self.payerCancelled
                                  ? .cancelledOnProvider
                                  : .failed(NIPaymentError(category: .declined,
                                                           message: "Payment \(state.lowercased())",
                                                           paymentMethod: Self.methodName)))
                }
            default:
                // Still STARTED or an in-flight state — give the backend more time.
                self.retryOrFail()
            }
        }
    }

    private func retryOrFail() {
        guard pollAttempt < BenefitViewController.maxPollAttempts else {
            // The payment never reached a final state in the time allowed, so its real outcome is
            // unknown rather than known-bad. Reported as a timeout so the merchant reconciles from
            // the order instead of telling the payer it failed.
            let waited = Int(Double(BenefitViewController.maxPollAttempts) * BenefitViewController.pollInterval)
            DispatchQueue.main.async {
                self.dispatch(.failed(NIPaymentError(
                    category: .timeout,
                    message: "The payment did not reach a final state within \(waited)s; confirm it from the order",
                    paymentMethod: Self.methodName)))
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BenefitViewController.pollInterval) { [weak self] in
            self?.pollOrderState()
        }
    }

    private func startPollingIfNeeded() {
        guard !didStartPolling, !didDispatchResult else { return }
        didStartPolling = true
        showCover()
        pollOrderState()
    }

    /// Decides what to do once the payer has left Benefit's site. The gateway has already recorded
    /// the result by this point — it is what redirected us onwards — so an error callback needs no
    /// confirmation from the order: it can only mean the payer cancelled or the attempt errored, and
    /// either way they belong back on the payment page with their other options intact. Anything
    /// else is a real result and is read from the order.
    private func resolveAfterLeavingBenefit() {
        guard !didDispatchResult, !didStartPolling else { return }
        if payerCancelled {
            print("Benefit: payer cancelled on Benefit's page — returning to the payment page")
            dispatch(.cancelledOnProvider)
            return
        }
        print("Benefit: suppressing post-payment redirect, polling order instead")
        startPollingIfNeeded()
    }

    private func dispatch(_ status: BenefitPaymentStatus) {
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

    private func finish(with status: BenefitPaymentStatus) {
        dismiss(animated: true) { [onCompletion] in
            onCompletion(status)
        }
    }

    @objc private func cancelTapped() {
        webView.stopLoading()
        // A cancel after the gateway callback would discard a payment that already went through.
        if sawReturnCallback {
            startPollingIfNeeded()
            return
        }
        // Backing out from our own toolbar before Benefit recorded anything leaves the order
        // untouched, so the payer keeps their other options.
        dispatch(payerCancelled ? .cancelledOnProvider : .dismissed)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + BenefitViewController.revealDebounce, execute: item)
    }

    /// True for the gateway's own return endpoints, `.../benefit/Response/accept` and
    /// `.../benefit/Error/accept`. Both mean the result reached the backend; which one it was does
    /// not decide the outcome, the polled order state does.
    private func isReturnCallback(_ url: URL?) -> Bool {
        guard let path = url?.path.lowercased() else { return false }
        return path.contains("/benefit/") && path.hasSuffix("/accept")
    }

    /// The api-gateway host the order itself lives on. Every server-side callback — the accept
    /// endpoint included — is on this host, so navigations to it are never suppressed.
    private lazy var gatewayHost: String? = URL(string: args.orderLink)?.host?.lowercased()

    private func isGatewayHost(_ url: URL?) -> Bool {
        guard let gateway = gatewayHost, let host = url?.host?.lowercased() else { return false }
        return host == gateway
    }

    private func isBenefitHost(_ url: URL?) -> Bool {
        guard let benefit = benefitHost, let host = url?.host?.lowercased() else { return false }
        return host == benefit
    }

    /// The payer is done with Benefit the moment the WebView leaves Benefit's own site, whatever it
    /// lands on next. That destination cannot be predicted from the order: the paypage is on an
    /// entirely different domain from the gateway (`paypage-dev.platform.network.ae` versus
    /// `api-gateway-dev.ngenius-payments.com`), so a rule written in terms of our own domain misses
    /// it and lets the paypage's dead "payment link is not exist" page render. Leaving Benefit is
    /// the signal; where it goes afterwards is not our business, because the order decides the
    /// outcome regardless.
    private func hasLeftBenefit(_ url: URL?) -> Bool {
        guard didReachBenefitHost else { return false }
        return !isBenefitHost(url)
    }

    /// Benefit's own cancel page, e.g. `test.benefit-gateway.bh/payment/paymentcancel.htm`. Tapping
    /// Cancel on the hosted page lands here before Benefit hands control back to us.
    ///
    /// This — not the gateway's `Error/accept` — is the only cancel signal the WebView ever sees.
    /// Benefit reports the outcome to our backend server to server, so the accept callback never
    /// appears as a navigation at all; by the time the WebView moves again it is already on the
    /// paypage, which looks identical for a cancel and for a decline.
    private func isBenefitCancelPage(_ url: URL?) -> Bool {
        guard isBenefitHost(url), let path = url?.path.lowercased() else { return false }
        return path.contains("cancel")
    }

    /// `.../benefit/Error/accept`. Kept as a secondary signal for the case where the callback does
    /// travel through the WebView, since the backend records it as a failed payment unconditionally
    /// and so it can never mean the payer actually paid.
    private func isErrorCallback(_ url: URL?) -> Bool {
        guard let path = url?.path.lowercased() else { return false }
        return path.contains("/benefit/error/") && path.hasSuffix("/accept")
    }

    /// Records anything worth knowing about a URL the WebView passes through. Server redirects and
    /// policy decisions surface different hops of the same chain, so both feed into this.
    private func noteNavigation(_ url: URL?, source: String) {
        print("Benefit: \(source) \(url?.absoluteString ?? "<nil>")")
        if isBenefitCancelPage(url) || isErrorCallback(url) {
            print("Benefit: payer cancelled on the hosted page")
            payerCancelled = true
        }
        if isReturnCallback(url) {
            sawReturnCallback = true
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        noteNavigation(url, source: "navigating to")

        if isReturnCallback(url) {
            // Allowed through so the backend can process the Benefit result; the order is polled
            // once this hop settles.
            decisionHandler(.allow)
            return
        }

        // Never suppress anything on the gateway itself. The accept callback is what tells the
        // backend how the payment went, and its exact path is the gateway's to choose — cancelling
        // it because it did not match the expected shape would strand the payment in PENDING.
        if isGatewayHost(url) {
            decisionHandler(.allow)
            return
        }

        // Anything else on our own domain once the payer has been to Benefit is the browser-facing
        // paypage hop, which the gateway 303s to after it has already recorded the result. That
        // page's session was consumed when the payment started from the SDK rather than the paypage,
        // so it renders "the payment link is not exist" — a dead end the payer must never see. Stop
        // it loading and resolve the payment from the order, which is authoritative regardless.
        if sawReturnCallback || hasLeftBenefit(url) {
            decisionHandler(.cancel)
            showCover()
            resolveAfterLeavingBenefit()
            return
        }

        if isBenefitHost(url) {
            didReachBenefitHost = true
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showCover()
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // A 303 taken mid-navigation lands here instead of in `decidePolicyFor`, so this is the
        // other place the return has to be caught — otherwise the paypage loads behind the cover.
        // It is also where the accept callback tends to show up, since Benefit reaches it through a
        // server-side redirect chain rather than a navigation the policy delegate ever sees.
        noteNavigation(webView.url, source: "server redirect to")
        if isReturnCallback(webView.url) || hasLeftBenefit(webView.url) {
            sawReturnCallback = true
            webView.stopLoading()
            showCover()
            resolveAfterLeavingBenefit()
            return
        }
        showCover()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if sawReturnCallback || hasLeftBenefit(webView.url) {
            startPollingIfNeeded()
            return
        }
        scheduleReveal()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(error)
    }

    /// After the accept callback the payment is already decided server-side, so a failure loading
    /// the redirect target must not be reported as a failed payment.
    private func handleNavigationFailure(_ error: Error) {
        print("Benefit: navigation failed - \(error.localizedDescription)")

        // Suppressing the paypage hop above cancels a navigation, and WebKit reports that as a
        // failure. It is our own doing and the payment is already being resolved, so it must never
        // be mistaken for the page failing to load.
        let nsError = error as NSError
        let isSelfInflicted = nsError.code == NSURLErrorCancelled
            || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102)
        if isSelfInflicted || didStartPolling {
            return
        }

        if sawReturnCallback {
            startPollingIfNeeded()
            return
        }
        // Benefit's hosted page never loaded. Connectivity errors are worth a retry; anything else
        // is Benefit's page failing on its own terms.
        let isOffline = [NSURLErrorNotConnectedToInternet,
                         NSURLErrorNetworkConnectionLost,
                         NSURLErrorTimedOut,
                         NSURLErrorCannotFindHost,
                         NSURLErrorCannotConnectToHost].contains(nsError.code)
        dispatch(.failed(NIPaymentError(category: isOffline ? .network : .provider,
                                        message: error.localizedDescription,
                                        paymentMethod: Self.methodName)))
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
