//
//  CreditCardInfoView.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 09/10/23.
//  Copyright © 2023 Network International. All rights reserved.
//

import Foundation
import UIKit
import NISdk

protocol CreditCardInfoViewDelegate: AnyObject {
    func didTapPayButton(withCVV cvv: String?)
}

class CreditCardInfoView: UIView {
    
    weak var delegate: CreditCardInfoViewDelegate?
    private var savedCard: SavedCard?
    
    // MARK: - UI Components
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let maskedCardNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    private let expiryDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    private let cardHolderNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    private lazy var cardInfoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [cardHolderNameLabel, expiryDateLabel, maskedCardNumberLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay", for: .normal)
        button.backgroundColor = UIColor.black
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(logoImageView)
        addSubview(cardInfoStackView)
        addSubview(payButton)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        layer.cornerRadius = 8
        backgroundColor = .gray
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Auto Layout Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 56),
            
            cardInfoStackView.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 16),
            cardInfoStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            payButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            payButton.widthAnchor.constraint(equalToConstant: 60),
            payButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func setCard(savedCard: SavedCard) {
        self.savedCard = savedCard
        if let expiry = savedCard.expiry {
            expiryDateLabel.text = "Exp: \(expiry)"
        }
        if let maskedPan = savedCard.maskedPan {
            let last4 = String(maskedPan.suffix(4))
            maskedCardNumberLabel.text = "Ending: \(last4)"

        }
        cardHolderNameLabel.text = savedCard.cardholderName?.uppercased()
        let cardProviderLogo = getCardLogo(scheme: savedCard.scheme!)
        logoImageView.image = UIImage(named: cardProviderLogo, in: NISdk.sharedInstance.getBundle(), compatibleWith: nil)
    }
    
    func getCardLogo(scheme: String) -> String {
        switch scheme {
        case "MASTERCARD":
            return "mastercardlogo"
        case "VISA":
            return "visalogo"
        case "DINERS_CLUB_INTERNATIONAL":
            return "dinerslogo"
        case "JCB":
            return "jcblogo"
        case "AMERICAN_EXPRESS":
            return "amexlogo"
        default:
            return "defaultlogo"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 3
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        return newString.count <= maxLength
    }
    
    @objc private func payButtonTapped() {
        guard self.savedCard != nil else {
            return
        }
        delegate?.didTapPayButton(withCVV: nil)
    }
    
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
