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
    private let onPartiallyAuthorised: () -> Void
    
    init(partialAuthArgs: PartialAuthArgs,
         onSuccess: @escaping () -> Void,
         onFailed: @escaping () -> Void,
         onDecline: @escaping () -> Void,
         onPartialAuth: @escaping () -> Void
    ) {
        self.partialAuthArgs = partialAuthArgs
        self.onSuccess = onSuccess
        self.onFailed = onFailed
        self.onDecline = onDecline
        self.onPartiallyAuthorised = onPartialAuth
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
                    self.submitUserResponse(url: self.partialAuthArgs.acceptUrl)
                },
                onDecline: {
                    self.submitUserResponse(url: self.partialAuthArgs.declineUrl)
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
    
    private func submitUserResponse(url: String) {
        self.transectionService.partialAuth(
            with: url,
            using: partialAuthArgs.accessToken,
            on: {
                data, response, error in
                if error != nil {
                    self.onFailed()
                } else if let data = data {
                    do {
                        let response = try JSONDecoder().decode(PartialAuthActionResponse.self, from: data)
                        self.handleState(state: response.state)
                    } catch {
                        self.onFailed()
                    }
                } else {
                    self.onFailed()
                }
            })
    }
    
    private func handleState(state: String) {
        switch state {
        case "CAPTURED", "AUTHORISED", "VERIFIED", "PURCHASED":
            self.onSuccess()
        case "PARTIAL_AUTH_DECLINED":
            self.onDecline()
        case "PARTIAL_AUTH_DECLINE_FAILED":
            self.onFailed()
        case "PARTIALLY_AUTHORISED":
            self.onPartiallyAuthorised()
        default:
            self.onFailed()
        }
    }
    
    private func setupTitleButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = "Patial Auth Title".localized
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
}


class PartialAuthActionResponse: NSObject, Codable {
    let state: String
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.state = try container.decode(String.self, forKey: .state)
    }
}
