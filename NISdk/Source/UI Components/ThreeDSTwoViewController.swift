//
//  ThreeDSTwoViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import os.log
import WebKit

class ThreeDSTwoViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView = {
        let wk = WKWebView()
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
        setupVCSubviews()
        initWebView()
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
                os_log("[NISdk] 3DS v2 — fingerprint phase: loading method URL: %{public}@", log: NISdkLogger.payment, type: .info, threeDSMethodURL)
                var request = URLRequest(url: url)
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.httpBody   = "threeDSServerTransID=\(threeDSServerTransID.encodeAsURL())&threeDSMethodNotificationURL=\(threeDSMethodNotificationURL.encodeAsURL())&threeDSMethodData=\(threeDSMethodData.encodeAsURL())".data(using: .utf8)

                webView.load(request)
                showActivityIndicator()
                self.frictionlessTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) {
                    timer in
                    timer.invalidate()
                    os_log("[NISdk] 3DS v2 — fingerprint timed out (10s), proceeding with compInd=N", log: NISdkLogger.payment, type: .info)
                    self.webView.stopLoading()
                    self.webView.load(URLRequest(url: URL(string: "about:blank")!))
                    self.fingerPrintCompleted = true
                    self.onCompleteFingerPrint(threeDSCompInd: "N")
                }
                RunLoop.current.add(self.frictionlessTimer!, forMode: .common)
            }
        } else {
            os_log("[NISdk] 3DS v2 — no method data/URL found, skipping fingerprint (compInd=U)", log: NISdkLogger.payment, type: .info)
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
        if let url = webView.url?.absoluteString {
            if(url.contains("/3ds2/method/notification")) {
                handleThreeDSTwoStageCompletion()
            }
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
            os_log("[NISdk] 3DS v2 — fingerprint notification received, compInd=Y", log: NISdkLogger.payment, type: .info)
            fingerPrintCompleted = true
            onCompleteFingerPrint(threeDSCompInd: "Y")
        } else {
            os_log("[NISdk] 3DS v2 — challenge completed, posting challenge response", log: NISdkLogger.payment, type: .info)
            showActivityIndicator()
            guard let threeDSTwoChallengeResponseURL = paymentResponse.paymentLinks?.threeDSTwoChallengeResponseURL else {
                os_log("[NISdk] 3DS v2 — missing challenge response URL, aborting", log: NISdkLogger.payment, type: .error)
                self.completionHandler(true)
                return
            }
            transactionService.postThreeDSTwoChallengeResponse(for: paymentResponse, using: threeDSTwoChallengeResponseURL) {
                data, response, error in
                os_log("[NISdk] 3DS v2 — challenge response posted", log: NISdkLogger.payment, type: .info)
                self.completionHandler(false)
            }
        }
    }

    func onCompleteFingerPrint(threeDSCompInd: String) {
        os_log("[NISdk] 3DS v2 — onCompleteFingerPrint compInd=%{public}@", log: NISdkLogger.payment, type: .info, threeDSCompInd)
        self.frictionlessTimer?.invalidate()
        guard let authenticationsUrl = paymentResponse.paymentLinks?.threeDSTwoAuthenticationURL else {
            os_log("[NISdk] 3DS v2 — missing authentication URL, aborting", log: NISdkLogger.payment, type: .error)
            self.completionHandler(true)
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
                os_log("[NISdk] 3DS v2 — JS evaluation returned nil result, aborting", log: NISdkLogger.payment, type: .error)
                self.completionHandler(true)
                return
            }
            if(error == nil) {
                var browserInfo: BrowserInfo? = nil
                do {
                    let data = try JSONSerialization.data(withJSONObject: result, options: [])
                    browserInfo = try JSONDecoder().decode(BrowserInfo.self, from: data)
                } catch {
                    os_log("[NISdk] 3DS v2 — failed to decode browser info: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                    self.completionHandler(true)
                    return
                }
                _ = browserInfo?.with(browserAcceptHeader:  "application/json, text/plain, */*")
                _ = browserInfo?.with(browserJavascriptEnabled: true)
                _ = browserInfo?.with(challengeWindowSize: "05")
                guard let browserInfo = browserInfo else {
                    os_log("[NISdk] 3DS v2 — browser info is nil after decode, aborting", log: NISdkLogger.payment, type: .error)
                    self.completionHandler(true)
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
                        os_log("[NISdk] 3DS v2 — failed to get payer IP address, aborting", log: NISdkLogger.payment, type: .error)
                        self.completionHandler(true)
                        return
                    }
                    var payerIp: String? = nil
                    do {
                        let payerIpDict: [String: String] = try JSONDecoder().decode([String: String].self, from: payerIPData)
                        payerIp = payerIpDict["requesterIp"]
                    } catch {
                        os_log("[NISdk] 3DS v2 — failed to decode payer IP response: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                        self.completionHandler(true)
                        return
                    }
                    guard let payerIp = payerIp else {
                        os_log("[NISdk] 3DS v2 — requesterIp missing from payer IP response, aborting", log: NISdkLogger.payment, type: .error)
                        self.completionHandler(true)
                        return
                    }

                    os_log("[NISdk] 3DS v2 — browser info collected, posting authentications (compInd=%{public}@)", log: NISdkLogger.payment, type: .info, threeDSCompInd)
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
                os_log("[NISdk] 3DS v2 — JS evaluation error: %{public}@", log: NISdkLogger.payment, type: .error, error?.localizedDescription ?? "unknown")
                self.completionHandler(true)
            }
        }
    }

    func postAuthentications(threeDSAuthenticationsRequest: ThreeDSAuthenticationsRequest, authenticationsUrl: String) {
        os_log("[NISdk] 3DS v2 — postAuthentications → %{public}@", log: NISdkLogger.payment, type: .info, authenticationsUrl)
        self.transactionService.postThreeDSAuthentications(
            for: self.paymentResponse,
            with: threeDSAuthenticationsRequest,
            using: authenticationsUrl,
            on: { authenticationsData, _, er in
                guard let authenticationsData = authenticationsData else {
                    os_log("[NISdk] 3DS v2 — authentications response data is nil, aborting", log: NISdkLogger.payment, type: .error)
                    self.completionHandler(true)
                    return
                }

                guard let threeDSTwoAuthenticationsResponse = try? JSONDecoder().decode(ThreeDSTwoAuthenticationsResponse.self, from: authenticationsData) else {
                    os_log("[NISdk] 3DS v2 — failed to decode authentications response, aborting", log: NISdkLogger.payment, type: .error)
                    self.completionHandler(true)
                    return
                }

                os_log("[NISdk] 3DS v2 — authentications response state=%{public}@", log: NISdkLogger.payment, type: .info, threeDSTwoAuthenticationsResponse.state ?? "nil")

                if(threeDSTwoAuthenticationsResponse.state == "FAILED") {
                    os_log("[NISdk] 3DS v2 — authentication state FAILED, aborting", log: NISdkLogger.payment, type: .error)
                    self.completionHandler(true)
                    return
                }

                guard let transStatus = threeDSTwoAuthenticationsResponse.threeDSTwo?.transStatus else {
                    os_log("[NISdk] 3DS v2 — no transStatus in response, aborting", log: NISdkLogger.payment, type: .error)
                    self.completionHandler(true)
                    return
                }

                os_log("[NISdk] 3DS v2 — transStatus=%{public}@", log: NISdkLogger.payment, type: .info, transStatus)

                switch(transStatus) {
                case "C":
                    os_log("[NISdk] 3DS v2 — challenge flow: loading ACS challenge frame", log: NISdkLogger.payment, type: .info)
                    if let base64EncodedCReq = threeDSTwoAuthenticationsResponse.threeDSTwo?.base64EncodedCReq,
                       let acsUrlString = threeDSTwoAuthenticationsResponse.threeDSTwo?.acsURL,
                       let acsURL = URL(string: acsUrlString){
                        os_log("[NISdk] 3DS v2 — posting creq to ACS URL: %{public}@", log: NISdkLogger.payment, type: .info, acsUrlString)
                        var request = URLRequest(url: acsURL)
                        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        request.httpMethod = "POST"
                        request.httpBody   = "creq=\(base64EncodedCReq.encodeAsURL())".data(using: .utf8)
                        DispatchQueue.main.async {
                            self.webView.load(request)
                        }
                    } else {
                        os_log("[NISdk] 3DS v2 — missing base64EncodedCReq or acsURL for challenge, aborting", log: NISdkLogger.payment, type: .error)
                        self.completionHandler(true)
                    }
                    break
                default:
                    os_log("[NISdk] 3DS v2 — frictionless flow (transStatus=%{public}@), completing", log: NISdkLogger.payment, type: .info, transStatus)
                    self.completionHandler(false)
                    break
                }
            })
    }
}

extension ThreeDSTwoViewController {
    private func getIpUrl(stringVal: String, outletRef: String, orderRef: String, paymentRef: String, paypageLink: String) -> String {
        // The payment `_id` is returned as a URN (e.g. "urn:payment:<uuid>") in the saved-card /
        // merchant-initiated 3DS2 flow. Left in place it produces an invalid request path
        // (".../payments/urn:payment:<uuid>/3ds2/requester-ip"), so strip the prefix first.
        let cleanPaymentRef = paymentRef.replacingOccurrences(of: "urn:payment:", with: "")

        // `paypageLink` is absent in some saved-card / merchant-initiated order responses, which
        // previously left an empty host ("https:///api/...") that fails with "Could not connect to
        // the server". Fall back to deriving the paypage host from the authentication URL host.
        let fallbackHost = URL(string: stringVal)?.host?.replacingOccurrences(of: "api-gateway", with: "paypage")
        let urlHost = URL(string: paypageLink)?.host ?? fallbackHost ?? ""

        let slug = "/api/outlets/\(outletRef)/orders/\(orderRef)/payments/\(cleanPaymentRef)/3ds2/requester-ip"
        let ipUrl = "https://\(urlHost)\(slug)"
        os_log("[NISdk] 3DS v2 — requester-ip URL resolved: %{public}@", log: NISdkLogger.payment, type: .info, ipUrl)
        return ipUrl
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
