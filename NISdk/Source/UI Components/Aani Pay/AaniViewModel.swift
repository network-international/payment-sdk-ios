//
//  AaniViewModel.swift
//  NISdk
//
//  Created by Gautam Chibde on 02/08/24.
//

import Combine
import SwiftUI

enum AaniViewType {
    case inputSelection
    case timer
}

public enum AaniPaymentStatus {
    case success
    case failed
    case cancelled
    case invalidRequest
}

class AaniViewModel: ObservableObject {
    private var aaniPayArgs: AaniPayArgs
    @Published var viewType: AaniViewType = .inputSelection
    @Published var timeString: String = "03:00"
    private var serviceAdapter: TransactionService
    private var cancellable: AnyCancellable?
    private let onCompletion: (AaniPaymentStatus) -> Void?
    private let onPaymentProccessing: (Bool) -> Void?
    private var remainingTime: Int = 180  // 3 minutes in seconds
    private var timer: AnyCancellable?

    init(aaniPayArgs: AaniPayArgs,
         onCompletion: @escaping (AaniPaymentStatus) -> Void?,
         onPaymentProcessing: @escaping (Bool) -> Void?
    ) {
        self.aaniPayArgs = aaniPayArgs
        self.onCompletion = onCompletion
        self.onPaymentProccessing = onPaymentProcessing
        self.serviceAdapter = TransactionServiceAdapter()
    }

    func onSubmit(idType: AaniIDType, inputText: String) {
        self.onPaymentProccessing(false)
        serviceAdapter.authorizePayment(
            for: aaniPayArgs.authCode,
            using: aaniPayArgs.authUrl,
            on: { [weak self] tokens in
                if let accessToken = tokens["access-token"] {
                    self?.getPayerIp(payPageLink: self?.aaniPayArgs.payPageUrl) { payerIp in
                        guard let ip = payerIp else {
                            return
                        }
                        let request = AaniPayRequest(aliasType: idType.key, payerIp: ip, backLink: "niannipay://open")
                        
                        switch idType {
                        case .mobileNumber:
                            request.mobileNumber = MobileNumber(countryCode: "+971", number: inputText)
                        case .emiratesID:
                            request.emiratesId = inputText
                        case .passportID:
                            request.passportId = inputText
                        case .emailID:
                            request.emailId = inputText
                        }
                        
                        self?.serviceAdapter.aaniPayment(
                            for: self?.aaniPayArgs.anniPaymentLink ?? "",
                            with: request,
                            using: accessToken,
                            on: { data, response, error in
                                if error != nil {
                                    self?.onPaymentProccessing(true)
                                    self?.onCompletion(.failed)
                                } else if let data = data {
                                    do {
                                        let response = try JSONDecoder().decode(AaniPayResponse.self, from: data)
                                        self?.startPolling(accessToken: accessToken, url: response.links.aaniStatus ?? "")
                                        if let url = URL(string: response.aani.deepLinkUrl) {
                                            DispatchQueue.main.async {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }
                                        }
                                    } catch let _ {
                                        self?.onPaymentProccessing(true)
                                        self?.onCompletion(.failed)
                                    }
                                } else {
                                    self?.onPaymentProccessing(true)
                                    self?.onCompletion(.failed)
                                }
                            })
                    }
                }
            })
    }

    func startPolling(accessToken: String, url: String) {
        DispatchQueue.main.async {
            self.viewType = .timer
        }
        startTimer()
        cancellable = Timer.publish(every: 6, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.callAPI(accessToken: accessToken, url: url)
            }
    }

    func stopPolling(_ status: AaniPaymentStatus) {
        cancellable?.cancel()
        stopTimer()
        onCompletion(status)
    }

    private func callAPI(accessToken: String, url: String) {
        serviceAdapter.aaniPaymentPooling(with: url, using: accessToken) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.stopPolling(.failed)
                } else if let data = data {
                    if let state = try? JSONDecoder().decode(AaniPoolingResponse.self, from: data).state {
                        switch state {
                        case "CAPTURED", "PURCHASED":
                            print("success")
                            self?.stopPolling(.success)
                        case "FAILED":
                            self?.stopPolling(.failed)
                        default:
                            break
                        }
                    } else {
                        self?.stopPolling(.failed)
                    }
                } else {
                    self?.stopPolling(.failed)
                }
            }
        }
    }

    func getPayerIp(payPageLink: String?, onCompletion: @escaping (String?) -> ()) {
        guard let url = payPageLink, let urlHost = URL(string: url)?.host else {
            onCompletion(nil)
            return
        }
        let ipUrl = "https://\(urlHost)/api/requester-ip"
        serviceAdapter.getPayerIp(with: ipUrl, on: { payerIPData, _, _ in
            if let payerIPData = payerIPData {
                do {
                    let payerIpDict: [String: String] = try JSONDecoder().decode([String: String].self, from: payerIPData)
                    onCompletion(payerIpDict["requesterIp"])
                } catch {
                    onCompletion(nil)
                }
            } else {
                onCompletion(nil)
            }
        })
    }

    // Countdown Timer Methods
    func startTimer() {
        updateTimeString()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        if remainingTime > 0 {
            remainingTime -= 1
            updateTimeString()
        } else {
            stopTimer()
            // Handle timer completion if needed
        }
    }

    private func updateTimeString() {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        timeString = String(format: "%02d:%02d", minutes, seconds)
    }

    func getAmountFormatted() -> String {
        return Amount(currencyCode: aaniPayArgs.currencyCode, value: aaniPayArgs.amount).getFormattedAmount2Decimal()
    }
}
