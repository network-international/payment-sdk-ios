//
//  AaniPayViewController.swift
//  NISdk
//
//  Created by Gautam Chibde on 02/08/24.
//

import Foundation
import UIKit
import SwiftUI

class AaniPayViewController: UIViewController {
    
    private let aaniPayArgs: AaniPayArgs
    private let onCompletion: (AaniPaymentStatus) -> Void?
    
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
        let child = UIHostingController(rootView: AaniPayView(viewModel: AaniViewModel(aaniPayArgs: aaniPayArgs, onCompletion: { status in
            self.finish(with: status)
            
        }, onPaymentProcessing: { status in
            self.updateCancelButtonWith(status: status)
        })))
        
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
    
    private func updateCancelButtonWith(status: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = status
    }
    
    private func setupCancelButton() {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.title = "Aani Pay"
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Cancel".localized, style: .done, target: self, action: #selector(self.cancelAction))
    }
    
    private func finish(with status: AaniPaymentStatus) {
        self.dismiss(animated: true)
        self.onCompletion(status)
    }
    
    @objc func cancelAction() {
        finish(with: .cancelled)
    }
}
