//
//  RecurringDetails.swift
//  NISdk
//
//  Created by Prasath R on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

public struct RecurringDetails: Codable {
    public let numberOfTenure: Int
    public let recurringType: String
    public let startDate: String?
    public let endDate: String?
    public let recurringAmount: Amount?
}
