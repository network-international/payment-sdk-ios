//
//  SubscriptionDetails.swift
//  Pods
//
//  Created by Prasath R on 09/02/26.
//


import Foundation

struct SubscriptionDetails: Codable {
    let frequency: String
    let startDate: String
    let amount: String
    let lastPaymentDate: String
}
