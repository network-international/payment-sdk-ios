//
//  VisaPlans.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//
import Foundation

class CostInfo: NSObject, Codable {
    let currency : String?
    let lastInstallment : LastInstallment?
    let totalFees : Double?
    let totalPlanCost : Double?
    let totalRecurringFees : Double?
    let totalUpfrontFees : Double?
    let annualPercentageRate : Double
    
    enum CodingKeys: String, CodingKey {
        case currency
        case lastInstallment
        case totalFees
        case totalPlanCost
        case totalRecurringFees
        case totalUpfrontFees
        case annualPercentageRate
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        currency = try values.decodeIfPresent(String.self, forKey: .currency)
        lastInstallment = try values.decodeIfPresent(LastInstallment.self, forKey: .lastInstallment)
        totalFees = try values.decodeIfPresent(Double.self, forKey: .totalFees)
        totalPlanCost = try values.decodeIfPresent(Double.self, forKey: .totalPlanCost)
        totalRecurringFees = try values.decodeIfPresent(Double.self, forKey: .totalRecurringFees)
        totalUpfrontFees = try values.decodeIfPresent(Double.self, forKey: .totalUpfrontFees)
        annualPercentageRate = try values.decodeIfPresent(Double.self, forKey: .annualPercentageRate) ?? 0
    }
}
