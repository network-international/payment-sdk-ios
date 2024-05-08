//
//  VisaPlans.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//
import Foundation

class TermsAndConditions: NSObject, Codable {
    let text : String?
    let version : Int?
    let languageCode : String?
    let url : String?
    
    init(text: String, version: Int, languageCode: String, url: String) {
        self.text = text
        self.version = version
        self.languageCode = languageCode
        self.url = url
    }
    
    enum CodingKeys: String, CodingKey {
        case text
        case version
        case languageCode
        case url
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        version = try values.decodeIfPresent(Int.self, forKey: .version)
        languageCode = try values.decodeIfPresent(String.self, forKey: .languageCode)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }
    
    func getFormattedText() -> String {
        guard let text = text else {
            return ""
        }
        return text.replacingOccurrences(of: "\\n\\n", with: "\n\n")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "<", with: "(")
            .replacingOccurrences(of: ">", with: ")")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&gt;", with: ")")
            .replacingOccurrences(of: "&lt;", with: "(")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replaceURLs()
    }
}
