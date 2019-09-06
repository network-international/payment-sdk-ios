//
//  String+RemoveWhitespace.swift
//  NISdk
//
//  Created by Johnny Peter on 25/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension String {
    func replace(string:String, replacement:String) -> String {
        return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
    }
    
    func removeWhitespace() -> String {
        return self.replace(string: " ", replacement: "")
    }
}
