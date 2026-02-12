//
//  TermsAndConditionsView.swift
//  Pods
//
//  Created by Prasath R on 09/02/26.
//

import UIKit

final class TermsAndConditionsView: UIView {

    private let checkbox = UIButton(type: .custom)
    private let label = UILabel()
    private let errorLabel = UILabel()

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
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        checkbox.tintColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
        checkbox.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)

        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        label.addGestureRecognizer(tap)

        errorLabel.textColor = .red
        errorLabel.font = UIFont.systemFont(ofSize: 11)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let horizontalStack = UIStackView(arrangedSubviews: [checkbox, label])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 6
        horizontalStack.alignment = .top

        let verticalStack = UIStackView(arrangedSubviews: [horizontalStack, errorLabel])
        verticalStack.axis = .vertical
        verticalStack.spacing = 4

        addSubview(verticalStack)
        verticalStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func isAccepted() -> Bool {
        return isChecked
    }

    func showValidationError() {
        errorLabel.text = "Please accept Terms and Conditions".localized
        errorLabel.isHidden = false
    }

    func clearValidationError() {
        errorLabel.text = nil
        errorLabel.isHidden = true
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

    func validate() -> Bool {
        if !isChecked {
            showError("Please accept Terms and Conditions".localized)
            return false
        }
        hideError()
        return true
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func hideError() {
        errorLabel.text = nil
        errorLabel.isHidden = true
    }

    @objc private func toggleCheckbox() {
        isChecked.toggle()
        checkbox.isSelected = isChecked
        clearValidationError()
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
