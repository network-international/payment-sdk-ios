//
//  ClickToPayEmailViewController.swift
//  NISdk
//
//  Created on 09/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit
import ImageIO

class ClickToPayEmailViewController: UIViewController {

    // MARK: - Callbacks

    var onLoadMyCards: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Properties

    private let orderAmount: Amount?
    private var isInfoExpanded = false

    // MARK: - UI (Email form)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let emailField = UITextField()
    private let loadButton = UIButton()
    private let infoContentLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let errorLabel = UILabel()

    // MARK: - UI (Loading state)

    private let loadingOverlay = UIView()
    private let gifImageView = UIImageView()
    private var gifDisplayLink: CADisplayLink?
    private var gifFrames: [UIImage] = []
    private var gifFrameDelays: [Double] = []
    private var gifCurrentFrame: Int = 0
    private var gifAccumulator: Double = 0

    // MARK: - Init

    init(orderAmount: Amount?) {
        self.orderAmount = orderAmount
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopGifAnimation()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupScrollView()
        buildUI()
        setupLoadingOverlay()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If returning from the CTP webview (e.g. cancelled), hide loading
        if !loadingOverlay.isHidden {
            hideLoading()
        }
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout

    private func setupScrollView() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                          leading: view.safeAreaLayoutGuide.leadingAnchor,
                          bottom: view.safeAreaLayoutGuide.bottomAnchor,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor)
        scrollView.anchor(width: view.safeAreaLayoutGuide.widthAnchor)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        contentStack.anchor(top: scrollView.topAnchor,
                            leading: scrollView.leadingAnchor,
                            bottom: scrollView.bottomAnchor,
                            trailing: scrollView.trailingAnchor)
        contentStack.anchor(width: view.widthAnchor)
    }

    private func buildUI() {
        // 1. Title section: "Click to Pay" with bottom border
        let titleSection = createTitleSection()
        contentStack.addArrangedSubview(titleSection)

        // Padding wrapper for the rest of the content
        let bodyStack = UIStackView()
        bodyStack.axis = .vertical
        bodyStack.spacing = 32
        bodyStack.translatesAutoresizingMaskIntoConstraints = false

        // 2. Total amount box
        let amountBox = createAmountBox()
        bodyStack.addArrangedSubview(amountBox)

        // 3. Email input section
        let emailSection = createEmailSection()
        bodyStack.addArrangedSubview(emailSection)

        // 4. "Load my cards" button
        let buttonSection = createLoadButton()
        bodyStack.addArrangedSubview(buttonSection)

        // 5. Info section (divider + expandable)
        let infoSection = createInfoSection()
        bodyStack.addArrangedSubview(infoSection)

        // Body padding wrapper
        let bodyWrapper = UIView()
        bodyWrapper.translatesAutoresizingMaskIntoConstraints = false
        bodyWrapper.addSubview(bodyStack)
        bodyStack.anchor(top: bodyWrapper.topAnchor, leading: bodyWrapper.leadingAnchor,
                         bottom: bodyWrapper.bottomAnchor, trailing: bodyWrapper.trailingAnchor,
                         padding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32))

        contentStack.addArrangedSubview(bodyWrapper)
    }

    // MARK: - Loading Overlay

    private func setupLoadingOverlay() {
        loadingOverlay.backgroundColor = .white
        loadingOverlay.isHidden = true
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let overlayStack = UIStackView()
        overlayStack.axis = .vertical
        overlayStack.spacing = 0
        overlayStack.alignment = .fill
        overlayStack.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(overlayStack)

        NSLayoutConstraint.activate([
            overlayStack.topAnchor.constraint(equalTo: loadingOverlay.topAnchor),
            overlayStack.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor),
            overlayStack.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor),
        ])

        // Title section (same as email page)
        let titleSection = createTitleSection()
        overlayStack.addArrangedSubview(titleSection)

        // Loading content
        let loadingContentStack = UIStackView()
        loadingContentStack.axis = .vertical
        loadingContentStack.spacing = 32
        loadingContentStack.alignment = .center
        loadingContentStack.translatesAutoresizingMaskIntoConstraints = false

        // Loading text
        let loadingLabel = UILabel()
        loadingLabel.text = "Click to Pay is looking for your linked cards ...."
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        loadingLabel.textColor = UIColor(hexString: "#8F8F8F")
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 0
        loadingContentStack.addArrangedSubview(loadingLabel)

        // GIF image view
        gifImageView.contentMode = .scaleAspectFit
        gifImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gifImageView.widthAnchor.constraint(equalToConstant: 280),
            gifImageView.heightAnchor.constraint(equalToConstant: 200),
        ])
        loadingContentStack.addArrangedSubview(gifImageView)

        // Padding wrapper for loading content
        let loadingWrapper = UIView()
        loadingWrapper.translatesAutoresizingMaskIntoConstraints = false
        loadingWrapper.addSubview(loadingContentStack)
        loadingContentStack.anchor(top: loadingWrapper.topAnchor, leading: loadingWrapper.leadingAnchor,
                                    bottom: loadingWrapper.bottomAnchor, trailing: loadingWrapper.trailingAnchor,
                                    padding: UIEdgeInsets(top: 48, left: 32, bottom: 32, right: 32))

        overlayStack.addArrangedSubview(loadingWrapper)

        // Load GIF frames
        loadGifFrames()
    }

    private func showLoading() {
        view.endEditing(true)
        loadingOverlay.isHidden = false
        loadingOverlay.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.loadingOverlay.alpha = 1
        }
        startGifAnimation()
    }

    private func hideLoading() {
        stopGifAnimation()
        loadingOverlay.isHidden = true
        loadButton.isEnabled = true
        loadButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
        loadButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
    }

    // MARK: - GIF Animation

    private func loadGifFrames() {
        let bundle = NISdk.sharedInstance.getBundle()
        var gifUrl: URL?

        // Try resource bundle
        if let path = bundle.path(forResource: "ctp_cards_loader", ofType: "gif") {
            gifUrl = URL(fileURLWithPath: path)
        }

        // Fallback: framework bundle
        if gifUrl == nil, let path = Bundle(for: type(of: self)).path(forResource: "ctp_cards_loader", ofType: "gif") {
            gifUrl = URL(fileURLWithPath: path)
        }

        guard let url = gifUrl,
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return
        }

        let frameCount = CGImageSourceGetCount(source)
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                gifFrames.append(UIImage(cgImage: cgImage))
            }

            // Get frame delay
            var delay: Double = 0.1
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gifProps = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                if let unclampedDelay = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, unclampedDelay > 0 {
                    delay = unclampedDelay
                } else if let clampedDelay = gifProps[kCGImagePropertyGIFDelayTime as String] as? Double, clampedDelay > 0 {
                    delay = clampedDelay
                }
            }
            gifFrameDelays.append(delay)
        }

        // Show first frame
        if let firstFrame = gifFrames.first {
            gifImageView.image = firstFrame
        }
    }

    private func startGifAnimation() {
        guard !gifFrames.isEmpty else { return }
        gifCurrentFrame = 0
        gifAccumulator = 0
        gifDisplayLink = CADisplayLink(target: self, selector: #selector(updateGifFrame))
        gifDisplayLink?.add(to: .main, forMode: .common)
    }

    private func stopGifAnimation() {
        gifDisplayLink?.invalidate()
        gifDisplayLink = nil
    }

    @objc private func updateGifFrame() {
        guard !gifFrames.isEmpty else { return }
        guard let displayLink = gifDisplayLink else { return }

        gifAccumulator += displayLink.duration
        let frameDelay = gifFrameDelays[gifCurrentFrame]

        if gifAccumulator >= frameDelay {
            gifAccumulator -= frameDelay
            gifCurrentFrame = (gifCurrentFrame + 1) % gifFrames.count
            gifImageView.image = gifFrames[gifCurrentFrame]
        }
    }

    // MARK: - Title Section

    private func createTitleSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Click to Pay"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#070707")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(hexString: "#DADADA")
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(bottomBorder)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32),
            titleLabel.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor, constant: -32),

            bottomBorder.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),
        ])

        return container
    }

    // MARK: - Amount Box

    private func createAmountBox() -> UIView {
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.backgroundColor = UIColor(hexString: "#F9F9F9")
        box.layer.cornerRadius = 8
        box.layer.borderColor = UIColor(hexString: "#F5F5F5").cgColor
        box.layer.borderWidth = 1

        let totalLabel = UILabel()
        totalLabel.text = "Total"
        totalLabel.font = UIFont.systemFont(ofSize: 14, weight: .light)
        totalLabel.textColor = UIColor(hexString: "#070707")
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        let amountLabel = UILabel()
        amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        amountLabel.textColor = UIColor(hexString: "#070707")
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        // Format amount
        if let amount = orderAmount {
            amountLabel.text = amount.getFormattedAmount2Decimal()
        } else {
            amountLabel.text = ""
        }

        box.addSubview(totalLabel)
        box.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            box.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            totalLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            totalLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),

            amountLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: totalLabel.trailingAnchor, constant: 16),
        ])

        return box
    }

    // MARK: - Email Section

    private func createEmailSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Description label
        let descLabel = UILabel()
        descLabel.text = "Enter email to access a set of linked cards"
        descLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        descLabel.textColor = UIColor(hexString: "#070707")
        descLabel.numberOfLines = 0
        stack.addArrangedSubview(descLabel)

        // Email input box
        let inputBox = UIView()
        inputBox.translatesAutoresizingMaskIntoConstraints = false
        inputBox.layer.borderColor = UIColor(hexString: "#DADADA").cgColor
        inputBox.layer.borderWidth = 1
        inputBox.layer.cornerRadius = 8
        inputBox.backgroundColor = .white

        emailField.accessibilityIdentifier = "sdk_ctp_field_email"
        emailField.placeholder = "Email"
        emailField.font = UIFont.systemFont(ofSize: 16, weight: .light)
        emailField.textColor = UIColor(hexString: "#070707")
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.borderStyle = .none
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.addTarget(self, action: #selector(emailFieldChanged), for: .editingChanged)

        inputBox.addSubview(emailField)
        NSLayoutConstraint.activate([
            inputBox.heightAnchor.constraint(equalToConstant: 52),
            emailField.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 12),
            emailField.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -12),
            emailField.centerYAnchor.constraint(equalTo: inputBox.centerYAnchor),
        ])

        stack.addArrangedSubview(inputBox)

        // Error label (hidden by default)
        errorLabel.accessibilityIdentifier = "sdk_ctp_label_error"
        errorLabel.font = UIFont.systemFont(ofSize: 13)
        errorLabel.textColor = .red
        errorLabel.text = ""
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        stack.addArrangedSubview(errorLabel)

        return stack
    }

    // MARK: - Load Button

    private func createLoadButton() -> UIView {
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.accessibilityIdentifier = "sdk_ctp_button_load"
        loadButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
        loadButton.setTitle("Load my cards", for: .normal)
        loadButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
        loadButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loadButton.layer.cornerRadius = 8
        loadButton.addTarget(self, action: #selector(loadMyCardsTapped), for: .touchUpInside)

        loadButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        return loadButton
    }

    // MARK: - Info Section

    private func createInfoSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(hexString: "#DADADA")
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(divider)

        // Info toggle row
        let toggleRow = UIView()
        toggleRow.translatesAutoresizingMaskIntoConstraints = false

        let infoLabel = UILabel()
        infoLabel.text = "How does Click to Pay use my information?"
        infoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        infoLabel.textColor = UIColor(hexString: "#070707")
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            chevronImageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        }
        chevronImageView.tintColor = UIColor(hexString: "#070707")
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        toggleRow.addSubview(infoLabel)
        toggleRow.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            toggleRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            infoLabel.leadingAnchor.constraint(equalTo: toggleRow.leadingAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: toggleRow.centerYAnchor),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -12),

            chevronImageView.trailingAnchor.constraint(equalTo: toggleRow.trailingAnchor),
            chevronImageView.centerYAnchor.constraint(equalTo: toggleRow.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 24),
            chevronImageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        let toggleTap = UITapGestureRecognizer(target: self, action: #selector(infoToggleTapped))
        toggleRow.addGestureRecognizer(toggleTap)
        toggleRow.isUserInteractionEnabled = true

        stack.addArrangedSubview(toggleRow)

        // Info content (hidden by default)
        infoContentLabel.text = "Click to Pay securely stores your card information. When you enter your email, we look up cards linked to your account so you can pay without re-entering card details."
        infoContentLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        infoContentLabel.textColor = UIColor(hexString: "#8F8F8F")
        infoContentLabel.numberOfLines = 0
        infoContentLabel.isHidden = true
        infoContentLabel.alpha = 0

        stack.addArrangedSubview(infoContentLabel)

        return stack
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func loadMyCardsTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !email.isEmpty, email.contains("@") else {
            errorLabel.text = "Please enter a valid email address"
            errorLabel.isHidden = false
            return
        }

        errorLabel.isHidden = true
        loadButton.isEnabled = false
        loadButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
        loadButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonDisabledTitleColor, for: .normal)
        showLoading()
        onLoadMyCards?(email)
    }

    @objc private func emailFieldChanged() {
        if !errorLabel.isHidden {
            errorLabel.isHidden = true
        }
    }

    @objc private func infoToggleTapped() {
        isInfoExpanded.toggle()

        UIView.animate(withDuration: 0.25) {
            self.infoContentLabel.isHidden = !self.isInfoExpanded
            self.infoContentLabel.alpha = self.isInfoExpanded ? 1 : 0

            // Rotate chevron
            if self.isInfoExpanded {
                self.chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
            } else {
                self.chevronImageView.transform = .identity
            }

            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        if scrollView.contentInset.bottom != 0 {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}
