//
//  VisaPlans.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//

import Foundation

class LastInstallment: NSObject, Codable {
	let amount : Int?
	let installmentFee : Int?
	let totalAmount : Double?
	let upfrontFee : Int?

	enum CodingKeys: String, CodingKey {

		case amount
		case installmentFee
		case totalAmount
		case upfrontFee
	}

    required public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		amount = try values.decodeIfPresent(Int.self, forKey: .amount)
		installmentFee = try values.decodeIfPresent(Int.self, forKey: .installmentFee)
		totalAmount = try values.decodeIfPresent(Double.self, forKey: .totalAmount)
		upfrontFee = try values.decodeIfPresent(Int.self, forKey: .upfrontFee)
	}

}
