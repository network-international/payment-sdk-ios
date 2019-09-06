//
//  String+URLEncode.swift
//  NISdk
//
//  Created by Johnny Peter on 05/09/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension String {
    func encodeAsURL() -> String {
        var validCharacters = CharacterSet.alphanumerics
        validCharacters.insert(charactersIn: "-._* ")
        return self.addingPercentEncoding(withAllowedCharacters: validCharacters)!.replacingOccurrences(of: " ", with: "+")
    }
}
