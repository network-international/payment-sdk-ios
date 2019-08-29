//
//  TokenUtils.swift
//  NISdk
//
//  Created by Johnny Peter on 28/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class TokenUtils {
    static func extractTokens(headerValue: String, tokenPatterns: [String]) -> [String:String] {
        let tokens: [String] = headerValue.components(separatedBy: ",") // Get the two top level token strings
        var tokenSubComponents: [String] = []
        for tokenComponent in tokens { // Get all substrings within a token field
            tokenSubComponents.append(contentsOf: tokenComponent.components(separatedBy: ";"))
        }
        var requiredTokens: [String:String] = [:]
        for tokenPattern in tokenPatterns {
            let tokenValue: String = tokenSubComponents.filter { $0.contains(tokenPattern) }[0]
            requiredTokens[tokenPattern] = tokenValue.components(separatedBy: "\(tokenPattern)=")[1]
        }
        return requiredTokens
    }
}
