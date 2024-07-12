//
//  PartialAuthViewController.swift
//  NISdk
//
//  Created by Gautam Chibde on 08/07/24.
//

import Foundation
import SwiftUI
import UIKit

class PartialAuthViewController: UIViewController {
    
    private let partialAuthArgs: PartialAuthArgs
    private let transectionService: TransactionService
    private let onSuccess: () -> Void?
    private let onDecline: () -> Void?
    private let onFailed: () -> Void?
    
    init(partialAuthArgs: PartialAuthArgs,
         onSuccess: @escaping () -> Void,
         onFailed: @escaping () -> Void,
         onDecline: @escaping () -> Void
    ) {
        self.partialAuthArgs = partialAuthArgs
        self.onSuccess = onSuccess
        self.onFailed = onFailed
        self.onDecline = onDecline
        transectionService = TransactionServiceAdapter()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTitleButton()
        let child = UIHostingController(
            rootView: PartialAuthView(
                issuingOrg: partialAuthArgs.issuingOrg,
                partialAmount: partialAuthArgs.getPartialAmountFormatted(),
                amount: partialAuthArgs.getAmountFormatted(),
                onAccept: {
                    self.partialAuthAccept()
                },
                onDecline: {
                    self.partialAuthDecline()
                })
        )
        addChild(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func partialAuthAccept() {
        self.transectionService.partialAuthAccept(
            with: partialAuthArgs.acceptUrl,
            using: partialAuthArgs.accessToken,
            on: { data, response, error in
                if error != nil {
                    self.onFailed()
                } else if let _ = data {
                    self.onSuccess()
                } else {
                    self.onFailed()
                }
            }
        )
    }
    
    private func partialAuthDecline() {
        self.transectionService.partialAuthAccept(
            with: partialAuthArgs.declineUrl,
            using: partialAuthArgs.accessToken,
            on: { data , _, _  in
                if let _ = data {
                    self.onDecline()
                }
                self.onFailed()
            }
        )
    }
    
    private func setupTitleButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = "Patial Auth Title".localized
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
}
