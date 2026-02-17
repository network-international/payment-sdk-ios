//
//  PaymentResultViewController.swift
//  NISdk
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
class PaymentResultViewController: UIViewController {

    private let args: PaymentResultArgs
    private let onDone: () -> Void

    init(args: PaymentResultArgs, onDone: @escaping () -> Void) {
        self.args = args
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Hide navigation bar cancel button on result screen
        self.parent?.navigationItem.rightBarButtonItem = nil
        self.parent?.navigationItem.leftBarButtonItem = nil
        self.parent?.navigationItem.hidesBackButton = true
        self.parent?.navigationItem.title = ""

        let child = UIHostingController(
            rootView: PaymentResultView(
                args: args,
                onDone: { [weak self] in
                    self?.onDone()
                }
            )
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
}
