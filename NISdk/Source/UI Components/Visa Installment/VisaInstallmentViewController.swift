//
//  VisaInstallmentViewController.swift
//  NISdk
//
//  Created by Gautam Chibde on 16/04/24.
//

import Foundation
import UIKit
import SwiftUI

class VisaInstallmentViewController: UIViewController {
    let visaPlan: VisaPlans
    let fullAmount: Amount
    let onCancel: () -> Void?
    let cardNumber: String
    let onMakePayment: (VisaRequest?) -> Void
    
    init(visaPlan: VisaPlans, fullAmount: Amount, cardNumber: String, onMakePayment: @escaping (VisaRequest?) -> Void, onCancel: @escaping () -> Void) {
        self.visaPlan = visaPlan
        self.fullAmount = fullAmount
        self.onCancel = onCancel
        self.cardNumber = cardNumber
        self.onMakePayment = onMakePayment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCancelButton()
        let installmentPlans = visaPlan.toInstallmentPlans(fullAmount: fullAmount)
        let child = UIHostingController(rootView: VisaInstallmentView(plans: installmentPlans, cardNumber: cardNumber, onMakePayment: { plan in
            self.updateCancelButtonWith(status: false)
            let visRequest: VisaRequest? = if plan.frequency != .PayInFull {
                VisaRequest(planSelectionIndicator: true, acceptedTAndCVersion: plan.termsAndConditions?.version, vPlanId: plan.vPlanId)
            } else {
                nil
            }
            self.onMakePayment(visRequest)
        }))
        
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
        self.parent?.navigationItem.rightBarButtonItem?.isEnabled = status
    }
    
    private func setupCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = "Make Payment".localized
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        self.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Cancel".localized, style: .done, target: self, action: #selector(self.cancelAction))
    }
    
    @objc func cancelAction() {
        self.onCancel();
    }
}
