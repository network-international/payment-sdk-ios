//
//  UIScreen+Bounds.swift
//  NISdk
//
//  Created by Johnny Peter on 13/03/20.
//  Copyright © 2020 Network International. All rights reserved.
//

import Foundation

extension UIScreen {
    public var deviceScreenWidth: CGFloat {
        let screenBounds = UIScreen.main.bounds
        return screenBounds.width
    }
}
