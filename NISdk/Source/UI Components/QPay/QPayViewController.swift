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
    private var didStartRefetch = false

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
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

        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        print("[QPay] decidePolicy method=\(navigationAction.request.httpMethod ?? "?") url=\(url?.absoluteString ?? "nil")")
        // Mark when the gateway hops through our backend's accept URL — backend processes the
        // result there. We allow the navigation so the backend can update order state, then on
        // the next didFinish we refetch the order and report to the host app.
        if let path = url?.path, path.contains("/qpay/accept") {
            print("[QPay] callback URL seen — letting it through; will refetch order on next didFinish")
            sawAcceptCallback = true
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("[QPay] didStartProvisional url=\(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("[QPay] didReceiveServerRedirect url=\(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("[QPay] didCommit url=\(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[QPay] didFinish url=\(webView.url?.absoluteString ?? "nil")")
        activityIndicator.stopAnimating()
        if sawAcceptCallback && !didStartRefetch {
            didStartRefetch = true
            print("[QPay] post-callback didFinish → refetching order")
            refetchOrderAndDispatch()
            return
        }
        // Probe the loaded page to see why it renders blank.
        webView.evaluateJavaScript("document.title") { value, _ in
            print("[QPay] document.title=\(value ?? "<nil>")")
        }
        webView.evaluateJavaScript("document.body ? document.body.innerText.substring(0, 1500) : '<no body>'") { value, _ in
            print("[QPay] body.innerText[0:1500]=\(value ?? "<nil>")")
        }
        webView.evaluateJavaScript("document.body ? document.body.children.length : -1") { value, _ in
            print("[QPay] body.children.length=\(value ?? "<nil>")")
        }
        webView.evaluateJavaScript("document.getElementById('root') ? document.getElementById('root').innerHTML.length : -1") { value, _ in
            print("[QPay] #root innerHTML length=\(value ?? "<nil>")")
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        dispatch(.failed)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[QPay] didFailProvisional error=\(error.localizedDescription)")
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
