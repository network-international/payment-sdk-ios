//
//  SubscriptionDetailsCardView.swift
//  NISdk
//
//  Created by Prasath R on 02/02/26.
//

import UIKit
import SwiftUI

final class SubscriptionDetailsCardView: UIView {
    
    init(startDate: String,
         endDate: String,
         amount: String,
         frequency: String) {
        super.init(frame: .zero)
        setupUI(
            startDate: startDate,
            endDate: endDate,
            amount: amount,
            frequency: frequency
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(startDate: String,
                         endDate: String,
                         amount: String,
                         frequency: String) {
        
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.alignment = .fill
        
        addSubview(vStack)
        vStack.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            padding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        )
        
        vStack.addArrangedSubview(makeRow(title: "first_payment_date".localized, value: startDate))
        vStack.addArrangedSubview(makeRow(title: "last_payment_date".localized, value: endDate))
        vStack.addArrangedSubview(makeRow(title: "recurring_amount".localized, value: amount))
        vStack.addArrangedSubview(makeRow(title: "frequency".localized, value: (frequency + "_FREQUENCY").localized))
    }
    
    private func makeRow(title: String, value: String) -> UIView {

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill

        let isRTL = Locale.characterDirection(forLanguage: NISdk.sharedInstance.sdkLanguage) == .rightToLeft

        hStack.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = isRTL ? .right : .left

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .black
        valueLabel.textAlignment = isRTL ? .left : .right

        hStack.addArrangedSubview(titleLabel)
        hStack.addArrangedSubview(valueLabel)

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return hStack
    }
}
