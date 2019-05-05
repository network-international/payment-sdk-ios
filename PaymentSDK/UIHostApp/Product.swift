//
//  Product.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/23/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation

struct Product : Codable{
    var id:String
    var info: Info
    var prices: [Price]
    var quantity: Double
    
    struct Info : Codable{
        var name:String
        var locale:String
        var productDescription:String
        var image:String
    }
    
    struct Price : Codable{
        var total: Double
        var tax: Double
        var currency: String
    }
    
}




