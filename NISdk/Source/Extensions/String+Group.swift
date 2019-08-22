//
//  String+Group.swift
//  NISdk
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension String {
    func group(by groupSize: Int = 4, separator: String = " ") -> String {
        if count <= groupSize   { return self }
        
        let splitSize  = min(max(2, count - 2) , groupSize)
        let splitIndex = index(startIndex, offsetBy:splitSize)
        
        return String(self[..<splitIndex])
            + separator
            + String(self[splitIndex...]).group(by:groupSize, separator:separator)
    }
}
