//
//  TermsAndConditionsView.swift
//  NISDK
//
//  Created by Prasath R on 09/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

final class TermsAndConditionsView: UIView {

    private let checkbox = UIButton(type: .custom)
    private let label = UILabel()

    private var isChecked = false
    private var linkRange: NSRange?
    private var linkUrl: String?

    var onCheckedChange: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        checkbox.setPreferredSymbolConfiguration(config, forImageIn: .normal)

        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        checkbox.tintColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor

        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.widthAnchor.constraint(equalToConstant: 24).isActive = true
        checkbox.heightAnchor.constraint(equalToConstant: 24).isActive = true

        checkbox.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)

        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        label.addGestureRecognizer(tap)

        let horizontalStack = UIStackView(arrangedSubviews: [checkbox, label])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 8
        horizontalStack.alignment = .center
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }


    func isAccepted() -> Bool {
        return isChecked
    }

    func updateTermsUrl(_ url: String) {
        self.linkUrl = url
    }

    func configure(
        termsText: String,
        linkText: String,
        termsUrl: String
    ) {
        self.linkUrl = termsUrl

        let attributed = NSMutableAttributedString(
            string: termsText,
            attributes: [
                .foregroundColor: UIColor.gray,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )

        let nsText = termsText as NSString
        let range = nsText.range(of: linkText)

        if range.location != NSNotFound {
            attributed.addAttributes([
                .foregroundColor: NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor,
                .font: UIFont.boldSystemFont(ofSize: 12),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: range)

            self.linkRange = range
        }

        label.attributedText = attributed
    }

    @objc private func toggleCheckbox() {
        isChecked.toggle()
        checkbox.isSelected = isChecked
        onCheckedChange?(isChecked)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard
            let range = linkRange,
            let text = label.attributedText,
            let urlString = linkUrl,
            let url = URL(string: urlString)
        else { return }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let storage = NSTextStorage(attributedString: text)

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines

        let location = gesture.location(in: label)
        let index = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        if NSLocationInRange(index, range) {
            UIApplication.shared.open(url)
        }
    }
}
