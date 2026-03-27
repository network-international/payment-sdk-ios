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
            guard let tokenValue = tokenSubComponents.first(where: { $0.contains(tokenPattern) }),
                  let extractedValue = tokenValue.components(separatedBy: "\(tokenPattern)=").last else {
                continue
            }
            requiredTokens[tokenPattern] = extractedValue
        }
        return requiredTokens
    }
}
