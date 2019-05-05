//
//  OrderRequestPayload.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/26/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation

struct OrderRequestPayload : Codable {
    var amount: Amount
    var action : String
    var language : String
    var description : String
}
