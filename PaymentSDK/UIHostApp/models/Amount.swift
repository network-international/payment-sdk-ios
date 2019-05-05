//
//  Amount.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/26/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation

struct Amount : Codable {
    var currencyCode: String
    var value: Int
}
