//
//  UIViewController+Container.swift
//  NISdk
//
//  Created by Johnny Peter on 17/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension UIViewController {
    func add(_ child: UIViewController, inside container: UIView?) {
        addChild(child)
        if let container = container {
            container.addSubview(child.view)
            child.view.bindFrameToSuperviewBounds()
        } else {
            view.addSubview(child.view)
        }
    }
    
    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }
        
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
