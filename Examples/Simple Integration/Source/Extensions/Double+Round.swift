//
//  Double+Round.swift
//  Simple Integration
//
//  Created by Johnny Peter on 01/04/20.
//  Copyright © 2020 Network International. All rights reserved.
//

import Foundation

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
