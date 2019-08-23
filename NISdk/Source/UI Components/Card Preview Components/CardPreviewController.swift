//
//  NICardPreview.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class CardPreviewController: UIViewController {
    let panLabel = UILabel()
    let cardHolderNameLabel = UILabel()
    let expiryDateLabel = UILabel()
    let cardLogo = UIImageView()
    var cardProvider: CardProvider?
    
    let defaultPanText = "---- ---- ---- ----"
    let defaultNameLabelText = "---"
    let defaultExpiryLabelText = "--/--"
    var cardProviderLogo: String {
        switch self.cardProvider {
        case .masterCard?:
            return "mastercardlogo"
        case .visa?:
            return "visalogo"
        case .dinersClubInternational?:
            return "dinerslogo"
        case .jcb?:
            return "jcblogo"
        case .americanExpress?:
            return "amexlogo"
            
        case .discover?:
            return "discoverlogo"
            
        case .visaElectron?, .maestro?:
            return "defaultlogo"
        default:
            return "defaultlogo"
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let providerLogoView = setupProviderLogoView()
        let panView = setupPanView()
        let nameAndExpiryView = setupNameAndExpiryView()
        
        let vStack = UIStackView(arrangedSubviews: [providerLogoView, panView, nameAndExpiryView])
        
        vStack.axis = .vertical
        vStack.distribution = .fillEqually
        vStack.spacing = 0
        
        view.addSubview(vStack)
        vStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = UIColor(hexString: "#171618")
        stackBackgroundView.pinAsBackground(to: vStack)
        stackBackgroundView.layer.cornerRadius = 16
        
        vStack.bindFrameToSuperviewBounds()
    }
    
    func updateCardLogo() {
        let cardLogoImage = UIImage(named: self.cardProviderLogo, in: Bundle(for: NISdk.self), compatibleWith: nil)
        cardLogo.image = cardLogoImage
    }
    
    func setupProviderLogoView() -> UIView {
        let containerView = UIStackView()
        containerView.axis = .horizontal
        containerView.alignment = .center
        
        cardLogo.contentMode = .scaleAspectFill
        updateCardLogo()
        cardLogo.contentMode = .scaleAspectFit
        containerView.addArrangedSubview(cardLogo)
        cardLogo.anchor(top: nil, leading: nil, bottom: nil, trailing: nil, padding: .zero, size: CGSize(width: 60, height: 0))
        
        let deadSpaceView = UIView()
        containerView.addArrangedSubview(deadSpaceView)
        return containerView
    }
    
    @objc func didChangePan(_ notification: Notification) {
        if let data = notification.userInfo {
            let pan = data["value"] as? String ?? ""
            if (pan).isEmpty {
                panLabel.text = defaultPanText
            } else {
//                let pan = pan.group(by: 4, separator: " ")
                panLabel.text = pan
            }
            if let cardProvider = data["cardProvider"] as? CardProvider {
                self.cardProvider = cardProvider
            }
        }
        updateCardLogo()
    }
    
    func setupPanView() -> UIView {
        let containerView = UIView()
        panLabel.font = UIFont(name: "OCRA", size: 20.0)
        
        panLabel.textColor = .white
        panLabel.text = defaultPanText
        containerView.addSubview(panLabel)
        panLabel.anchor(top: containerView.topAnchor,
                        leading: containerView.leadingAnchor,
                        bottom: containerView.bottomAnchor,
                        trailing: containerView.trailingAnchor,
                        padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePan(_:)),
                                               name: .didChangePan, object: nil)
        return containerView
    }
    
    @objc func didChangeCardHolderName(_ notification: Notification) {
        if let data = notification.userInfo {
            let cardHolderName = data["value"] as? String ?? ""
            if (cardHolderName).isEmpty {
                cardHolderNameLabel.text = defaultNameLabelText
            } else {
                cardHolderNameLabel.text = cardHolderName
            }
        }
    }
    
    @objc func didChangeExpiry(_ notification: Notification) {
        if let data = notification.userInfo {
            var expiryMonth = data["month"] as? String ?? ""
            var expiryYear = data["year"] as? String ?? ""
            if (expiryMonth).isEmpty {
                expiryMonth = "--"
            }
            if(expiryYear).isEmpty {
                expiryYear = "--"
            }
            expiryDateLabel.text = "\(expiryMonth)/\(expiryYear)"
        }
    }
    
    func setupNameAndExpiryView() -> UIView {
        let containerView = UIView()
        cardHolderNameLabel.font = UIFont(name: "OCRA", size: 13.0)
        cardHolderNameLabel.textColor = .white
        cardHolderNameLabel.text = defaultNameLabelText
        containerView.addSubview(cardHolderNameLabel)
        
        cardHolderNameLabel.anchor(top: containerView.topAnchor,
                         leading: containerView.leadingAnchor,
                         bottom: containerView.bottomAnchor,
                         trailing: nil,
                         padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeCardHolderName(_:)),
                                               name: .didChangeCardHolderName, object: nil)
        
        expiryDateLabel.font = UIFont(name: "OCRA", size: 13.0)
        expiryDateLabel.textColor = .white
        expiryDateLabel.text = defaultExpiryLabelText
        containerView.addSubview(expiryDateLabel)
        
        expiryDateLabel.anchor(top: containerView.topAnchor,
                           leading: nil, bottom: containerView.bottomAnchor,
                           trailing: containerView.trailingAnchor,
                           padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeExpiry(_:)),
                                               name: .didChangeExpiryDate, object: nil)
        return containerView
    }
}
