//
//  ProductViewCell.swift
//  Simple Integration
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

class ProductViewCell: UICollectionViewCell {
    let productLabel = UILabel()
    let priceLabel = UILabel()
    var price: Double = 0

    private static let niBlue = UIColor(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addViews()
    }

    func updateBorder(selected: Bool) {
        if selected {
            contentView.layer.borderColor = ProductViewCell.niBlue.cgColor
            contentView.layer.borderWidth = 2
            contentView.backgroundColor = ProductViewCell.niBlue.withAlphaComponent(0.05)
        } else {
            contentView.layer.borderColor = UIColor.separator.cgColor
            contentView.layer.borderWidth = 1
            contentView.backgroundColor = UIColor.secondarySystemBackground
        }
    }

    func setProduct(product: Product) {
        productLabel.text = product.name
        price = product.amount
        priceLabel.text = String(format: "%.2f", price)
        accessibilityIdentifier = "product_cell_\(product.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    func addViews() {
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.secondarySystemBackground

        productLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        productLabel.textColor = .secondaryLabel
        productLabel.textAlignment = .center
        productLabel.accessibilityIdentifier = "product_label_name"

        priceLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        priceLabel.textColor = .label
        priceLabel.textAlignment = .center
        priceLabel.accessibilityIdentifier = "product_label_price"

        let vStack = UIStackView(arrangedSubviews: [priceLabel, productLabel])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 4
        contentView.addSubview(vStack)

        updateBorder(selected: false)

        vStack.anchor(top: contentView.topAnchor, leading: contentView.leadingAnchor,
                     bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor,
                     padding: UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12),
                     size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
