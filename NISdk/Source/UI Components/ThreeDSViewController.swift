//
//  ThreeDSViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import WebKit

class ThreeDSViewController: UIViewController, WKNavigationDelegate {
    private var webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    private var acsUrl: String
    private var acsPaReq: String
    private var acsMd: String
    private var threeDSTermURL: String
    private var completionHandler: () -> Void
    private var hasClosedWebView: Bool = false
    private var hasInitialisedRequest: Bool = false
    
    
    init(with acsUrl: String, acsPaReq: String, acsMd: String, threeDSTermURL: String, completion: @escaping () -> Void) {
        self.acsUrl = acsUrl
        self.acsPaReq = acsPaReq
        self.acsMd = acsMd
        self.threeDSTermURL = threeDSTermURL
        self.completionHandler = completion
        activityIndicator.hidesWhenStopped = true
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    private func setupSubviews() {
        view.backgroundColor = .white
        
        webView.alpha = 0
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                       leading: view.safeAreaLayoutGuide.leadingAnchor,
                       bottom: view.safeAreaLayoutGuide.bottomAnchor,
                       trailing: view.safeAreaLayoutGuide.trailingAnchor)
        
        view.addSubview(activityIndicator)
        activityIndicator.alignCenterToCenterOf(parent: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Adding this check to prevent multiple requests
        if(!hasInitialisedRequest) {
            hasInitialisedRequest = true
            var request = URLRequest(url: URL(string: acsUrl)!)
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody   = "PaReq=\(acsPaReq.encodeAsURL())&TermUrl=\(threeDSTermURL.encodeAsURL())&MD=\(acsMd.encodeAsURL())".data(using: .utf8)
            
            webView.load(request)
            showActivityIndicator()
        }
    }
    
    private func showActivityIndicator() {
        self.activityIndicator.alpha = 1
        self.activityIndicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        UIView.animate(withDuration: 0.4,
                       animations: { self.webView.alpha = 1; self.activityIndicator.alpha = 0 },
                       completion: { _ in self.activityIndicator.stopAnimating()})
    }
    
    // MARK: WKNavigationDelegate delegation methods
    // Gets called once the 3ds page is loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideActivityIndicator()
    }
    
    // Gets called after 3ds is performed and a 302 redirect is received from txn service
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if (webView.url?.queryParameters?["3ds_status"]) != nil {
            hasClosedWebView = true
            webView.stopLoading()
            self.completionHandler()
        }
    }
    
    // Gets called when the 3ds page fails to load
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 3ds Failed due to some error
        webView.stopLoading()
        if(!hasClosedWebView) {
            hasClosedWebView = true;
            self.completionHandler()
        }
    }
}
