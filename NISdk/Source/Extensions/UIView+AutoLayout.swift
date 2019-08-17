//
//  UIView+AutoLayout.swift
//  NISdk
//
//  Created by Johnny Peter on 17/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension UIView {
    func anchor(top: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?,
                bottom: NSLayoutYAxisAnchor?, trailing: NSLayoutXAxisAnchor?,
                padding: UIEdgeInsets = .zero,
                size: CGSize = .zero) {
        
        translatesAutoresizingMaskIntoConstraints = false
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: padding.top).isActive = true
        }
        
        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: padding.left).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom).isActive = true
        }
        
        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: -padding.right).isActive = true
        }
        
        if(size.width != 0) {
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
        
        if(size.height != 0) {
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
    
    func pinAsBackground(to view: UIStackView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(self, at: 0)
        pin(to: view)
    }
    
    public func pin(to view: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
}
