import Combine
import SwiftUI

enum AaniViewType {
    case inputSelection
    case timer
}

@objc public enum AaniPaymentStatus: Int, RawRepresentable {
    case success
    case failed
    case cancelled
    case invalidRequest
}

class AaniViewModel: ObservableObject {
    private var aaniPayArgs: AaniPayArgs
    @Published var viewType: AaniViewType = .inputSelection
    @Published var timeString: String = "05:00"
    private var serviceAdapter: TransactionService
    private var cancellable: AnyCancellable?
    private let onCompletion: (AaniPaymentStatus) -> Void
    private let onPaymentProcessing: (Bool) -> Void
    private var remainingTime: Int = 300
    private var timer: AnyCancellable?

    init(
        aaniPayArgs: AaniPayArgs,
        onCompletion: @escaping (AaniPaymentStatus) -> Void,
        onPaymentProcessing: @escaping (Bool) -> Void
    ) {
        self.aaniPayArgs = aaniPayArgs
        self.onCompletion = onCompletion
        self.onPaymentProcessing = onPaymentProcessing
        self.serviceAdapter = TransactionServiceAdapter()
    }

    func onSubmit(idType: AaniIDType, inputText: String) {
        onPaymentProcessing(false)
        serviceAdapter.authorizePayment(
            for: aaniPayArgs.authCode,
            using: aaniPayArgs.authUrl
        ) { [weak self] tokens in
            guard let self = self, let accessToken = tokens["access-token"] else {
                self?.handlePaymentFailure()
                return
            }
            self.getPayerIp(payPageLink: self.aaniPayArgs.payPageUrl) { payerIp in
                guard let ip = payerIp else {
                    self.handlePaymentFailure()
                    return
                }
                let request = self.createPaymentRequest(idType: idType, inputText: inputText, payerIp: ip, backLink: self.aaniPayArgs.backLink)
                self.processPayment(request: request, accessToken: accessToken)
            }
        }
    }

    private func createPaymentRequest(idType: AaniIDType, inputText: String, payerIp: String, backLink: String) -> AaniPayRequest {
        let request = AaniPayRequest(aliasType: idType.key, payerIp: payerIp, backLink: backLink)
        
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
        
        return request
    }

    private func processPayment(request: AaniPayRequest, accessToken: String) {
        serviceAdapter.aaniPayment(
            for: aaniPayArgs.anniPaymentLink,
            with: request,
            using: accessToken
        ) { [weak self] data, response, error in
            guard let self = self else { return }
            if let _ = error {
                self.handlePaymentFailure()
                return
            }
            
            guard let data = data else {
                self.handlePaymentFailure()
                return
            }
            
            do {
                let response = try JSONDecoder().decode(AaniPayResponse.self, from: data)
                self.startPolling(accessToken: accessToken, url: response.links.aaniStatus ?? "")
                self.openDeepLink(urlString: response.aani.deepLinkUrl)
            } catch {
                self.handlePaymentFailure()
            }
        }
    }

    private func handlePaymentFailure() {
        DispatchQueue.main.async {
            self.onPaymentProcessing(true)
            self.onCompletion(.failed)
        }
    }

    private func openDeepLink(urlString: String) {
        if let url = URL(string: urlString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
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
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let _ = error {
                    self.stopPolling(.failed)
                    return
                }
                
                guard let data = data else {
                    self.stopPolling(.failed)
                    return
                }
                
                do {
                    let state = try JSONDecoder().decode(AaniPoolingResponse.self, from: data).state
                    switch state {
                    case "CAPTURED", "PURCHASED":
                        self.stopPolling(.success)
                    case "FAILED":
                        self.stopPolling(.failed)
                    default:
                        break
                    }
                } catch {
                    self.stopPolling(.failed)
                }
            }
        }
    }

    func getPayerIp(payPageLink: String?, onCompletion: @escaping (String?) -> Void) {
        guard let url = payPageLink, let urlHost = URL(string: url)?.host else {
            onCompletion(nil)
            return
        }
        let ipUrl = "https://\(urlHost)/api/requester-ip"
        serviceAdapter.getPayerIp(with: ipUrl) { payerIPData, _, _ in
            if let payerIPData = payerIPData {
                let payerIpDict = try? JSONDecoder().decode([String: String].self, from: payerIPData)
                onCompletion(payerIpDict?["requesterIp"])
            } else {
                onCompletion(nil)
            }
        }
    }

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
