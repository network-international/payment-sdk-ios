//
//  MatchedPlan.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//

import Foundation

class MatchedPlan: NSObject, Codable {
    let costInfo : CostInfo?
    let installmentFrequency : String?
    let name : String?
    let numberOfInstallments : Int?
    let termsAndConditions : [TermsAndConditions]?
    let fundedBy : [String]?
    let type : String?
    let vPlanID : String?
    let vPlanIDRef : String?
    
    enum CodingKeys: String, CodingKey {
        case costInfo
        case installmentFrequency
        case name
        case numberOfInstallments
        case termsAndConditions
        case fundedBy
        case type
        case vPlanID
        case vPlanIDRef
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        costInfo = try values.decodeIfPresent(CostInfo.self, forKey: .costInfo)
        installmentFrequency = try values.decodeIfPresent(String.self, forKey: .installmentFrequency)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        numberOfInstallments = try values.decodeIfPresent(Int.self, forKey: .numberOfInstallments)
        termsAndConditions = try values.decodeIfPresent([TermsAndConditions].self, forKey: .termsAndConditions)
        fundedBy = try values.decodeIfPresent([String].self, forKey: .fundedBy)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        vPlanID = try values.decodeIfPresent(String.self, forKey: .vPlanID)
        vPlanIDRef = try values.decodeIfPresent(String.self, forKey: .vPlanIDRef)
    }
}
