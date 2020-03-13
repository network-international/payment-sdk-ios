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
        let language = NISdk.sharedInstance.sdkLanguage
        let direction = Locale.characterDirection(forLanguage: language)
        return direction == .leftToRight ? UIUserInterfaceLayoutDirection.leftToRight : UIUserInterfaceLayoutDirection.rightToLeft
    }
    
    func setInterfaceLayoutDirection() {
        let language = NISdk.sharedInstance.sdkLanguage
        let direction = Locale.characterDirection(forLanguage: language)
        if (direction == .rightToLeft) {
            self.semanticContentAttribute = .forceRightToLeft
        } else {
             self.semanticContentAttribute = .forceLeftToRight
        }
    }
}
