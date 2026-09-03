//
//  QPayViewController.swift
//  NISdk
//

import Foundation
import UIKit
import WebKit

class QPayViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private let args: QPayInitArgs
    private let onCompletion: (QPayPaymentStatus) -> Void
    private let transactionService: TransactionService

    private let accessToken: String
    private var didDispatchResult = false
    private var sawAcceptCallback = false
    private var sawCancelCallback = false
    private var didStartRefetch = false

    /// Pending "reveal the WebView" work. Each navigation hop cancels it and re-shows the cover,
    /// so intermediate redirect pages (incl. the brief broken-link/error page) never get displayed.
    private var revealWorkItem: DispatchWorkItem?
    /// How long a page must stay put (no new navigation) before we reveal it. A redirect hop fires
    /// the next provisional navigation well within this window, keeping the cover up.
    private static let revealDebounce: TimeInterval = 0.45

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        // Isolate this payment's web session. The paypage stores `paypage_browser_session_id` and
        // `paypage_used_auth_codes` in localStorage (and the gateway sets session cookies). With the
        // default *persistent* data store that state survives across orders, so after a failed
        // payment a brand-new order reuses the dead session → "your session has expired or marked as
        // invalid". A non-persistent store lives only for this view controller, so every order starts
        // with a clean session and nothing leaks to the next one.
        config.websiteDataStore = .nonPersistent()
        // Capture console.* and uncaught errors from QCB's JS so we can see what's happening.
        let userScript = """
        (function() {
          var send = function(level, args) {
            try {
              var msg = Array.prototype.map.call(args, function(a) {
                try { return typeof a === 'string' ? a : JSON.stringify(a); }
                catch (e) { return String(a); }
              }).join(' ');
              window.webkit.messageHandlers.qpayConsole.postMessage({ level: level, msg: msg });
            } catch (e) {}
          };
          ['log','warn','error','info'].forEach(function(level) {
            var orig = console[level];
            console[level] = function() { send(level, arguments); orig.apply(console, arguments); };
          });
          window.addEventListener('error', function(e) {
            send('uncaught', [(e.message || '') + ' @ ' + (e.filename || '') + ':' + (e.lineno || '')]);
          });
          window.addEventListener('unhandledrejection', function(e) {
            send('rejection', [String(e.reason || e)]);
          });
        })();
        """
        config.userContentController.add(self, name: "qpayConsole")
        config.userContentController.addUserScript(WKUserScript(source: userScript,
                                                                injectionTime: .atDocumentStart,
                                                                forMainFrameOnly: false))

        // Pin the viewport so QCB's hosted page doesn't auto-zoom when inputs receive focus.
        // Override any existing viewport meta and force inputs to ≥16px (iOS auto-zooms below that).
        let viewportScript = """
        (function() {
          function applyViewport() {
            var existing = document.querySelectorAll('meta[name="viewport"]');
            existing.forEach(function(m) { m.parentNode.removeChild(m); });
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no';
            (document.head || document.documentElement).appendChild(meta);

            var style = document.createElement('style');
            style.innerHTML = 'input, select, textarea, button { font-size: 16px !important; }';
            (document.head || document.documentElement).appendChild(style);
          }
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', applyViewport);
          } else {
            applyViewport();
          }
        })();
        """
        config.userContentController.addUserScript(WKUserScript(source: viewportScript,
                                                                injectionTime: .atDocumentEnd,
                                                                forMainFrameOnly: false))

        let wk = WKWebView(frame: .zero, configuration: config)
        wk.accessibilityIdentifier = "sdk_qpay_webview"
        wk.navigationDelegate = self
        wk.uiDelegate = self
        // Belt-and-braces: disable WKWebView's pinch-zoom so even if a page ignores the viewport
        // meta, the user can't zoom in/out.
        wk.scrollView.minimumZoomScale = 1.0
        wk.scrollView.maximumZoomScale = 1.0
        wk.scrollView.bouncesZoom = false
        return wk
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    /// Opaque view sitting *above* the WebView. While it's visible the user sees only a white
    /// screen + spinner, never whatever the WebView is rendering mid-redirect.
    private let coverView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.accessibilityIdentifier = "sdk_qpay_cover"
        return v
    }()

    init(args: QPayInitArgs,
         transactionService: TransactionService,
         accessToken: String,
         onCompletion: @escaping (QPayPaymentStatus) -> Void) {
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

        // Cover sits on top of the WebView and hides intermediate redirect pages.
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
        navigationItem.title = "QPay"
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
        transactionService.initQPay(with: args.qpayLink, using: accessToken) { [weak self] data, _, error in
            guard let self = self else { return }
            self.handleInitResponse(data: data, error: error)
        }
    }

    private func handleInitResponse(data: Data?, error: Error?) {
        guard error == nil, let data = data else {
            DispatchQueue.main.async { self.dispatch(.failed) }
            return
        }
        guard let response = try? JSONDecoder().decode(QPayInitResponse.self, from: data) else {
            DispatchQueue.main.async { self.dispatch(.failed) }
            return
        }
        if response.cancelled == true {
            DispatchQueue.main.async { self.dispatch(.cancelled) }
            return
        }
        // Auto-submit form, loaded with baseURL = paypage origin so the cross-origin POST to QCB
        // carries `Origin: https://paypage-sandbox.platform.network.ae` (whitelisted by QCB).
        guard let html = QPayFormBuilder.buildAutoSubmitHTML(response: response),
              let baseURL = URL(string: args.payPageOrigin) else {
            DispatchQueue.main.async { self.dispatch(.failed) }
            return
        }
        print("[QPay] Loading auto-submit form, baseURL=\(baseURL.absoluteString) action=\(response.redirectUri ?? "<nil>")")
        DispatchQueue.main.async {
            self.webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    private func refetchOrderAndDispatch() {
        activityIndicator.startAnimating()
        transactionService.getOrder(for: args.orderLink, using: accessToken) { [weak self] data, _, error in
            guard let self = self else { return }
            guard error == nil, let data = data,
                  let order = try? OrderResponse.decodeFrom(data: data) else {
                DispatchQueue.main.async { self.dispatch(.failed) }
                return
            }
            let state = order.embeddedData?.payment?.first?.state ?? ""
            let success = ["CAPTURED", "AUTHORISED", "PURCHASED", "VERIFIED", "POST_AUTH_REVIEW"]
                .contains(state)
            DispatchQueue.main.async {
                self.dispatch(success ? .success : .failed)
            }
        }
    }

    private func dispatch(_ status: QPayPaymentStatus) {
        guard !didDispatchResult else { return }
        didDispatchResult = true
        activityIndicator.stopAnimating()
        dismiss(animated: true) { [onCompletion] in
            onCompletion(status)
        }
    }

    @objc private func cancelTapped() {
        webView.stopLoading()
        dispatch(.cancelled)
    }

    // MARK: - Cover (hide intermediate redirect pages)

    /// Re-cover the WebView and cancel any pending reveal. Called at the start of every navigation
    /// hop so the user keeps seeing the spinner, not the page being loaded.
    private func showCover() {
        revealWorkItem?.cancel()
        revealWorkItem = nil
        coverView.isHidden = false
        activityIndicator.startAnimating()
    }

    /// Reveal the WebView, but only if no further navigation starts within `revealDebounce`.
    /// A redirect chain fires its next provisional navigation almost immediately, which calls
    /// `showCover()` and cancels this — so only a page that actually settles gets shown.
    private func scheduleReveal() {
        revealWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.coverView.isHidden = true
            self.qpayDebug("revealed settled page url=\(self.webView.url?.absoluteString ?? "nil")")
        }
        revealWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + QPayViewController.revealDebounce, execute: item)
    }

    // MARK: - Debug

    /// Timestamped trace so the exact sequence + origin of the brief flash page is captured.
    private func qpayDebug(_ msg: String) {
        let ts = String(format: "%.3f", Date().timeIntervalSince1970)
        print("[QPay][DEBUG \(ts)] \(msg)")
    }

    /// Snapshot what a page actually rendered — used to fingerprint the broken-link/error page.
    private func snapshotPage(_ tag: String) {
        let urlStr = webView.url?.absoluteString ?? "nil"
        webView.evaluateJavaScript("document.title") { [weak self] value, _ in
            self?.qpayDebug("\(tag) title=\(value ?? "<nil>") url=\(urlStr)")
        }
        webView.evaluateJavaScript("document.body ? document.body.innerText.substring(0, 300) : '<no body>'") { [weak self] value, _ in
            self?.qpayDebug("\(tag) bodyText[0:300]=\(value ?? "<nil>")")
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        print("[QPay] decidePolicy method=\(navigationAction.request.httpMethod ?? "?") url=\(url?.absoluteString ?? "nil")")
        if let path = url?.path {
            // QCB's user-cancel endpoint. When the payer taps cancel on the QCB hosted page the
            // WebView navigates here before it ever reaches our accept callback. Treat this hop as
            // a definitive user cancellation so we report cancelled rather than failed.
            if path.contains("/d3gw/cancel") {
                print("[QPay] QCB cancel URL seen — user canceled at gateway")
                sawCancelCallback = true
            }
            // Mark when the gateway hops through our backend's accept URL — backend processes the
            // result there. We allow the navigation so the backend can update order state, then on
            // the next didFinish we refetch the order and report to the host app.
            if path.contains("/qpay/accept") {
                print("[QPay] callback URL seen — letting it through; will refetch order on next didFinish")
                sawAcceptCallback = true
            }
        }
        decisionHandler(.allow)
    }

    /// Logs the HTTP status of every response. A 4xx/5xx here is the smoking gun for the
    /// broken-link/error page that briefly flashes — its URL is the page origin we're hunting.
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let http = navigationResponse.response as? HTTPURLResponse {
            let marker = (200..<400).contains(http.statusCode) ? "" : "  <-- NON-OK (likely the flash page)"
            qpayDebug("response status=\(http.statusCode) url=\(http.url?.absoluteString ?? "nil")\(marker)")
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        qpayDebug("didStartProvisional url=\(webView.url?.absoluteString ?? "nil")")
        // A new hop began — re-cover so the page being navigated to is never shown until it settles.
        showCover()
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        qpayDebug("didReceiveServerRedirect url=\(webView.url?.absoluteString ?? "nil")")
        showCover()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // didCommit = content starts rendering. This is the page that *would* flash; the cover is
        // hiding it. Snapshot it so we can see exactly what it is.
        qpayDebug("didCommit url=\(webView.url?.absoluteString ?? "nil")")
        snapshotPage("didCommit")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        qpayDebug("didFinish url=\(webView.url?.absoluteString ?? "nil")")
        // User canceled at the QCB gateway — report cancelled so the host app returns to the order
        // page instead of the payment-failed page. Checked before the accept branch: a cancel that
        // still reached /qpay/accept must not be refetched into a failed result.
        if sawCancelCallback && !didDispatchResult {
            print("[QPay] post-cancel didFinish → reporting cancelled")
            dispatch(.cancelled)
            return
        }
        if sawAcceptCallback && !didStartRefetch {
            didStartRefetch = true
            print("[QPay] post-callback didFinish → refetching order")
            refetchOrderAndDispatch()
            return
        }
        snapshotPage("didFinish")
        // Only reveal if this page settles (no further redirect within the debounce window).
        scheduleReveal()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        qpayDebug("didFail url=\(webView.url?.absoluteString ?? "nil") error=\(error.localizedDescription)")
        dispatch(.failed)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        qpayDebug("didFailProvisional url=\(webView.url?.absoluteString ?? "nil") error=\(error.localizedDescription)")
        dispatch(.failed)
    }

    // MARK: - WKUIDelegate (handle window.open by loading in same WebView)

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            print("[QPay] window.open intercepted url=\(url.absoluteString) — loading in same WebView")
            webView.load(navigationAction.request)
        }
        return nil
    }

    // MARK: - WKScriptMessageHandler (JS console + uncaught errors)

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "qpayConsole",
              let payload = message.body as? [String: Any],
              let level = payload["level"] as? String,
              let msg = payload["msg"] as? String else { return }
        print("[QPay JS \(level)] \(msg)")
    }
}
