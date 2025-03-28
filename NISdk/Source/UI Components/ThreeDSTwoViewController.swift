//
//  ThreeDSTwoViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
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
    
    private var authorizationLabel: UILabel {
        let authLabel = UILabel()
        authLabel.text = "Authenticating using 3DS".localized
        authLabel.textColor = NISdk.sharedInstance.niSdkColors.threeDSViewLabelColor
        return authLabel
    }
    private let vStack = UIStackView()
    
    init(with paymentResponse: PaymentResponse, accessToken: String,
         transactionService: TransactionServiceAdapter, completion: @escaping (Bool) -> Void) {
        self.completionHandler = completion
        self.transactionService = transactionService
        self.accessToken = accessToken
        self.activityIndicator.color = NISdk.sharedInstance.niSdkColors.threeDSViewActivityIndicatorColor
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
        
        view.backgroundColor = NISdk.sharedInstance.niSdkColors.threeDSViewBackgroundColor
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
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.preferredContentMode = .mobile
        decisionHandler(.allow, preferences)
    }
    
    func handleThreeDSTwoStageCompletion() {
        if(!fingerPrintCompleted) {
            fingerPrintCompleted = true
            onCompleteFingerPrint(threeDSCompInd: "Y")
        } else {
            // Challenge is completed
            showActivityIndicator()
            guard let threeDSTwoChallengeResponseURL = paymentResponse.paymentLinks?.threeDSTwoChallengeResponseURL else {
                self.completionHandler(true)
                return
            }
            transactionService.postThreeDSTwoChallengeResponse(for: paymentResponse, using: threeDSTwoChallengeResponseURL) {
                data, response, error in
                self.completionHandler(false)
            }
        }
    }
    
    func onCompleteFingerPrint(threeDSCompInd: String) {
        self.frictionlessTimer?.invalidate()
        guard let authenticationsUrl = paymentResponse.paymentLinks?.threeDSTwoAuthenticationURL else {
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
                self.completionHandler(true)
                return
            }
            if(error == nil) {
                var browserInfo: BrowserInfo? = nil
                do {
                    let data = try JSONSerialization.data(withJSONObject: result, options: [])
                    browserInfo = try JSONDecoder().decode(BrowserInfo.self, from: data)
                } catch {
                    // Could not deserialise browser info
                    self.completionHandler(true)
                    return
                }
                _ = browserInfo?.with(browserAcceptHeader:  "application/json, text/plain, */*")
                _ = browserInfo?.with(browserJavascriptEnabled: true)
                _ = browserInfo?.with(challengeWindowSize: "05")
                guard let browserInfo = browserInfo else {
                    // browser info null
                    self.completionHandler(true)
                    return
                }
                guard let notificationUrl = self.paymentResponse.threeDSMethodNotificationURL else {
                    // notificationUrl is null
                    self.completionHandler(true)
                    return
                }
                self.transactionService.getPayerIp(with: self.getIpUrl(
                    stringVal: self.paymentResponse.paymentLinks!.threeDSTwoAuthenticationURL!,
                    outletRef: self.paymentResponse.outletId!,
                    orderRef: self.paymentResponse.orderReference!,
                    paymentRef: self.paymentResponse._id!),
                                                   using: self.accessToken,
                                                   on: { payerIPData, _, _ in
                    guard let payerIPData = payerIPData else {
                        // Unable to get IP address of payer
                        self.completionHandler(true)
                        return
                    }
                    var payerIp: String? = nil
                    do {
                        let payerIpDict: [String: String] = try JSONDecoder().decode([String: String].self, from: payerIPData)
                        payerIp = payerIpDict["requesterIp"]
                    } catch {
                        // Unable to get payer Ip address from decoded response
                        self.completionHandler(true)
                        return
                    }
                    guard let payerIp = payerIp else {
                        self.completionHandler(true)
                        return
                    }
                    
                    let _ = browserInfo.with(browserIP: payerIp)
                    let threeDSAuthenticationsRequest = ThreeDSAuthenticationsRequest()
                        .with(threeDSCompInd: threeDSCompInd)
                        .with(browserInfo: browserInfo)
                        .with(notificationUrl: notificationUrl)
                    self.postAuthentications(
                        threeDSAuthenticationsRequest: threeDSAuthenticationsRequest,
                        authenticationsUrl: authenticationsUrl)
                })
            } else {
                // Could not get browser info
                self.completionHandler(true)
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
                    self.completionHandler(true)
                    return
                }
                
                guard let threeDSTwoAuthenticationsResponse = try? JSONDecoder().decode(ThreeDSTwoAuthenticationsResponse.self, from: authenticationsData) else {
                    // unable to decode threeDSTwoAuthenticationsResponse
                    self.completionHandler(true)
                    return
                }
                
                if(threeDSTwoAuthenticationsResponse.state == "FAILED") {
                    // 3ds Failed something went wrong
                    self.completionHandler(true)
                    return
                    
                }
                
                guard let transStatus = threeDSTwoAuthenticationsResponse.threeDSTwo?.transStatus else {
                    // no transStatus found
                    self.completionHandler(true)
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
                            self.webView.load(request)
                        }
                    } else {
                        // Unable to obtain base64EncodedCReq and acsURL
                        self.completionHandler(true)
                    }
                    break
                default:
                    self.completionHandler(false)
                    break
                }
            })
    }
}

extension ThreeDSTwoViewController {
    private func getIpUrl(stringVal: String, outletRef: String, orderRef: String, paymentRef: String) -> String {
        let slug =
        "/api/outlets/\(outletRef)/orders/\(orderRef)/payments/\(paymentRef)/3ds2/requester-ip"
        if (stringVal.localizedCaseInsensitiveContains("-uat") ||
            stringVal.localizedCaseInsensitiveContains("sandbox")
        ) {
            return "https://paypage.sandbox.ngenius-payments.com\(slug)"
        }
        if (stringVal.localizedCaseInsensitiveContains("-dev")) {
            return "https://paypage-dev.ngenius-payments.com\(slug)"
        }
        return "https://paypage.ngenius-payments.com\(slug)"
    }
}

