//
//  UIView+InterfaceLayoutDirection.swift
//  NISdk
//
//  Created by Johnny Peter on 06/09/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension UIView {
    func getUILayoutDirection() -> UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
    }
}
