//
//  OrderResponse.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/26/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation

struct OrderResponse :Codable {
    var orderReference: String
    var paymentAuthorizationUrl: String
    var code: String
}
