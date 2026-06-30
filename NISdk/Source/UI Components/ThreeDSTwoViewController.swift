//
//  ThreeDSTwoViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import WebKit
import os.log

class ThreeDSTwoViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView = {
        // Some ACS challenge pages open the OTP form in a popup (window.open /
        // target="_blank"). Allow script-driven windows so they aren't dropped;
        // the WKUIDelegate below renders them inline.
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        let wk = WKWebView(frame: .zero, configuration: configuration)
        return wk
    }()
    private var hasInitialisedRequest: Bool = false
    private var fingerPrintCompleted: Bool = false
    
    private var completionHandler: (Bool) -> Void
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var transactionService: TransactionService
    private var accessToken: String
    private var paymentResponse: PaymentResponse
    private var frictionlessTimer: Timer?
    // Challenge (ACS) load tracking. The ACS page is loaded into the same web
    // view; if it stalls or fails, nothing here used to surface an error, so the
    // UI hung until the server-side 3DS timeout (~11 min). These guard against
    // that.
    private var challengeLoadTimer: Timer?
    private var challengeStarted: Bool = false
    private var challengeRendered: Bool = false
    private var hasCompleted: Bool = false
    // Set once the challenge has finished and the result is being resolved via the
    // challenge-response API call. After this point the ACS web view is torn down /
    // redirected, so any further navigation failure is irrelevant and must never
    // override the real result.
    private var completionInitiated: Bool = false
    // ACS challenge URL of the in-flight challenge, retained only for masked
    // diagnostic logging. Never surfaced to the customer-facing failure message.
    private var challengeAcsUrl: String?
    // Max time to wait for the ACS challenge page to render its first content
    // before failing fast. If the ACS/Cardinal page does not load or render
    // within this window the flow is terminated with THREE_DS_ACS_LOAD_TIMEOUT,
    // instead of letting the customer wait for the server-side 3DS timeout (~11 min).
    private let challengeLoadTimeout: TimeInterval = 30.0
    // Overall wall-clock backstop for the entire 3DS session. Unlike the
    // challengeLoadTimer (which only guards the ACS page's first render and is
    // cancelled once it renders), this timer runs for the whole flow and
    // guarantees a merchant callback even if a network/JS closure never fires or
    // the customer stalls on the challenge — the "no callback / ~10 min" hang.
    private var sessionTimer: Timer?
    private let sessionTimeout: TimeInterval = NISdk.sharedInstance.threeDSSessionTimeout
    // Reports a stable SDK error code (see `ThreeDSErrorCode`) when the challenge
    // is terminated by the SDK. Set by the presenter so the merchant gets a clear
    // failure reason; the normal pass/fail result still flows via completionHandler.
    var onSDKFailure: ((String) -> Void)?
    var paypageLink: String
    
    private var authorizationLabel: UILabel {
        let authLabel = UILabel()
        authLabel.text = "Authenticating using 3DS".localized
        return authLabel
    }
    private let vStack = UIStackView()
    
    init(with paymentResponse: PaymentResponse, accessToken: String,
         transactionService: TransactionServiceAdapter, completion: @escaping (Bool) -> Void) {
        self.completionHandler = completion
        self.transactionService = transactionService
        self.accessToken = accessToken
        self.paypageLink = ""
        self.activityIndicator.color = .gray
        self.paymentResponse = paymentResponse
        activityIndicator.hidesWhenStopped = true
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startSessionBackstop()
        setupVCSubviews()
        initWebView()
    }

    // Guarantees the merchant always receives a callback: if the whole 3DS flow
    // stalls (hung network/JS closure, or the customer never finishes the
    // challenge), this fires and terminates with THREE_DS_TIMEOUT instead of
    // leaving the integration without a result until the server-side timeout.
    private func startSessionBackstop() {
        guard sessionTimeout > 0 else { return }
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(withTimeInterval: self.sessionTimeout, repeats: false) { [weak self] timer in
                timer.invalidate()
                guard let self = self else { return }
                os_log("[NISdk] 3DS session — exceeded %{public}.0fs wall-clock cap, terminating (%{public}@)",
                       log: NISdkLogger.payment, type: .error, self.sessionTimeout, ThreeDSErrorCode.threeDSTimeout)
                self.completeOnce(withSDKError: true, errorCode: ThreeDSErrorCode.threeDSTimeout)
            }
            RunLoop.current.add(self.sessionTimer!, forMode: .common)
        }
    }
    
    private func setupVCSubviews() {
        vStack.addArrangedSubview(authorizationLabel)
        vStack.addArrangedSubview(activityIndicator)
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .center
        
        view.addSubview(vStack)
        vStack.anchor(top: nil,
                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                      bottom: nil,
                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                      padding: .zero,
                      size: CGSize(width: 0, height: 100))
        
        vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.backgroundColor = .white
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        webView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                       leading: view.safeAreaLayoutGuide.leadingAnchor,
                       bottom: view.safeAreaLayoutGuide.bottomAnchor,
                       trailing: view.safeAreaLayoutGuide.trailingAnchor)
        
        view.addSubview(vStack)
    }
    
    private func showActivityIndicator() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4,
                           animations: { self.webView.alpha = 0; self.vStack.alpha = 1 },
                           completion: { _ in self.activityIndicator.startAnimating()})
        }
    }
    
    private func hideActivityIndicator() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4,
                           animations: { self.webView.alpha = 1; self.vStack.alpha = 0 },
                           completion: { _ in self.activityIndicator.stopAnimating()})
        }
    }
    
    private func initWebView() {
        if let threeDSServerTransID = paymentResponse.threeDSTwoConfig?.threeDSServerTransID,
           let threeDSMethodNotificationURL = paymentResponse.threeDSMethodNotificationURL,
           let threeDSMethodData = paymentResponse.threeDSMethodData,
           let threeDSMethodURL = paymentResponse.threeDSTwoConfig?.threeDSMethodURL,
           let url = URL(string: threeDSMethodURL) {
            // Adding this check to prevent multiple requests
            if(!hasInitialisedRequest) {
                hasInitialisedRequest = true
                var request = URLRequest(url: url)
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.httpBody   = "threeDSServerTransID=\(threeDSServerTransID.encodeAsURL())&threeDSMethodNotificationURL=\(threeDSMethodNotificationURL.encodeAsURL())&threeDSMethodData=\(threeDSMethodData.encodeAsURL())".data(using: .utf8)

                webView.load(request)
                showActivityIndicator()
                self.frictionlessTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) {
                    timer in
                    timer.invalidate()
                    // frictionless has timedout. Proceed to Challenge
                    self.webView.stopLoading()
                    self.webView.load(URLRequest(url: URL(string: "about:blank")!))
                    self.fingerPrintCompleted = true
                    self.onCompleteFingerPrint(threeDSCompInd: "N")
                }
                RunLoop.current.add(self.frictionlessTimer!, forMode: .common)
            }
        } else {
            // No method data and url found, continue to challenge
            self.fingerPrintCompleted = true
            onCompleteFingerPrint(threeDSCompInd: "U")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.parent?.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: WKNavigationDelegate delegation methods
    // Gets called everytime the url is loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if(fingerPrintCompleted) {
            hideActivityIndicator()
        }
        if challengeStarted, !challengeRendered {
            // ACS challenge page rendered its first content — cancel the load
            // watchdog and let the customer complete the challenge at their pace.
            challengeRendered = true
            challengeLoadTimer?.invalidate()
        }
        if let url = webView.url?.absoluteString {
            if(url.contains("/3ds2/method/notification")) {
                handleThreeDSTwoStageCompletion()
            }
        }
    }

    // MARK: WKUIDelegate — ACS challenge pages frequently open the OTP form in a
    // new window (window.open / target="_blank") or drive the flow via JS
    // dialogs. With no WKUIDelegate, WKWebView silently drops both and the
    // challenge appears blank/stuck until the server-side 3DS timeout.

    // Render new-window / popup navigations inline in the same web view.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

    // MARK: ACS / challenge navigation failure handling
    // The 3DS1 controller already does this; the 3DS2 controller did not, which
    // is why a failed/stalled ACS page hung until the server-side 3DS timeout.

    // Page failed before any content was committed (TLS, DNS, reset, blocked nav).
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleChallengeNavigationFailure(error)
    }

    // Page failed after it started rendering.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleChallengeNavigationFailure(error)
    }

    // Web content process was terminated (e.g. memory pressure). Reload the
    // current ACS request once so the challenge can still render.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if challengeStarted, !challengeRendered, let url = webView.url {
            webView.load(URLRequest(url: url))
        }
    }

    private func handleChallengeNavigationFailure(_ error: Error) {
        let nsError = error as NSError
        // Ignore cancellations we trigger ourselves via decisionHandler(.cancel).
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { return }
        // WebKit surfaces a navigation that we cancel or supersede from a policy
        // decision (the ACS posting back to the challenge-notification /
        // urn:payment: URL, which we intercept and reload) as "frame load
        // interrupted" (WebKitErrorFrameLoadInterruptedByPolicyChange = 102). That
        // is the normal end-of-challenge signal, not an ACS load failure — treating
        // it as fatal raced ahead of the real challenge-response result and failed
        // otherwise-successful payments.
        if nsError.domain == "WebKitErrorDomain", nsError.code == 102 { return }
        // Once the challenge has finished and the result is being resolved via the
        // challenge-response call, any further navigation failure is irrelevant.
        if completionInitiated { return }
        // Failures during the fingerprint/method phase are handled by the
        // frictionless timer; only surface failures once the challenge starts.
        guard challengeStarted else { return }
        os_log("[NISdk] 3DS challenge — ACS navigation failed (%{public}@): %{public}@. ACS: %{public}@",
               log: NISdkLogger.payment, type: .error,
               ThreeDSErrorCode.acsLoadFailed, nsError.localizedDescription,
               maskedAcsUrl(challengeAcsUrl))
        completeOnce(withSDKError: true, errorCode: ThreeDSErrorCode.acsLoadFailed)
    }

    // Redacts the ACS URL for logging: keeps scheme + host (useful for
    // diagnostics) but strips the path and query, which carry the CReq token and
    // other sensitive challenge parameters. The full URL is never logged or shown.
    private func maskedAcsUrl(_ urlString: String?) -> String {
        guard let urlString = urlString else { return "<none>" }
        guard let components = URLComponents(string: urlString),
              let host = components.host else { return "<redacted>" }
        let scheme = components.scheme ?? "https"
        return "\(scheme)://\(host)/<redacted>"
    }

    private func startChallengeLoadWatchdog() {
        DispatchQueue.main.async {
            self.challengeLoadTimer?.invalidate()
            self.challengeLoadTimer = Timer.scheduledTimer(withTimeInterval: self.challengeLoadTimeout, repeats: false) { [weak self] timer in
                timer.invalidate()
                guard let self = self else { return }
                if !self.challengeRendered {
                    // ACS challenge page never rendered within challengeLoadTimeout —
                    // fail fast instead of letting the customer wait for the
                    // server-side 3DS timeout.
                    os_log("[NISdk] 3DS challenge — ACS page did not render within %{public}.0fs, terminating (%{public}@). ACS: %{public}@",
                           log: NISdkLogger.payment, type: .error,
                           self.challengeLoadTimeout, ThreeDSErrorCode.acsLoadTimeout,
                           self.maskedAcsUrl(self.challengeAcsUrl))
                    self.completeOnce(withSDKError: true, errorCode: ThreeDSErrorCode.acsLoadTimeout)
                }
            }
            RunLoop.current.add(self.challengeLoadTimer!, forMode: .common)
        }
    }

    // Single guarded exit so failure paths never double-complete and always
    // tear down timers and stop the web view. When an `errorCode` is supplied it
    // is reported to the presenter (and on to the merchant) as a clear failure
    // reason before the normal pass/fail result is delivered.
    private func completeOnce(withSDKError hasSDKError: Bool, errorCode: String? = nil) {
        DispatchQueue.main.async {
            if self.hasCompleted { return }
            self.hasCompleted = true
            self.frictionlessTimer?.invalidate()
            self.challengeLoadTimer?.invalidate()
            self.sessionTimer?.invalidate()
            self.webView.stopLoading()
            if let errorCode = errorCode {
                self.onSDKFailure?(errorCode)
            }
            self.completionHandler(hasSDKError)
        }
    }
    
    // Gets called after 3ds is performed and a 302 redirect is received from txn service
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            if(url.contains("/3ds2/method/notification")) {
                handleThreeDSTwoStageCompletion()
            }
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let url = navigationResponse.response.url?.absoluteString {
            if url.contains("/3ds2/method/notification") {
                decisionHandler(.cancel)
                handleThreeDSTwoStageCompletion()
                return
            }
        }

        decisionHandler(.allow)
    }

    @available(iOS 13.0, *)
    private func webView(_ webView: WKWebView, didReceive response: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let httpResponse = response.response as? HTTPURLResponse {
            if httpResponse.statusCode == 405 {

                let errorHTML = """
                <html>
                <head><title>Error</title></head>
                <body>
                    <h1>Redirecting...</h1>
                </body>
                </html>
                """
                webView.loadHTMLString(errorHTML, baseURL: nil)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }


    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {

        preferences.preferredContentMode = .mobile

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow, preferences)
            return
        }

        let urlString = url.absoluteString

        if urlString.contains("urn:payment:") {
            decisionHandler(.cancel, preferences)

            let trimmedURLString = urlString.replacingOccurrences(of: "urn:payment:", with: "")

            if let fixedURL = URL(string: trimmedURLString) {
                let fixedRequest = URLRequest(url: fixedURL)
                webView.load(fixedRequest)
            }

            handleThreeDSTwoStageCompletion()
            return
        }

        decisionHandler(.allow, preferences)
    }
    
    func handleThreeDSTwoStageCompletion() {
        if(!fingerPrintCompleted) {
            fingerPrintCompleted = true
            onCompleteFingerPrint(threeDSCompInd: "Y")
        } else {
            // Challenge is completed
            completionInitiated = true
            challengeLoadTimer?.invalidate()
            showActivityIndicator()
            guard let threeDSTwoChallengeResponseURL = paymentResponse.paymentLinks?.threeDSTwoChallengeResponseURL else {
                self.completeOnce(withSDKError: true)
                return
            }
            transactionService.postThreeDSTwoChallengeResponse(for: paymentResponse, using: threeDSTwoChallengeResponseURL) {
                data, response, error in
                self.completeOnce(withSDKError: false)
            }
        }
    }
    
    func onCompleteFingerPrint(threeDSCompInd: String) {
        self.frictionlessTimer?.invalidate()
        guard let authenticationsUrl = paymentResponse.paymentLinks?.threeDSTwoAuthenticationURL else {
            self.completeOnce(withSDKError: true)
            return
        }
        let browserDataJS = "browserLanguage: window.navigator.language," +
        "browserJavaEnabled: window.navigator.javaEnabled ? window.navigator.javaEnabled() : false," +
        "browserColorDepth: window.screen.colorDepth.toString()," +
        "browserScreenHeight: window.screen.height.toString()," +
        "browserScreenWidth: window.screen.width.toString()," +
        "browserTZ: new Date().getTimezoneOffset().toString()," +
        "browserUserAgent: window.navigator.userAgent"
        self.webView.evaluateJavaScript("(function(){ return ({ \(browserDataJS) }); })()") { (result, error) in
            guard let result = result else {
                self.completeOnce(withSDKError: true)
                return
            }
            if(error == nil) {
                var browserInfo: BrowserInfo? = nil
                do {
                    let data = try JSONSerialization.data(withJSONObject: result, options: [])
                    browserInfo = try JSONDecoder().decode(BrowserInfo.self, from: data)
                } catch {
                    // Could not deserialise browser info
                    self.completeOnce(withSDKError: true)
                    return
                }
                _ = browserInfo?.with(browserAcceptHeader:  "application/json, text/plain, */*")
                _ = browserInfo?.with(browserJavascriptEnabled: true)
                _ = browserInfo?.with(challengeWindowSize: "05")
                guard let browserInfo = browserInfo else {
                    // browser info null
                    self.completeOnce(withSDKError: true)
                    return
                }
                var notificationUrl = self.paymentResponse.threeDSMethodNotificationURL
                
                self.transactionService.getPayerIp(with: self.getIpUrl(
                    stringVal: self.paymentResponse.paymentLinks!.threeDSTwoAuthenticationURL!,
                    outletRef: self.paymentResponse.outletId!,
                    orderRef: self.paymentResponse.orderReference!,
                    paymentRef: self.paymentResponse._id!,
                    paypageLink: self.paypageLink),
                                                   using: self.accessToken,
                                                   on: { payerIPData, _, _ in
                    
                    if (notificationUrl == nil) {
                        let authUrl = self.paymentResponse.paymentLinks!.threeDSTwoAuthenticationURL!
                        let notificationUrlPath = "/api/outlets/\(self.paymentResponse.outletId!)/orders/\(self.paymentResponse.orderReference!)" +
                                                                      "/payments/\(self.paymentResponse.reference)/3ds2/method/notification"
                        notificationUrl = self.getNotificationUrl(stringVal: authenticationsUrl, slug: notificationUrlPath, paymentLink: (self.paymentResponse.paymentLinks?.paymentLink)!)
                    }
                    guard let payerIPData = payerIPData else {
                        // Unable to get IP address of payer
                        self.completeOnce(withSDKError: true)
                        return
                    }
                    var payerIp: String? = nil
                    do {
                        let payerIpDict: [String: String] = try JSONDecoder().decode([String: String].self, from: payerIPData)
                        payerIp = payerIpDict["requesterIp"]
                    } catch {
                        // Unable to get payer Ip address from decoded response
                        self.completeOnce(withSDKError: true)
                        return
                    }
                    guard let payerIp = payerIp else {
                        self.completeOnce(withSDKError: true)
                        return
                    }
                    
                    let _ = browserInfo.with(browserIP: payerIp)
                    let threeDSAuthenticationsRequest = ThreeDSAuthenticationsRequest()
                        .with(threeDSCompInd: threeDSCompInd)
                        .with(browserInfo: browserInfo)
                        .with(notificationUrl: notificationUrl!)
                    self.postAuthentications(
                        threeDSAuthenticationsRequest: threeDSAuthenticationsRequest,
                        authenticationsUrl: authenticationsUrl)
                })
            } else {
                // Could not get browser info
                self.completeOnce(withSDKError: true)
            }
        }
    }
    
    func postAuthentications(threeDSAuthenticationsRequest: ThreeDSAuthenticationsRequest, authenticationsUrl: String) {
        self.transactionService.postThreeDSAuthentications(
            for: self.paymentResponse,
            with: threeDSAuthenticationsRequest,
            using: authenticationsUrl,
            on: { authenticationsData, _, er in
                // authentications done
                guard let authenticationsData = authenticationsData else {
                    // unable to parse data
                    self.completeOnce(withSDKError: true)
                    return
                }
                
                guard let threeDSTwoAuthenticationsResponse = try? JSONDecoder().decode(ThreeDSTwoAuthenticationsResponse.self, from: authenticationsData) else {
                    // unable to decode threeDSTwoAuthenticationsResponse
                    self.completeOnce(withSDKError: true)
                    return
                }
                
                if(threeDSTwoAuthenticationsResponse.state == "FAILED") {
                    // 3ds Failed something went wrong
                    self.completeOnce(withSDKError: true)
                    return
                    
                }
                
                guard let transStatus = threeDSTwoAuthenticationsResponse.threeDSTwo?.transStatus else {
                    // no transStatus found
                    self.completeOnce(withSDKError: true)
                    return
                }
                
                switch(transStatus) {
                case "C":
                    // Challenge flow
                    // Open Challenge frame
                    if let base64EncodedCReq = threeDSTwoAuthenticationsResponse.threeDSTwo?.base64EncodedCReq,
                       let acsUrlString = threeDSTwoAuthenticationsResponse.threeDSTwo?.acsURL,
                       let acsURL = URL(string: acsUrlString){
                        var request = URLRequest(url: acsURL)
                        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        request.httpMethod = "POST"
                        request.httpBody   = "creq=\(base64EncodedCReq.encodeAsURL())".data(using: .utf8)
                        DispatchQueue.main.async {
                            self.challengeStarted = true
                            self.challengeAcsUrl = acsUrlString
                            os_log("[NISdk] 3DS challenge — loading ACS page: %{public}@ (timeout %{public}.0fs)",
                                   log: NISdkLogger.payment, type: .info,
                                   self.maskedAcsUrl(acsUrlString), self.challengeLoadTimeout)
                            self.startChallengeLoadWatchdog()
                            self.webView.load(request)
                        }
                    } else {
                        // Unable to obtain base64EncodedCReq and acsURL
                        self.completeOnce(withSDKError: true)
                    }
                    break
                default:
                    self.completeOnce(withSDKError: false)
                    break
                }
            })
    }
}

extension ThreeDSTwoViewController {
    private func getIpUrl(stringVal: String, outletRef: String, orderRef: String, paymentRef: String, paypageLink: String) -> String {
        let urlHost = URL(string: paypageLink)?.host ?? ""
        let slug =
        "/api/outlets/\(outletRef)/orders/\(orderRef)/payments/\(paymentRef)/3ds2/requester-ip"
        if (stringVal.localizedCaseInsensitiveContains("-uat") ||
            stringVal.localizedCaseInsensitiveContains("sandbox")
        ) {
            return "https://\(urlHost)\(slug)"
        }
        if (stringVal.localizedCaseInsensitiveContains("-dev")) {
            return "https://\(urlHost)\(slug)"
        }
        return "https://\(urlHost)\(slug)"
    }

    private func getNotificationUrl(stringVal: String, slug: String, paymentLink: String) -> String {
        let urlHost = URL(string: paymentLink)?.host ?? ""
        if (stringVal.localizedCaseInsensitiveContains("-uat") ||
            stringVal.localizedCaseInsensitiveContains("sandbox")
        ) {
            return "https://\(urlHost)\(slug)"
        }
        if (stringVal.localizedCaseInsensitiveContains("-dev")) {
            return "https://\(urlHost)\(slug)"
        }
        return "https://\(urlHost)\(slug)"
    }
}

