//
//  UIView+AutoLayout.swift
//  NISdk
//
//  Created by Johnny Peter on 17/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

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
    
    func anchor(width: NSLayoutDimension) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalTo: width).isActive = true
    }
    
    func anchor(height: NSLayoutDimension) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalTo: height).isActive = true
    }
    
    func anchor(widthConstant: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: widthConstant).isActive = true
    }
    
    func anchor(heightConstant: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: heightConstant).isActive = true
    }
    
    func alignCenterToCenterOf(parent: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
        centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
    }
    
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
        
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
