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
    
    func replaceURLs() -> String {
        let pattern = "(https?://[^\\s]+)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let string = self
        var result = string

        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))

        for match in matches.reversed() {
            let urlRange = Range(match.range, in: string)!
            let url = String(string[urlRange])
            let replacement = "[\(url)](\(url))"
            result = result.replacingCharacters(in: urlRange, with: replacement)
        }

        return result
    }
}
