//
//  VisaPlans.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//

import Foundation

class VisaPlans: NSObject, Codable {
    let matchedPlans : [MatchedPlan]
    
    enum CodingKeys: String, CodingKey {
        case matchedPlans
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        matchedPlans = try values.decodeIfPresent([MatchedPlan].self, forKey: .matchedPlans) ?? []
    }
}

extension VisaPlans {
    func toInstallmentPlans(fullAmount: Amount) -> [InstallmentPlan] {
        var plans: [InstallmentPlan] = [planPayInFull(fullAmount: fullAmount)]
        for matchedPlan in matchedPlans {            
            let currency: String? = matchedPlan.costInfo?.currency
            let totalUpFrontFees: String = Amount(currencyCode: currency, value: matchedPlan.costInfo?.totalUpfrontFees).getFormattedAmount2Decimal()
            let amount: String = Amount(currencyCode: currency, value: matchedPlan.costInfo?.lastInstallment?.totalAmount).getFormattedAmount2Decimal()
            
            let rate = String(format: "%.2f", ((matchedPlan.costInfo?.annualPercentageRate ?? 0.0) / 100.00))
            
            let iso2Code = Locale.iso639_2LanguageCode ?? ""
            
            let termsAndConditions = matchedPlan.termsAndConditions?.first { $0.languageCode == iso2Code }
            
            plans.append(InstallmentPlan(vPlanId: matchedPlan.vPlanID ?? "", amount: amount, totalUpFrontFees: totalUpFrontFees, rate: rate, numberOfInstallments: matchedPlan.numberOfInstallments ?? 0, frequency: getPlanFrequency(frequency: matchedPlan.installmentFrequency ?? ""), termsAndConditions: termsAndConditions))
        }
        return plans
    }
    
    private func planPayInFull(fullAmount: Amount) -> InstallmentPlan {
        return InstallmentPlan(vPlanId: UUID().uuidString, amount: fullAmount.getFormattedAmount2Decimal(), totalUpFrontFees: "", rate: "", numberOfInstallments: 0, frequency: .PayInFull)
    }
    
    private func getPlanFrequency(frequency: String) -> PlanFrequency {
        return switch(frequency) {
        case "MONTHLY":
            PlanFrequency.Monthly
        case "WEEKLY":
            PlanFrequency .Weekly
        case "BIMONTHLY":
            PlanFrequency.BiMonthly
        case "BIWEEKLY":
            PlanFrequency.BiWeekly
        default:
            PlanFrequency.PayInFull
        }
    }
}
