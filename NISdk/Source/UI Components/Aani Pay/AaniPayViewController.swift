//
//  AaniPayViewController.swift
//  NISdk
//
//  Created by Gautam Chibde on 02/08/24.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 14.0, *)
class AaniPayViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    private let aaniPayArgs: AaniPayArgs
    private let onCompletion: (AaniPaymentStatus) -> Void?
    private var viewModel: AaniViewModel?

    init(aaniPayArgs: AaniPayArgs, onCompletion: @escaping (AaniPaymentStatus) -> Void?) {
        self.onCompletion = onCompletion
        self.aaniPayArgs = aaniPayArgs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCancelButton()
        let vm = AaniViewModel(aaniPayArgs: aaniPayArgs, onCompletion: { status in
            self.finish(with: status)

        }, onPaymentProcessing: { status in
            self.updateCancelButtonWith(status: status)
        })
        self.viewModel = vm
        let child = UIHostingController(rootView: AaniPayView(viewModel: vm))

        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.presentationController?.delegate = self
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Block swipe-to-dismiss when QR is active — user must use the cancel button
        return viewModel?.viewType != .qrDisplay
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // VC is already dismissed by the swipe — clean up without calling finish()
        viewModel?.handleSwipeDismiss()
        onCompletion(.cancelled)
    }
    
    private func updateCancelButtonWith(status: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = status
    }
    
    private func setupCancelButton() {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.title = "Pay with Aani".localized
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        self.navigationItem.rightBarButtonItem = nil
    }
    
    private func finish(with status: AaniPaymentStatus) {
        self.dismiss(animated: true) {
            self.onCompletion(status)
        }
    }
    
    @objc func cancelAction() {
        finish(with: .cancelled)
    }
}
