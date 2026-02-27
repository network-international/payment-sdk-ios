//
//  ClickToPayViewController.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ClickToPayViewController: UIViewController {

    /// Shared process pool across all Click to Pay WebView instances.
    /// This ensures cookies and session data set by the Visa SDK's iframes
    /// are preserved across VC presentations within the same app session,
    /// which is required for "remember me" / skip-OTP recognition to work.
    private static let sharedProcessPool = WKProcessPool()

    private var webView: WKWebView!
    private var progressBar: UIActivityIndicatorView!
    private var sdkInitialized = false
    private var popupWebView: WKWebView?  // Popup for Mastercard SRC enrollment
    private var popupCleanupTimer: Timer?

    // Two-stage loading: navigate to a real HTTPS URL first (to establish proper origin),
    // then inject the HTML via document.write. loadHTMLString creates a null/opaque origin
    // which breaks the Visa SDK's postMessage-based DCF (Digital Card Facilitator) flow.
    private var pendingHtmlBase64: String?
    private var originEstablished = false

    private let clickToPayConfig: ClickToPayConfig
    private let clickToPayArgs: ClickToPayArgs
    private let orderReference: String?
    private let onCompletion: (ClickToPayStatus) -> Void

    private let transactionService = TransactionServiceAdapter()
    private let apiInteractor = ClickToPayApiInteractor()
    private var threeDSChildVC: UIViewController?
    private var orderPollRetryCount = 0
    private let orderPollMaxRetries = 15  // 15 retries × 2s = 30s max

    private var accessToken: String?
    private var paymentCookie: String?
    private var userEmail: String?

    // When true, shows the close (X) button in the nav bar even without userEmail.
    // Used when launched from the unified page (probe mode) so users can cancel.
    var showCloseButton = false

    // Base64 GIF data URI to inject into the HTML for lookup loading
    private var gifDataUri: String?
    // Base64 Visa logo data URI to inject into the HTML
    private var visaLogoDataUri: String?

    // Encryption keys and merchant config fetched from /vctp/config endpoint
    private var vctpKid: String?
    private var vctpPublicKey: String?
    private var vctpMerchantConfig: [String: Any]?  // acquirerMerchantId, merchantCountryCode, acquirerBins, mcc

    init(clickToPayConfig: ClickToPayConfig,
         clickToPayArgs: ClickToPayArgs,
         orderReference: String?,
         accessToken: String? = nil,
         paymentCookie: String? = nil,
         userEmail: String? = nil,
         onCompletion: @escaping (ClickToPayStatus) -> Void) {
        self.clickToPayConfig = clickToPayConfig
        self.clickToPayArgs = clickToPayArgs
        self.orderReference = orderReference
        self.accessToken = accessToken
        self.paymentCookie = paymentCookie
        self.userEmail = userEmail
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupProgressBar()
        setupWebView()
        setupNavigationBar()  // After WebView so floating close button is on top
        loadGifDataUri()
        loadVisaLogoDataUri()
        authorizeAndLoadHtml()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        if let email = userEmail, !email.isEmpty {
            // Pushed onto an existing nav stack (email flow) — use the system nav bar
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.navigationItem.title = nil

            if #available(iOS 13.0, *) {
                let xImage = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
                let closeButton = UIBarButtonItem(image: xImage, style: .plain,
                                                  target: self, action: #selector(cancelAction))
                closeButton.tintColor = UIColor(hexString: "#070707")
                navigationItem.rightBarButtonItem = closeButton
            } else {
                let closeButton = UIBarButtonItem(title: "✕", style: .plain,
                                                  target: self, action: #selector(cancelAction))
                closeButton.tintColor = UIColor(hexString: "#070707")
                navigationItem.rightBarButtonItem = closeButton
            }
            navigationItem.hidesBackButton = true
        } else if showCloseButton {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            addFloatingCloseButton()
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    private func addFloatingCloseButton() {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let xImage = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
            button.setImage(xImage, for: .normal)
        } else {
            button.setTitle("✕", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        }
        button.tintColor = UIColor(hexString: "#070707")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setupProgressBar() {
        if #available(iOS 13.0, *) {
            progressBar = UIActivityIndicatorView(style: .large)
        } else {
            progressBar = UIActivityIndicatorView(style: .whiteLarge)
        }
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.hidesWhenStopped = true
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBar.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        progressBar.startAnimating()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "clickToPayBridge")
        configuration.userContentController = contentController
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Use the default persistent data store so that Visa SRC SDK cookies
        // (including "remember me" / skip OTP tokens) survive between sessions.
        // We clear only sessionStorage (which holds stale Visa session tokens
        // that cause AUTH_INVALID errors) while keeping cookies and localStorage.
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        // Share the process pool so that cookies/session state set by the Visa
        // SDK's iframes persist across VC presentations within the same app session.
        configuration.processPool = ClickToPayViewController.sharedProcessPool
        clearStaleWebData()

        if #available(iOS 14.0, *) {
            let webPreferences = WKWebpagePreferences()
            webPreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = webPreferences
        } else {
            configuration.preferences.javaScriptEnabled = true
        }

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.bounces = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.bringSubviewToFront(progressBar)
    }

    /// Clear sessionStorage to remove stale per-session data.
    /// We intentionally keep localStorage because the Visa SDK stores
    /// "remember me" / skip-OTP recognition tokens there. AUTH_INVALID
    /// errors from stale session tokens are handled reactively via
    /// unbindAppInstance + retry in the JS error handlers.
    private func clearStaleWebData() {
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeSessionStorage
        ]
        WKWebsiteDataStore.default().removeData(
            ofTypes: dataTypes,
            modifiedSince: Date.distantPast,
            completionHandler: {}
        )
    }

    // MARK: - GIF Data URI

    /// Load the GIF from the bundle and convert to base64 data URI for injection into HTML
    private func loadGifDataUri() {
        let bundle = NISdk.sharedInstance.getBundle()
        var gifUrl: URL?

        if let path = bundle.path(forResource: "ctp_cards_loader", ofType: "gif") {
            gifUrl = URL(fileURLWithPath: path)
        }
        if gifUrl == nil, let path = Bundle(for: type(of: self)).path(forResource: "ctp_cards_loader", ofType: "gif") {
            gifUrl = URL(fileURLWithPath: path)
        }

        guard let url = gifUrl,
              let data = try? Data(contentsOf: url) else {
            return
        }

        let base64 = data.base64EncodedString()
        gifDataUri = "data:image/gif;base64,\(base64)"
    }

    /// Inject the GIF data URI into the HTML page so the lookup loading view can display it
    private func injectGifIntoHtml() {
        guard let dataUri = gifDataUri else { return }
        let escaped = dataUri.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("setLookupGif('\(escaped)')") { _, _ in }
    }

    // MARK: - Visa Logo Data URI

    /// Load the Visa logo from the bundle and convert to base64 data URI for injection into HTML
    private func loadVisaLogoDataUri() {
        let bundle = NISdk.sharedInstance.getBundle()
        guard let image = UIImage(named: "visalogo", in: bundle, compatibleWith: nil)
                ?? UIImage(named: "visalogo", in: Bundle(for: type(of: self)), compatibleWith: nil),
              let data = image.pngData() else {
            return
        }
        let base64 = data.base64EncodedString()
        visaLogoDataUri = "data:image/png;base64,\(base64)"
    }

    /// Inject the Visa logo data URI into the HTML page
    private func injectVisaLogoIntoHtml() {
        guard let dataUri = visaLogoDataUri else { return }
        let escaped = dataUri.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("setVisaLogo('\(escaped)')") { _, _ in }
    }

    // MARK: - Authorization

    private func authorizeAndLoadHtml() {
        // If tokens were already provided (e.g. from PaymentViewController which already authorized),
        // skip the authorization step and go straight to fetching vctp config then loading HTML
        if let existingToken = self.accessToken, !existingToken.isEmpty {
            if self.paymentCookie == nil || self.paymentCookie!.isEmpty {
                self.paymentCookie = ""
            }
            fetchVctpConfigAndLoadHtml()
            return
        }

        transactionService.authorizePayment(
            for: clickToPayArgs.authCode,
            using: clickToPayArgs.authUrl
        ) { [weak self] tokens in
            guard let self = self else { return }

            guard let accessToken = tokens["access-token"] else {
                self.finish(with: .failed)
                return
            }

            self.accessToken = accessToken
            let paymentToken = tokens["payment-token"] ?? ""
            self.paymentCookie = "payment-token=\(paymentToken)"

            self.fetchVctpConfigAndLoadHtml()
        }
    }

    // MARK: - VCTP Config (kid + publicKey for card encryption)

    /// Fetch the Click to Pay encryption config (kid, publicKey) from the backend,
    /// then load the HTML page. If the fetch fails, we still proceed (add card just won't work).
    private func fetchVctpConfigAndLoadHtml() {
        // If kid and publicKey are already provided in config, skip the API call
        if clickToPayConfig.kid != nil && clickToPayConfig.publicKey != nil {
            DispatchQueue.main.async {
                self.loadClickToPayHtml()
            }
            return
        }

        // Build the vctp/config URL from the pay page host
        guard let payPageHost = URL(string: clickToPayArgs.payPageUrl)?.host else {
            DispatchQueue.main.async {
                self.loadClickToPayHtml()
            }
            return
        }

        let vctpConfigUrl = "https://\(payPageHost)/api/outlets/\(clickToPayArgs.outletId)/vctp/config"

        var headers: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
            headers["Access-Token"] = token
        }
        if let cookie = paymentCookie, !cookie.isEmpty {
            headers["Cookie"] = cookie
            let parts = cookie.components(separatedBy: "=")
            if parts.count >= 2 {
                headers["Payment-Token"] = parts.dropFirst().joined(separator: "=")
            }
        }

        HTTPClient(url: vctpConfigUrl)?
            .withMethod(method: "GET")
            .withHeaders(headers: headers)
            .makeRequest(with: { [weak self] data, response, error in
                guard let self = self else { return }

                if let data = data,
                   let jsonObj = try? JSONSerialization.jsonObject(with: data),
                   let json = jsonObj as? [String: Any] {

                    if let kid = json["kid"] as? String {
                        self.vctpKid = kid
                    }
                    if let publicKey = json["publicKey"] as? String {
                        self.vctpPublicKey = publicKey
                    }
                    // Save merchant config fields for dpaTransactionOptions
                    var merchantConfig: [String: Any] = [:]
                    if let v = json["acquirerMerchantId"] as? String { merchantConfig["acquirerMerchantId"] = v }
                    if let v = json["merchantCountryCode"] as? String { merchantConfig["merchantCountryCode"] = v }
                    if let v = json["mcc"] { merchantConfig["mcc"] = v }
                    if let v = json["acquirerBins"] { merchantConfig["acquirerBins"] = v }
                    if !merchantConfig.isEmpty {
                        self.vctpMerchantConfig = merchantConfig
                    }
                }

                DispatchQueue.main.async {
                    self.loadClickToPayHtml()
                }
            })
    }

    // MARK: - Load HTML

    private func loadClickToPayHtml() {
        let bundle = NISdk.sharedInstance.getBundle()

        var htmlContent: String?

        if let htmlPath = bundle.path(forResource: "click_to_pay", ofType: "html") {
            htmlContent = try? String(contentsOfFile: htmlPath, encoding: .utf8)
        }

        if htmlContent == nil {
            if let htmlPath = Bundle(for: type(of: self)).path(forResource: "click_to_pay", ofType: "html") {
                htmlContent = try? String(contentsOfFile: htmlPath, encoding: .utf8)
            }
        }

        guard let html = htmlContent else {
            finish(with: .failed)
            return
        }

        // CRITICAL: We must NOT use loadHTMLString because it creates a null/opaque origin.
        // The Visa SDK's DCF (Digital Card Facilitator) uses postMessage to communicate
        // between an iframe at secure.checkout.visa.com and the parent window.
        // With a null origin, postMessage target origin validation fails, causing
        // "Target window is closed" errors and CARD_ADD_FAILED.
        //
        // Instead, we navigate to a real HTTPS URL on the merchant's pay page host
        // to establish a proper origin, then inject our HTML via document.write.
        // document.write replaces the page content but preserves the browsing context
        // and its HTTPS origin.

        guard let htmlData = html.data(using: .utf8) else {
            finish(with: .failed)
            return
        }
        pendingHtmlBase64 = htmlData.base64EncodedString()

        guard URL(string: clickToPayArgs.payPageUrl)?.host != nil else {
            webView.loadHTMLString(html, baseURL: URL(string: clickToPayArgs.payPageUrl))
            return
        }

        // Navigate to the actual pay page URL on the merchant's domain.
        // This establishes the correct HTTPS origin AND sets document.location.href
        // to match PayPageV2's URL. The Visa SDK sends the full href to its servers
        // during DPA authentication — using a different URL path (like /vctp/config)
        // causes AUTH_INVALID because it doesn't match the registered DPA.
        let originUrl = clickToPayArgs.payPageUrl

        var request = URLRequest(url: URL(string: originUrl)!)
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let cookie = paymentCookie, !cookie.isEmpty {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        webView.load(request)
    }

    /// Inject the pending HTML into the WebView via document.write.
    /// This preserves the HTTPS origin established by the initial navigation.
    private func injectHtmlIntoOrigin() {
        guard let base64Html = pendingHtmlBase64 else { return }
        pendingHtmlBase64 = nil  // Consume it

        let js = """
        (function() {
            var bytes = Uint8Array.from(atob('\(base64Html)'), function(c) { return c.charCodeAt(0); });
            var html = new TextDecoder().decode(bytes);
            document.open();
            document.write(html);
            document.close();
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] _, error in
            if let error = error {
                print("ClickToPay: document.write injection error: \(error)")
                self?.finish(with: .failed)
                return
            }
            self?.initializeSdkInWebView()
        }
    }

    /// Call initializeSdk in the WebView after HTML injection
    private func initializeSdkInWebView() {
        sdkInitialized = true

        // Inject button colors from SDK color configuration
        injectButtonColors()

        let configJson = getInitConfigJson()
        guard let configData = configJson.data(using: .utf8) else {
            return
        }
        let base64Config = configData.base64EncodedString()

        var js: String
        if let email = userEmail, !email.isEmpty {
            js = "setNativeWillLookup(); initializeSdk(atob('\(base64Config)'))"
        } else {
            js = "setProbeMode(); initializeSdk(atob('\(base64Config)'))"
        }

        webView.evaluateJavaScript(js) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.progressBar.stopAnimating()
            }
        }
    }

    private func injectButtonColors() {
        let colors = NISdk.sharedInstance.niSdkColors
        let btnBg = colors.payButtonBackgroundColor.toHex()
        let btnText = colors.payButtonTitleColor.toHex()
        let disBg = colors.payButtonDisabledBackgroundColor.toHex()
        let disText = colors.payButtonDisabledTitleColor.toHex()
        let css = ".btn-primary{background:\(btnBg)!important;color:\(btnText)!important;}" +
                  ".btn-pay{background:\(btnBg)!important;color:\(btnText)!important;}" +
                  ".add-card-submit-btn{background:\(btnBg)!important;color:\(btnText)!important;}" +
                  ".otp-verify-btn{background:\(btnBg)!important;color:\(btnText)!important;}" +
                  ".btn-primary:disabled{background:\(disBg)!important;color:\(disText)!important;}" +
                  ".btn-pay:disabled{background:\(disBg)!important;color:\(disText)!important;}" +
                  ".add-card-submit-btn:disabled{background:\(disBg)!important;color:\(disText)!important;}" +
                  ".otp-verify-btn:disabled{background:\(disBg)!important;color:\(disText)!important;}"
        let js = "var s=document.createElement('style');s.textContent='\(css)';document.head.appendChild(s);"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - SDK Initialization

    private func getInitConfigJson() -> String {
        let orderAmount = Amount(currencyCode: clickToPayArgs.currencyCode, value: clickToPayArgs.amount)
        let formattedDisplayAmount = orderAmount.getFormattedAmount2Decimal()
        let minorUnit = orderAmount.getMinorUnit()
        let exponent = pow(10.0, Double(minorUnit))
        let majorAmount = clickToPayArgs.amount / exponent

        var config: [String: Any] = [
            "sdkUrl": clickToPayConfig.sdkUrl,
            "dpaId": clickToPayConfig.dpaId,
            "dpaName": clickToPayConfig.dpaName,
            "cardBrands": clickToPayConfig.cardBrandsParam,
            "amount": majorAmount,
            "currencyCode": clickToPayArgs.currencyCode,
            "formattedAmount": formattedDisplayAmount,
            "locale": NISdk.sharedInstance.sdkLanguage
        ]

        if let dpaClientId = clickToPayConfig.dpaClientId {
            config["dpaClientId"] = dpaClientId
        }

        if let orderRef = orderReference {
            config["orderReference"] = orderRef
        }

        config["merchantName"] = clickToPayConfig.dpaName

        if let kid = clickToPayConfig.kid ?? vctpKid {
            config["kid"] = kid
        }
        if let publicKey = clickToPayConfig.publicKey ?? vctpPublicKey {
            config["publicKey"] = publicKey
        }

        if let merchantConfig = vctpMerchantConfig {
            config["merchantConfig"] = merchantConfig
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: config),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    // MARK: - JS Bridge Message Handling

    private func handleBridgeMessage(type: String, data: [String: Any]) {
        switch type {
        case "onSdkInitialized":
            // Always inject the GIF and Visa logo so they're available
            DispatchQueue.main.async {
                self.injectGifIntoHtml()
                self.injectVisaLogoIntoHtml()
            }
            if let email = userEmail, !email.isEmpty {
                let escapedEmail = email.replacingOccurrences(of: "'", with: "\\'")
                DispatchQueue.main.async {
                    let combinedJs = "lookupConsumer('\(escapedEmail)')"
                    self.webView.evaluateJavaScript(combinedJs) { _, _ in }
                }
            }

        case "onSdkInitError":
            finish(with: .failed)

        case "onCardsAvailable":
            break

        case "onIdentityValidationRequired":
            break

        case "onAddCardRequired":
            finish(with: .cancelled)

        case "onOtpSent":
            break

        case "onIdentityValidated":
            break

        case "onCheckoutSuccess":
            handleCheckoutSuccess(data: data)

        case "onError":
            finish(with: .failed)

        case "onSwitchId":
            DispatchQueue.main.async {
                if self.userEmail != nil {
                    // Email was provided via native email VC — pop back to it
                    self.navigationController?.popViewController(animated: true)
                } else {
                    // No email VC to pop to (recognized or standalone) — show in-page email entry
                    self.webView.evaluateJavaScript("showView('emailEntry')") { _, _ in }
                }
            }

        case "onCanceled":
            finish(with: .cancelled)

        case "log":
            let message = data["message"] as? String ?? ""
            print("ClickToPayJS: \(message)")

        default:
            break
        }
    }

    private func handleCheckoutSuccess(data: [String: Any]) {
        dismissPopup()

        guard let checkoutResponse = data["checkoutResponse"] as? String else {
            finish(with: .failed)
            return
        }

        guard let accessToken = self.accessToken,
              let paymentCookie = self.paymentCookie else {
            finish(with: .failed)
            return
        }

        let srcDigitalCardId = data["srcDigitalCardId"] as? String

        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.progressBar.startAnimating()
        }

        apiInteractor.submitPayment(
            unifiedClickToPayUrl: clickToPayArgs.unifiedClickToPayUrl,
            checkoutResponse: checkoutResponse,
            srcDigitalCardId: srcDigitalCardId,
            accessToken: accessToken,
            paymentCookie: paymentCookie,
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.handlePaymentResult(result)
                }
            }
        )
    }

    private func handlePaymentResult(_ result: ClickToPayPaymentResult) {
        switch result {
        case .authorised, .purchased, .captured:
            finish(with: .success)
        case .postAuthReview:
            finish(with: .postAuthReview)
        case .pending:
            orderPollRetryCount = 0
            pollOrderStatus()
        case .requires3DS(let paymentResponse):
            initiateThreeDS(with: paymentResponse)
        case .failed:
            finish(with: .failed)
        }
    }

    // MARK: - 3DS Handling

    private func initiateThreeDS(with paymentResponse: PaymentResponse) {
        if let acsUrl = paymentResponse.threeDSConfig?.acsUrl,
           let acsPaReq = paymentResponse.threeDSConfig?.acsPaReq,
           let acsMd = paymentResponse.threeDSConfig?.acsMd,
           let threeDSTermURL = paymentResponse.paymentLinks?.threeDSTermURL {
            let threeDSVC = ThreeDSViewController(with: acsUrl,
                                                  acsPaReq: acsPaReq,
                                                  acsMd: acsMd,
                                                  threeDSTermURL: threeDSTermURL,
                                                  completion: onThreeDSCompletion)
            showThreeDSViewController(threeDSVC)
        } else if let token = self.accessToken {
            let threeDSTwoVC = ThreeDSTwoViewController(with: paymentResponse,
                                                        accessToken: token,
                                                        transactionService: self.transactionService,
                                                        completion: onThreeDSCompletion)
            threeDSTwoVC.paypageLink = clickToPayArgs.payPageUrl
            showThreeDSViewController(threeDSTwoVC)
        } else {
            finish(with: .failed)
        }
    }

    private func showThreeDSViewController(_ vc: UIViewController) {
        threeDSChildVC = vc
        add(vc, inside: view)
        webView.isHidden = true
        view.bringSubviewToFront(vc.view)
    }

    private func removeThreeDSViewController() {
        threeDSChildVC?.remove()
        threeDSChildVC = nil
        webView.isHidden = false
    }

    lazy private var onThreeDSCompletion: (Bool) -> Void = { [weak self] hasSDKError in
        guard let self = self else { return }

        DispatchQueue.main.async {
            self.removeThreeDSViewController()
        }

        if hasSDKError {
            DispatchQueue.main.async {
                self.finish(with: .failed)
            }
            return
        }

        self.orderPollRetryCount = 0
        self.pollOrderStatus()
    }

    /// Poll the order status until it resolves to a final state.
    /// Used after both PENDING payment submission and 3DS completion.
    private func pollOrderStatus() {
        guard let token = self.accessToken else {
            finish(with: .failed)
            return
        }

        let orderUrl = clickToPayArgs.orderUrl

        transactionService.getOrder(for: orderUrl, using: token) { [weak self] data, response, error in
            guard let self = self else { return }

            guard let data = data else {
                DispatchQueue.main.async { self.finish(with: .failed) }
                return
            }

            do {
                let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                guard let payments = orderResponse.embeddedData?.payment else {
                    DispatchQueue.main.async { self.finish(with: .failed) }
                    return
                }

                let successStates = ["CAPTURED", "AUTHORISED", "PURCHASED", "VERIFIED", "POST_AUTH_REVIEW"]

                if let successPayment = payments.first(where: { successStates.contains($0.state) }) {
                    DispatchQueue.main.async {
                        if successPayment.state == "POST_AUTH_REVIEW" {
                            self.finish(with: .postAuthReview)
                        } else {
                            self.finish(with: .success)
                        }
                    }
                } else if let awaitingPayment = payments.first(where: { $0.state == "AWAIT_3DS" }) {
                    self.fetchPaymentForThreeDS(payment: awaitingPayment)
                } else if payments.contains(where: { $0.state == "PENDING" }) && self.orderPollRetryCount < self.orderPollMaxRetries {
                    self.orderPollRetryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.pollOrderStatus()
                    }
                } else if payments.contains(where: { $0.state == "FAILED" }) {
                    DispatchQueue.main.async { self.finish(with: .failed) }
                } else {
                    DispatchQueue.main.async { self.finish(with: .failed) }
                }
            } catch {
                DispatchQueue.main.async { self.finish(with: .failed) }
            }
        }
    }

    /// Fetch the individual payment resource to get 3DS configuration (acsUrl, etc.)
    /// The payment from the order poll may not include 3DS config — fetch the payment URL directly.
    private func fetchPaymentForThreeDS(payment: PaymentResponse) {
        if payment.threeDSConfig != nil || payment.threeDSTwoConfig != nil {
            DispatchQueue.main.async {
                self.initiateThreeDS(with: payment)
            }
            return
        }

        guard let token = self.accessToken,
              let paymentUrl = payment.paymentLinks?.paymentLink else {
            DispatchQueue.main.async { self.finish(with: .failed) }
            return
        }

        transactionService.getOrder(for: paymentUrl, using: token) { [weak self] data, response, error in
            guard let self = self else { return }

            guard let data = data else {
                DispatchQueue.main.async { self.finish(with: .failed) }
                return
            }

            do {
                let paymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                DispatchQueue.main.async {
                    self.initiateThreeDS(with: paymentResponse)
                }
            } catch {
                DispatchQueue.main.async { self.finish(with: .failed) }
            }
        }
    }

    // MARK: - Completion

    private func finish(with status: ClickToPayStatus) {
        dismissPopup()
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.onCompletion(status)
            }
        }
    }

    @objc private func cancelAction() {
        finish(with: .cancelled)
    }

    deinit {
        popupCleanupTimer?.invalidate()
        popupWebView?.removeFromSuperview()
        popupWebView = nil
        threeDSChildVC?.remove()
        threeDSChildVC = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "clickToPayBridge")
    }
}

// MARK: - WKNavigationDelegate

extension ClickToPayViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == popupWebView {
            return
        }

        if !originEstablished && pendingHtmlBase64 != nil {
            originEstablished = true
            injectHtmlIntoOrigin()
            return
        }

        if !sdkInitialized {
            initializeSdkInWebView()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if webView == popupWebView { return }
        fallbackToLoadHtmlString()
    }

    /// If the origin-establishing navigation fails (network error, DNS, etc.),
    /// fall back to loadHTMLString. The Visa add-card DCF won't work with a null origin,
    /// but existing card checkout and Mastercard flows may still function.
    private func fallbackToLoadHtmlString() {
        guard !originEstablished, let base64Html = pendingHtmlBase64 else { return }
        pendingHtmlBase64 = nil
        originEstablished = true

        guard let htmlData = Data(base64Encoded: base64Html),
              let html = String(data: htmlData, encoding: .utf8) else {
            finish(with: .failed)
            return
        }

        let baseUrl = URL(string: clickToPayArgs.payPageUrl)
        webView.loadHTMLString(html, baseURL: baseUrl)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if webView == popupWebView { return }
        fallbackToLoadHtmlString()
    }
}

// MARK: - WKUIDelegate (popup handling for Mastercard SRC enrollment)

extension ClickToPayViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        let popup = WKWebView(frame: view.bounds, configuration: configuration)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.navigationDelegate = self
        popup.uiDelegate = self

        view.addSubview(popup)
        popupWebView = popup

        return popup
    }

    func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            hidePopupWithDelayedCleanup()
        }
    }

    @objc private func closePopupWebView() {
        hidePopupWithDelayedCleanup()
    }

    /// Hide the popup immediately (UI) but keep the WKWebView alive for a few seconds
    /// so the Visa SDK can finish communicating with it to resolve the checkout promise.
    private func hidePopupWithDelayedCleanup() {
        popupWebView?.isHidden = true

        popupCleanupTimer?.invalidate()
        popupCleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.destroyPopup()
        }
    }

    private func dismissPopup() {
        popupCleanupTimer?.invalidate()
        popupCleanupTimer = nil
        destroyPopup()
    }

    private func destroyPopup() {
        guard popupWebView != nil else { return }
        popupWebView?.removeFromSuperview()
        popupWebView = nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}

// MARK: - WKScriptMessageHandler

extension ClickToPayViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "clickToPayBridge" else { return }

        guard let messageString = message.body as? String,
              let messageData = messageString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: messageData),
              let json = jsonObject as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        let data = json["data"] as? [String: Any] ?? [:]
        handleBridgeMessage(type: type, data: data)
    }
}
