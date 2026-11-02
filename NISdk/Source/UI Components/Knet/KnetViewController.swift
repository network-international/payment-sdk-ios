//
//  KnetViewController.swift
//  NISdk
//

import Foundation
import UIKit
import WebKit

/// `POST .../knet` answers in the same shape as Benefit's initiation — `paymentId`, `paymentUrl`,
/// `status: "Initiated"` — and rejects with the same gateway error envelope
/// (`"Failed to encrypt KNET trandata" (invalidKnetPayment)`), so the decoders are shared.
typealias KnetInitResponse = BenefitInitResponse
typealias KnetInitErrorBody = BenefitInitErrorBody

enum KnetPaymentStatus {
    case success
    case postAuthReview
    /// Carries why, so the merchant can tell a decline from a dropped connection or a
    /// misconfigured order instead of receiving an undifferentiated failure.
    case failed(NIPaymentError)
    /// The payer left before KNET settled anything. The order is still payable — a fresh KNET
    /// attempt is accepted on it — so the payer goes back to the payment page to try again or pick
    /// another method.
    case dismissed
    /// Cancelled on KNET's own hosted page. That attempt is spent, but it is the payer backing out
    /// rather than a payment outcome, so they go back to the payment page with the order intact.
    case cancelledOnProvider
    /// KNET never started: the order had no `payment:knet` link, the gateway refused the
    /// initiation, or KNET's page never loaded. The payer never saw KNET and nothing was recorded,
    /// so this is not a payment outcome; their other methods survive it.
    case couldNotStart(NIPaymentError)
}

extension KnetPaymentStatus {
    /// True for every outcome that leaves the order payable. Those go back to the unified payment
    /// page instead of ending the payment, so the payer gets another try on the same order.
    var returnsToPaymentPage: Bool {
        switch self {
        case .dismissed, .cancelledOnProvider, .couldNotStart:
            return true
        case .success, .postAuthReview, .failed:
            return false
        }
    }
}

/// Hosts KNET (Kuwait debit) payments.
///
/// Flow: re-read the order → `POST` its current `payment:knet` link → load the returned
/// `paymentUrl` on KNET's site → the payer pays or cancels there → KNET reports to the gateway and
/// the browser is sent onwards to the paypage. That paypage hop means nothing inside the SDK, so
/// the WebView is covered the moment it leaves KNET's site and the order is polled for the
/// authoritative state. Nothing on the redirect is ever trusted as a result.
///
/// Differs from `BenefitViewController` in two ways:
/// - The order is re-read before every attempt, so a retry after a cancel always posts to the
///   payment's current `payment:knet` link rather than the one the page was built with.
/// - There is no SDK Cancel button; KNET's page has its own. Its cancel lands back on the payment
///   page, and a KNET payment that is merely `PENDING` (as every one is from initiation) can be
///   initiated again, so the payer gets another try on the same order.
class KnetViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private let args: KnetInitArgs
    private let transactionService: TransactionService
    private let accessToken: String
    private let onCompletion: (KnetPaymentStatus) -> Void

    private var didDispatchResult = false
    /// Set once a gateway callback for KNET is seen, meaning the result reached the backend.
    private var sawReturnCallback = false
    private var didStartPolling = false
    private var pollAttempt = 0
    /// Set while the order is being checked before the payer may leave KNET's page.
    private var isVerifyingBeforeLeaving = false
    /// Set when the payer is seen on KNET's cancel page. Distinguishes "the payer backed out" from
    /// "the payment was declined" — the order reports `FAILED` for both.
    private var payerCancelled = false
    /// Set once the WebView has reached KNET's own site, so leaving it reads as the payer returning
    /// rather than as the flow still starting up.
    private var didReachKnetHost = false
    /// Host of the hosted page the gateway handed us, e.g. `kpaytest.com.kw`.
    private var knetHost: String?

    /// Names the method on any error handed to the merchant.
    static let methodName = "KNET"

    private static let maxPollAttempts = 15
    private static let pollInterval: TimeInterval = 2
    /// A page must stay put this long before it is revealed, so redirect hops never flash.
    private static let revealDebounce: TimeInterval = 0.45

    private static let successStates: Set<String> = ["AUTHORISED", "PURCHASED", "CAPTURED", "VERIFIED"]
    private static let failedStates: Set<String> = ["FAILED", "DECLINED", "CANCELLED", "REVERSED"]

    private var revealWorkItem: DispatchWorkItem?

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        // Non-persistent store so a previous (possibly cancelled) KNET session never leaks into the
        // next attempt — KNET's page and the gateway both set cookies keyed to the payment.
        config.websiteDataStore = .nonPersistent()
        let wk = WKWebView(frame: .zero, configuration: config)
        wk.accessibilityIdentifier = "sdk_knet_webview"
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
        view.accessibilityIdentifier = "sdk_knet_cover"
        return view
    }()

    init(args: KnetInitArgs,
         transactionService: TransactionService,
         accessToken: String,
         onCompletion: @escaping (KnetPaymentStatus) -> Void) {
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
        // A trademark: "KNET" stays in Latin script in every locale.
        navigationItem.title = "KNET"
        // No Cancel of our own: KNET's page carries its own, so a second one is not shown.
        // KNET's Cancel reaches the gateway and lands back on the payment page.
    }

    // MARK: - Flow

    /// Re-reads the order before initiating, so a second attempt on the same order (after a
    /// cancel) uses the payment's current `payment:knet` link and never re-initiates a payment that
    /// has meanwhile gone through.
    private func startCheckout() {
        showCover()
        transactionService.getOrder(for: args.orderLink, using: accessToken) { [weak self] data, _, error in
            guard let self = self else { return }
            guard error == nil,
                  let data = data,
                  let order = try? OrderResponse.decodeFrom(data: data) else {
                // The order could not be re-read; the link the page was built with is still the
                // best guess, and the gateway refuses it if it no longer applies.
                print("KNET: could not re-read the order before starting; using the original link")
                self.initiate(with: self.args.knetLink)
                return
            }
            let payment = order.embeddedData?.payment?.first
            let state = payment?.state.uppercased() ?? ""
            print("KNET: starting, order state=\(state), knet link=\(payment?.paymentLinks?.knetLink != nil)")
            if Self.successStates.contains(state) {
                // An earlier attempt on this order settled after the payer left it.
                print("KNET: order already paid (state=\(state)); not starting another attempt")
                DispatchQueue.main.async { self.dispatch(.success) }
                return
            }
            if state == "POST_AUTH_REVIEW" {
                DispatchQueue.main.async { self.dispatch(.postAuthReview) }
                return
            }
            guard let link = payment?.paymentLinks?.knetLink, !link.isEmpty else {
                print("KNET: order no longer offers KNET (state=\(state))")
                DispatchQueue.main.async {
                    self.dispatch(.couldNotStart(NIPaymentError(category: .configuration,
                                                                message: "The order no longer carries a payment:knet link",
                                                                paymentMethod: Self.methodName)))
                }
                return
            }
            self.initiate(with: link)
        }
    }

    private func initiate(with knetLink: String) {
        transactionService.initKnet(with: knetLink, using: accessToken) { [weak self] data, response, error in
            guard let self = self else { return }
            self.handleInitResponse(data: data, response: response, error: error)
        }
    }

    private func handleInitResponse(data: Data?, response urlResponse: URLResponse?, error: Error?) {
        // The gateway refuses KNET for several reasons that all surface here (KNET keys not
        // provisioned — "Failed to encrypt KNET trandata" — wrong currency or action, payment
        // already processed). Log status and reason; without them a refusal looks like a network
        // failure.
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
        guard error == nil,
              let data = data,
              let response = try? JSONDecoder().decode(KnetInitResponse.self, from: data) else {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            print("KNET: initiation failed httpStatus=\(statusCode) error=\(error?.localizedDescription ?? "none") body=\(body)")
            let category: NIPaymentErrorCategory = {
                if error != nil { return .network }
                return (400...499).contains(statusCode) ? .configuration : .provider
            }()
            let envelope = data.flatMap { try? JSONDecoder().decode(KnetInitErrorBody.self, from: $0) }
            let detail = error?.localizedDescription ?? envelope?.reason ?? body
            DispatchQueue.main.async {
                self.dispatch(.couldNotStart(NIPaymentError(category: category,
                                                            message: detail,
                                                            paymentMethod: Self.methodName)))
            }
            return
        }
        guard response.isInitiated,
              let paymentUrl = response.paymentUrl,
              let url = URL(string: paymentUrl) else {
            // A refusal is answered with the gateway's error envelope, which decodes into an
            // all-nil KnetInitResponse, so the reason has to be read from the envelope.
            let envelope = try? JSONDecoder().decode(KnetInitErrorBody.self, from: data)
            let reason = response.errorMessage
                ?? envelope?.reason
                ?? "KNET did not accept the payment (status \(response.status ?? "unknown"))"
            print("KNET: initiation rejected httpStatus=\(statusCode) status=\(response.status ?? "<nil>") error=\(reason)")
            DispatchQueue.main.async {
                self.dispatch(.couldNotStart(NIPaymentError(category: .provider,
                                                            message: reason,
                                                            paymentMethod: Self.methodName)))
            }
            return
        }
        DispatchQueue.main.async {
            self.knetHost = url.host?.lowercased()
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
            print("KNET: poll attempt=\(self.pollAttempt) state=\(state)")
            if Self.successStates.contains(state) {
                DispatchQueue.main.async { self.dispatch(.success) }
            } else if state == "POST_AUTH_REVIEW" {
                DispatchQueue.main.async { self.dispatch(.postAuthReview) }
            } else if Self.failedStates.contains(state) {
                // A failure that followed KNET's cancel page is the payer backing out, not a
                // decline, so it hands them back to the payment page.
                DispatchQueue.main.async {
                    self.dispatch(self.payerCancelled
                                  ? .cancelledOnProvider
                                  : .failed(NIPaymentError(category: .declined,
                                                           message: "Payment \(state.lowercased())",
                                                           paymentMethod: Self.methodName)))
                }
            } else {
                // Still PENDING or another in-flight state — give the backend more time.
                self.retryOrFail()
            }
        }
    }

    private func retryOrFail() {
        guard pollAttempt < KnetViewController.maxPollAttempts else {
            // The payment never reached a final state in the time allowed, so its outcome is
            // unknown rather than known-bad. Reported as a timeout so the merchant reconciles from
            // the order instead of telling the payer it failed.
            let waited = Int(Double(KnetViewController.maxPollAttempts) * KnetViewController.pollInterval)
            DispatchQueue.main.async {
                self.dispatch(.failed(NIPaymentError(
                    category: .timeout,
                    message: "The payment did not reach a final state within \(waited)s; confirm it from the order",
                    paymentMethod: Self.methodName)))
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + KnetViewController.pollInterval) { [weak self] in
            self?.pollOrderState()
        }
    }

    private func startPollingIfNeeded() {
        guard !didStartPolling, !didDispatchResult else { return }
        didStartPolling = true
        showCover()
        pollOrderState()
    }

    /// Decides what to do once the payer has left KNET's site. A cancel seen on KNET's own page
    /// needs no confirmation: the payer goes back to the payment page. Anything else is a real
    /// result and is read from the order.
    private func resolveAfterLeavingKnet() {
        guard !didDispatchResult, !didStartPolling else { return }
        if payerCancelled {
            print("KNET: payer cancelled on KNET's page — returning to the payment page")
            dispatch(.cancelledOnProvider)
            return
        }
        print("KNET: suppressing post-payment redirect, polling order instead")
        startPollingIfNeeded()
    }

    private func dispatch(_ status: KnetPaymentStatus) {
        guard !didDispatchResult else { return }
        didDispatchResult = true
        activityIndicator.stopAnimating()

        // A result can land before the sheet has finished animating in. UIKit drops a dismissal
        // issued mid-transition, which would strand the payer on a blank sheet, so wait for it.
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.finish(with: status)
            }
        } else {
            finish(with: status)
        }
    }

    private func finish(with status: KnetPaymentStatus) {
        dismiss(animated: true) { [onCompletion] in
            onCompletion(status)
        }
    }

    /// Reads the order once when KNET's page stops loading part-way. A payment that already went
    /// through ends the flow as a success instead of handing the payer a spent order; every other
    /// state returns them to the payment page, where the same order can be tried again. If the
    /// order cannot be read, the payer stays on KNET's page rather than being let go on a guess.
    private func verifyBeforeLeaving() {
        isVerifyingBeforeLeaving = true
        showCover()
        transactionService.getOrder(for: args.orderLink, using: accessToken) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isVerifyingBeforeLeaving = false
                guard error == nil,
                      let data = data,
                      let order = try? OrderResponse.decodeFrom(data: data) else {
                    print("KNET: could not read the order; staying on KNET's page")
                    self.scheduleReveal()
                    return
                }
                let state = order.embeddedData?.payment?.first?.state.uppercased() ?? ""
                print("KNET: checked the order before leaving KNET's page, state=\(state)")
                if Self.successStates.contains(state) {
                    self.dispatch(.success)
                } else if state == "POST_AUTH_REVIEW" {
                    self.dispatch(.postAuthReview)
                } else if Self.failedStates.contains(state) {
                    self.webView.stopLoading()
                    self.dispatch(.cancelledOnProvider)
                } else {
                    // STARTED, or PENDING — which every KNET payment is from initiation until the
                    // payer finishes on KNET's page. The gateway accepts a fresh initiation on a
                    // PENDING payment, so the order stays payable and the payer goes back to the
                    // payment page.
                    self.webView.stopLoading()
                    self.dispatch(.dismissed)
                }
            }
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + KnetViewController.revealDebounce, execute: item)
    }

    /// The api-gateway host the order lives on. Every server-side callback is on this host, so
    /// navigations to it are never suppressed.
    private lazy var gatewayHost: String? = URL(string: args.orderLink)?.host?.lowercased()

    private func isGatewayHost(_ url: URL?) -> Bool {
        guard let gateway = gatewayHost, let host = url?.host?.lowercased() else { return false }
        return host == gateway
    }

    /// A KNET callback on our own gateway (its exact path is the gateway's choice; anything under a
    /// `/knet` segment counts). Reaching it means the result was handed to the backend.
    private func isReturnCallback(_ url: URL?) -> Bool {
        guard isGatewayHost(url), let path = url?.path.lowercased() else { return false }
        return path.contains("/knet/") || path.hasSuffix("/knet")
    }

    private func isKnetHost(_ url: URL?) -> Bool {
        guard let knet = knetHost, let host = url?.host?.lowercased() else { return false }
        return host == knet
    }

    /// The payer is done with KNET the moment the WebView leaves KNET's site, wherever it lands
    /// next. The order decides the outcome regardless of that destination.
    private func hasLeftKnet(_ url: URL?) -> Bool {
        guard didReachKnetHost else { return false }
        return !isKnetHost(url)
    }

    /// KNET's own cancel page, `kpaytest.com.kw/kpg/paymentcancel.htm` on the test host. Tapping
    /// Cancel on the hosted page posts there before KNET hands control back to the gateway.
    private func isKnetCancelPage(_ url: URL?) -> Bool {
        guard isKnetHost(url), let path = url?.path.lowercased() else { return false }
        return path.contains("cancel")
    }

    /// Records anything worth knowing about a URL the WebView passes through. Server redirects and
    /// policy decisions surface different hops of the same chain, so both feed into this.
    private func noteNavigation(_ url: URL?, source: String) {
        print("KNET: \(source) \(redactUrlForLog(url))")
        if isKnetCancelPage(url) {
            print("KNET: payer cancelled on the hosted page")
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

        // Never suppress anything on the gateway itself: its callback is what tells the backend how
        // the payment went, and cancelling it would strand the payment in PENDING.
        if isGatewayHost(url) {
            decisionHandler(.allow)
            return
        }

        // Anything else once the payer has left KNET is the browser-facing paypage hop, a dead end
        // inside the SDK. Stop it and resolve the payment from the order.
        if sawReturnCallback || hasLeftKnet(url) {
            decisionHandler(.cancel)
            showCover()
            resolveAfterLeavingKnet()
            return
        }

        if isKnetHost(url) {
            didReachKnetHost = true
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showCover()
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // A 30x taken mid-navigation lands here instead of in `decidePolicyFor`, so this is the
        // other place the return has to be caught — otherwise the paypage loads behind the cover.
        noteNavigation(webView.url, source: "server redirect to")
        if hasLeftKnet(webView.url) && !isGatewayHost(webView.url) {
            webView.stopLoading()
            showCover()
            resolveAfterLeavingKnet()
            return
        }
        showCover()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // KNET's cancel page is a dead end: it shows "Payment Page validation failed due to invalid
        // Order Status: CANCELED" and never redirects back. Once it has loaded KNET has recorded the
        // cancel, so the payer goes straight back to the payment page — the cover raised when the
        // navigation started keeps that page from ever showing.
        if payerCancelled {
            resolveAfterLeavingKnet()
            return
        }
        if sawReturnCallback || hasLeftKnet(webView.url) {
            resolveAfterLeavingKnet()
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

    /// After the payer has left KNET the payment is decided server-side, so a failure loading the
    /// redirect target must not be reported as a failed payment.
    private func handleNavigationFailure(_ error: Error) {
        print("KNET: navigation failed - \(error.localizedDescription)")

        // Suppressing the paypage hop cancels a navigation, which WebKit reports as a failure.
        let nsError = error as NSError
        let isSelfInflicted = nsError.code == NSURLErrorCancelled
            || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102)
        if isSelfInflicted || didStartPolling || didDispatchResult {
            return
        }

        if sawReturnCallback || hasLeftKnet(webView.url) {
            resolveAfterLeavingKnet()
            return
        }
        let isOffline = [NSURLErrorNotConnectedToInternet,
                         NSURLErrorNetworkConnectionLost,
                         NSURLErrorTimedOut,
                         NSURLErrorCannotFindHost,
                         NSURLErrorCannotConnectToHost].contains(nsError.code)
        let paymentError = NIPaymentError(category: isOffline ? .network : .provider,
                                          message: error.localizedDescription,
                                          paymentMethod: Self.methodName)
        // Never having reached KNET's site means the payer could not have authorised anything, so
        // the order is untouched. Once on KNET's site an attempt may be in flight, so the order is
        // read once: paid ends the payment, anything still payable goes
        // back to the payment page for another try. Polling a PENDING payment would only time out.
        if didReachKnetHost {
            verifyBeforeLeaving()
        } else {
            dispatch(.couldNotStart(paymentError))
        }
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
