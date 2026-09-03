//
//  BenefitInAppViewController.swift
//  NISdk
//
//  Hosts the FOO BenefitInAppSDK button. The SDK is button-driven: on tap it reads the configuration
//  from its delegate, builds the MPQR payload and app-switches to the BenefitPay app. The payment
//  result does NOT come back here — BenefitPay returns it to the host app over the URL scheme, which
//  the host forwards through `NISdk.handleBenefitInAppCallback(url:)`. This screen therefore only
//  presents the button and reports a local cancel when the user dismisses without paying.
//

import UIKit
import BenefitInAppSDK

final class BenefitInAppViewController: UIViewController, BPInAppButtonDelegate {

    private let config: BenefitInAppConfig
    /// Fired only for a local dismissal (user closed the screen before the app-switch returned).
    private let onDismiss: () -> Void

    init(config: BenefitInAppConfig, onDismiss: @escaping () -> Void) {
        self.config = config
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let close = UIButton(type: .system)
        close.setTitle("Cancel", for: .normal)
        close.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        // 258 x 60 per the BenefitInAppSDK guidelines; the button drives the app-switch on tap.
        let button = BPInAppButton()
        button.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 258),
            button.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    @objc private func didTapClose() {
        dismiss(animated: true) { [onDismiss] in onDismiss() }
    }

    // MARK: - BPInAppButtonDelegate
    func bpInAppConfiguration() -> BPInAppConfiguration {
        return BPInAppConfiguration(
            appId: config.appId,
            andSecretKey: config.secretKey,
            andAmount: config.amount,
            andCurrencyCode: config.currencyCode,
            andMerchantId: config.merchantId,
            andMerchantName: config.merchantName,
            andMerchantCity: config.merchantCity,
            andCountryCode: config.countryCode,
            andMerchantCategoryId: config.merchantCategoryCode,
            andReferenceId: config.referenceId,
            andCallBackTag: config.callBackTag
        )
    }
}
