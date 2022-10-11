//
//  ThreeDSTwoViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import uSDK

class ThreeDSTwoViewController: UIViewController, UChallengeStatusReceiver {
    private var directoryServerID: String?
    private var threeDSMessageVersion: String?
    private var completionHandler: () -> Void
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    private var transactionService: TransactionService
    private var accessToken: String
    private var paymentResponse: PaymentResponse
    private var transaction: UTransaction?
    
    private var authorizationLabel: UILabel {
        let authLabel = UILabel()
        authLabel.text = "Authenticating Payment".localized
        return authLabel
    }
    
    init(with directoryServerID: String,
         threeDSMessageVersion: String,
         completion: @escaping () -> Void,
         transactionService: TransactionServiceAdapter,
         accessToken: String, paymentResponse: PaymentResponse) {
        self.directoryServerID = directoryServerID
        self.threeDSMessageVersion = paymentResponse.threeDSTwoConfig?.messageVersion
        self.completionHandler = completion
        self.transactionService = transactionService
        self.accessToken = accessToken
        self.paymentResponse = paymentResponse
        activityIndicator.hidesWhenStopped = true
        super.init(nibName: nil, bundle: nil)        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func completeThreeDSJourney() {
        if let transaction = self.transaction {
            do {
                DispatchQueue.main.async {
                    try? transaction.close()
                }
            }
        }
        self.completionHandler()
    }
    
    func completed(_ completionEvent: UCompletionEvent, navVC: UINavigationController) {
        let transactionStatus = completionEvent.getTransactionStatus()
        print("Challenge has completed with status \(transactionStatus)")
        transactionService.postThreeDSTwoChallengeResponse(for: self.paymentResponse, using: self.accessToken) {
            data, response, error in
            self.completeThreeDSJourney()
        }
    }
    
    func cancelled() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.parent?.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.isHidden = false
        spinner.startAnimating()

        let vStack = UIStackView(arrangedSubviews: [authorizationLabel, spinner])
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
        
        do {
            guard let directoryServerID = self.directoryServerID else {
                // unable to parse data
                completeThreeDSJourney()
                return
            }
            let directoryServerId = self.paymentResponse.paymentLinks?.threeDSTwoAuthenticationURL?.ngenEnv() == .PROD ? directoryServerID : "SANDBOX_DS"
            let txn = try UThreeDS2ServiceImpl.shared().u_createTransaction(
                directoryServerId, messageVersion: threeDSMessageVersion)
            self.transaction = txn
            let response = try txn.u_getAuthenticationRequestParameters()
            self.activityIndicator.stopAnimating()
            if let ephKeyData = response.getSDKEphemeralPublicKey().data(using: .utf8) {
                let sdkEphemPubKey = try JSONDecoder().decode(SDKEphemPubKey.self, from: ephKeyData)
                let sdkInfo = SDKInfo(sdkAppID: response.getSDKAppID(),
                                      sdkEncData: response.getDeviceData(),
                                      sdkEphemPubKey: sdkEphemPubKey,
                                      sdkMaxTimeout: 10,
                                      sdkReferenceNumber: response.getSDKReferenceNumber(),
                                      sdkTransID: response.getSDKTransactionID(),
                                      deviceRenderOptions: DeviceRenderOptions(
                                        sdkInterface: "03",
                                        sdkUiType: ["01", "02", "03", "05"]))
                let threeDSAuthReq = ThreeDSAuthenticationsRequest(sdkInfo: sdkInfo)
                self.transactionService.postThreeDSAuthentications(for: self.paymentResponse, with: threeDSAuthReq
                                                                      , using: self.accessToken) { data, response, error in
                    do {
                        guard let data = data else {
                            // unable to parse data
                            self.completeThreeDSJourney()
                            return
                        }
                        
                        guard let threeDSTwoAuthenticationsResponse = try? JSONDecoder().decode(ThreeDSTwoAuthenticationsResponse.self, from: data) else {
                            // unable to decode threeDSTwoAuthenticationsResponse
                            self.completeThreeDSJourney()
                            return
                        }
                        
                        if(threeDSTwoAuthenticationsResponse.state == "FAILED") {
                            // 3ds Failed something went wrong
                            self.completeThreeDSJourney()
                            return
                            
                        }
                        
                        guard let transStatus = threeDSTwoAuthenticationsResponse.threeDSTwo?.transStatus else {
                            // no transStatus found
                            self.completeThreeDSJourney()
                            return
                        }
                        
                        switch transStatus {
                        case "C":
                            // Challenge flow
                            // Open Challenge frame
                            guard let threeDSTransID = threeDSTwoAuthenticationsResponse.threeDSTwo?.threeDSServerTransID,
                                  let acsTransactionID = threeDSTwoAuthenticationsResponse.threeDSTwo?.acsTransID,
                                  let acsRefNumber = threeDSTwoAuthenticationsResponse.threeDSTwo?.acsReferenceNumber,
                                  let acsSignedContent = threeDSTwoAuthenticationsResponse.threeDSTwo?.acsSignedContent else {
                                      // Unable to get details required to open the challenge frame
                                self.completeThreeDSJourney()
                                return
                            }
                            let challengeParams = try UChallengeParameters(
                                threeDSTransID: threeDSTransID,
                                acsTransactionID: acsTransactionID,
                                acsRefNumber: acsRefNumber,
                                acsSignedContent:acsSignedContent)
                            let timeout: Int = 10
                            DispatchQueue.main.async {
                                guard let navController = self.navigationController else {
                                    print("Unable to get hold of nav controller")
                                    return
                                }
                                do {
                                    try txn.u_doChallenge(
                                        navController,
                                        challengeParameters: challengeParams,
                                        challengeStatusReceiver: self,
                                        timeOut: Int32(timeout))
                                } catch {
                                    // handle error
                                    print(error)
                                }
                            }
                            break;
                        case "Y":
                            // Frictionless is complete
                            self.completeThreeDSJourney()
                            break;
                        default:
                            self.completeThreeDSJourney()
                            break;
                        }
                    } catch {
                        // Something went wrong
                        self.completeThreeDSJourney()
                    }
                }
            }
        } catch {
            // Something went wrong in one of the tries above
            self.completeThreeDSJourney()
            print(error)
            self.activityIndicator.stopAnimating()
        }
    }
}
