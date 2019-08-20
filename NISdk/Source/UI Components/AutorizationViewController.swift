//
//  AutorizationViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class AuthorizationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let authorizationLabel = UILabel()
        authorizationLabel.text = "Authorizing Payment..."
        
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.isHidden = false
        spinner.startAnimating()
        
        let vStack = UIStackView(arrangedSubviews: [authorizationLabel, spinner])
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .center
        
        view.addSubview(vStack)
        vStack.anchor(top: nil,
                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                      bottom: nil,
                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                      padding: .zero,
                      size: CGSize(width: 0, height: 100))
        
        vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
