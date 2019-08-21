//
//  NICardPreview.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class CardPreviewController: UIViewController {
    var panLabel: UILabel?
    var cardHolderNameLabel: UILabel?
    var expiryDateLabel: UILabel?
    let defaultPanText = "---- ---- ---- ----"
    let defaultNameLabelText = "---"
    let defaultExpiryLabelText = "--/--"
    
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
    
    func setupProviderLogoView() -> UIView {
        let containerView = UIStackView()
        containerView.axis = .horizontal
        
        let cardLogo = UIImageView()
        cardLogo.image = UIImage(named: "mastercardlogo", in: Bundle(for: NISdk.self), compatibleWith: nil)
        cardLogo.contentMode = .scaleAspectFit
        containerView.addArrangedSubview(cardLogo)
        
        let deadSpaceView = UIView()
        containerView.addArrangedSubview(deadSpaceView)
        return containerView
    }
    
    @objc func didChangePan(_ notification: Notification) {
        if let data = notification.userInfo, let panLabel = panLabel {
            let pan = data["value"] as? String ?? ""
            if (pan).isEmpty {
               panLabel.text = defaultPanText
            } else {
                panLabel.text = pan
            }
        }
    }

    
    func setupPanView() -> UIView {
        let containerView = UIView()
        panLabel = UILabel()
        if let panLabel = panLabel {
            panLabel.font = UIFont(name: "OCRA", size: 20.0)
            
            panLabel.textColor = .white
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didChangePan(_:)),
                                                   name: .didChangePan, object: nil)
            panLabel.text = defaultPanText
            containerView.addSubview(panLabel)
            panLabel.anchor(top: containerView.topAnchor,
                            leading: containerView.leadingAnchor,
                            bottom: containerView.bottomAnchor,
                            trailing: containerView.trailingAnchor,
                            padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
        return containerView
    }
    
    func setupNameAndExpiryView() -> UIView {
        let containerView = UIView()
        let nameLabel = UILabel()
        nameLabel.font = UIFont(name: "OCRA", size: 13.0)
        nameLabel.textColor = .white
        nameLabel.text = defaultNameLabelText
        containerView.addSubview(nameLabel)
        
        nameLabel.anchor(top: containerView.topAnchor,
                         leading: containerView.leadingAnchor,
                         bottom: containerView.bottomAnchor,
                         trailing: nil,
                         padding: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        
        let expiryLabel = UILabel()
        expiryLabel.font = UIFont(name: "OCRA", size: 13.0)
        expiryLabel.textColor = .white
        expiryLabel.text = defaultExpiryLabelText
        containerView.addSubview(expiryLabel)
        
        expiryLabel.anchor(top: containerView.topAnchor,
                           leading: nil, bottom: containerView.bottomAnchor,
                           trailing: containerView.trailingAnchor,
                           padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        
        return containerView
    }
}
