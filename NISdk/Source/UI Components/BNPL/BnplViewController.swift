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
        /// The payer landed back on our return address, but without our marker to say how it went.
        /// Providers that rebuild the query from their own form fields — Tabby's hosted page
        /// submits a GET form carrying only `code`, `payment_method` and `payment_id` — drop it.
        /// The payer has still returned, so the payment is finalised and the order decides.
        case unknown
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

    /// Stable identity for the SDK's own website data store, so every checkout reuses one store
    /// rather than creating a new one — and a new directory on disk — each time.
    private static let checkoutStoreIdentifier = UUID(uuidString: "7F2C9E14-3B6A-4D58-9C01-4E7A1D3B85F2")!

    /// The website data store the hosted checkout runs on.
    ///
    /// It has to be **persistent**. Apple Pay inside the provider's own page is Apple Pay JS, and
    /// WebKit will not run an `ApplePaySession` in an ephemeral store: the sheet appears and closes
    /// again immediately, which is what a payer sees as Apple Pay flashing inside Tamara. This was
    /// `.nonPersistent()`, which is why it never worked here while the same page works in Safari.
    ///
    /// It also has to stay out of the app's own store, so an abandoned checkout never signs the
    /// next payer in — both providers keep the shopper logged in otherwise. iOS 17 gives exactly
    /// that: a named store, persistent but separate. Below 17 there is no such API, so the default
    /// store is used and the provider's own data is cleared before each checkout instead — that
    /// gives up separation from the host app, but a working Apple Pay is worth more than an
    /// isolation guarantee the payer never sees.
    private static func checkoutDataStore() -> WKWebsiteDataStore {
        if #available(iOS 17.0, *) {
            return WKWebsiteDataStore(forIdentifier: checkoutStoreIdentifier)
        }
        return .default()
    }

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = BnplViewController.checkoutDataStore()
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
        // No Cancel item: the providers render their own close control on every page of the
        // checkout, and it routes through their cancel URL — which the SDK turns into
        // `cancelledOnProvider`, returning the payer to the payment page with their other methods
        // intact. A second way out would sit beside it doing the same job less well, because ours
        // cannot tell the provider the payer walked away.
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
            // A 401 is the payment session's token having expired, not this provider failing.
            // Every other method on the page authenticates with the same token, so returning the
            // payer to choose another walks them into the same failure — the payment ends instead.
            if statusCode == 401 {
                DispatchQueue.main.async {
                    // Reported as `.configuration`: retrying this order cannot help, which is
                    // what that category means. A category of its own would read better but would
                    // break every merchant's exhaustive switch — the demo app's included.
                    self.dispatch(.failed(NIPaymentError(
                        category: .configuration,
                        message: "The payment session has expired. Start a new order to pay.",
                        paymentMethod: self.provider.methodName)))
                }
                return
            }
            // A transport error means the request never got an answer; another 4xx means the
            // gateway refused this order, which is the integration's problem and will not come
            // right on a retry. A 5xx is the gateway or the provider failing on their own terms.
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
            // The store is persistent now, so the sign-in an abandoned checkout leaves behind would
            // carry into the next payer's order. Clearing the provider's own data first is what
            // replaces the clean slate the ephemeral store used to give.
            self.clearProviderData(for: url) {
                self.webView.load(URLRequest(url: url))
            }
        }
    }

    /// Clears the provider's stored data — cookies, storage, caches — before a checkout starts.
    /// Scoped to the provider's own host so nothing else in the store is touched.
    private func clearProviderData(for url: URL, completion: @escaping () -> Void) {
        guard let host = url.host else {
            completion()
            return
        }
        let store = webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: types) { records in
            let matching = records.filter { host == $0.displayName || host.hasSuffix(".\($0.displayName)") }
            guard !matching.isEmpty else {
                completion()
                return
            }
            store.removeData(ofTypes: types, for: matching) {
                completion()
            }
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

    /// Scheme, host, port and path of a URL — what identifies a return address. The query cannot be
    /// part of it, because the providers append their own parameters to whatever they are given.
    private func originAndPath(_ url: URL?) -> String? {
        guard let url = url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased() else { return nil }
        let port = components.port.map { ":\($0)" } ?? ""
        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        return "\(scheme)://\(host)\(port)\(path)"
    }

    /// The addresses we asked the provider to send the payer back to.
    private lazy var returnTargets: Set<String> = {
        Set([args.successUrl, args.cancelUrl, args.failureUrl]
            .compactMap { originAndPath(URL(string: $0)) })
    }()

    /// Which return URL, if any, a navigation is heading to.
    ///
    /// Both halves matter. The navigation has to be going to one of the addresses we nominated, and
    /// it has to carry our marker. Matching on the marker alone ends the checkout the instant it
    /// opens: the gateway pastes our return URLs into the provider's checkout URL **without
    /// encoding them**, so the checkout page's own address arrives carrying `ni_sdk_result`, and
    /// the payer never sees the page they were sent to. Matching on the address alone cannot tell
    /// success from cancel.
    private func returnLeg(for url: URL?) -> ReturnLeg? {
        guard let url = url,
              let target = originAndPath(url),
              returnTargets.contains(target) else { return nil }
        let marker = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == BnplInitArgs.resultParam })?.value
        switch marker {
        case "success": return .success
        case "cancel": return .cancel
        case "failure": return .failure
        // Arriving at an address we nominated is itself the signal that the payer came back. Only
        // the marker can distinguish a cancel, so without it the payment is finalised and the order
        // has the final say — which it does in every other case anyway.
        default: return .unknown
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
        print("\(provider.methodName): navigating to \(redactUrlForLog(url))")
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
        print("\(provider.methodName): server redirect to \(redactUrlForLog(webView.url))")
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
