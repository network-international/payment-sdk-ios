//
//  SettingsDelegate.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/24/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation

protocol SettingsDelegate: class {
    
    func didEmailChange(_ email: String)
    
    func didCurrencyChange(_ currency: String)

}
