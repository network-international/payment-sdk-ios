//
//  FooterView.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

class FooterView: UIView {

    private let cardProviders: [CardProvider]?

    private let termsURL = URL(string: "https://www.network.ae/en/terms-and-conditions")!
    private let privacyURL = URL(string: "https://www.network.ae/en/privacy-notice")!

    init(cardProviders: [CardProvider]? = nil) {
        self.cardProviders = cardProviders
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Top divider (full width)
        let divider = UIView()
        divider.backgroundColor = UIColor(hexString: "#DADADA")
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        mainStack.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true

        // Row 1: Lock + "Powered by" + NI Logo (centered)
        let poweredByStack = UIStackView()
        poweredByStack.axis = .horizontal
        poweredByStack.spacing = 4
        poweredByStack.alignment = .center

        let lockIcon = UIImageView()
        if #available(iOS 13.0, *) {
            lockIcon.image = UIImage(systemName: "lock.fill")
        }
        lockIcon.tintColor = UIColor(hexString: "#8F8F8F")
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        lockIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let poweredByLabel = UILabel()
        poweredByLabel.text = "Powered by".localized
        poweredByLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        poweredByLabel.textColor = UIColor(hexString: "#8F8F8F")

        let sdkBundle = NISdk.sharedInstance.getBundle()
        let niLogoView = UIImageView(image: UIImage(named: "networklogo", in: sdkBundle, compatibleWith: nil))
        niLogoView.contentMode = .scaleAspectFit
        niLogoView.translatesAutoresizingMaskIntoConstraints = false
        niLogoView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        niLogoView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        poweredByStack.addArrangedSubview(lockIcon)
        poweredByStack.addArrangedSubview(poweredByLabel)
        poweredByStack.addArrangedSubview(niLogoView)

        mainStack.addArrangedSubview(poweredByStack)

        // Row 2: Terms and Conditions | Privacy Policy (centered)
        let linksStack = UIStackView()
        linksStack.axis = .horizontal
        linksStack.spacing = 12
        linksStack.alignment = .center

        let termsButton = UIButton(type: .system)
        termsButton.setTitle("Terms and Conditions".localized, for: .normal)
        termsButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        termsButton.setTitleColor(UIColor(hexString: "#8F8F8F"), for: .normal)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        let separatorLabel = UILabel()
        separatorLabel.text = "|"
        separatorLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        separatorLabel.textColor = UIColor(hexString: "#8F8F8F")

        let privacyButton = UIButton(type: .system)
        privacyButton.setTitle("Privacy Policy".localized, for: .normal)
        privacyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        privacyButton.setTitleColor(UIColor(hexString: "#8F8F8F"), for: .normal)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        linksStack.addArrangedSubview(termsButton)
        linksStack.addArrangedSubview(separatorLabel)
        linksStack.addArrangedSubview(privacyButton)

        mainStack.addArrangedSubview(linksStack)

        // Row 3: Card brand logos (only available providers)
        let logoNames = cardLogoNames()
        if !logoNames.isEmpty {
            let logosStack = UIStackView()
            logosStack.axis = .horizontal
            logosStack.spacing = 8
            logosStack.alignment = .center

            for logoName in logoNames {
                let imageView = UIImageView(image: UIImage(named: logoName, in: sdkBundle, compatibleWith: nil))
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
                logosStack.addArrangedSubview(imageView)
            }

            mainStack.addArrangedSubview(logosStack)
        }

        addSubview(mainStack)
        mainStack.anchor(top: topAnchor, leading: leadingAnchor,
                         bottom: bottomAnchor, trailing: trailingAnchor,
                         padding: UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20))
    }

    private func cardLogoNames() -> [String] {
        guard let providers = cardProviders, !providers.isEmpty else { return [] }
        var logos: [String] = []
        var seen = Set<String>()
        for provider in providers {
            let name: String?
            switch provider {
            case .visa:                     name = "visalogo"
            case .masterCard:               name = "mastercardlogo"
            case .americanExpress:          name = "amexlogo"
            case .dinersClubInternational:  name = "dinerslogo"
            case .jcb:                      name = "jcblogo"
            case .discover:                 name = "discoverlogo"
            default:                        name = nil
            }
            if let name = name, !seen.contains(name) {
                seen.insert(name)
                logos.append(name)
            }
        }
        return logos
    }

    @objc private func termsTapped() {
        UIApplication.shared.open(termsURL)
    }

    @objc private func privacyTapped() {
        UIApplication.shared.open(privacyURL)
    }
}
