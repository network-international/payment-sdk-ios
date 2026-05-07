//
//  OrderItem.swift
//  NISdk
//

import Foundation

public struct OrderItem {
    public let name: String
    public let amount: String

    public init(name: String, amount: String) {
        self.name = name
        self.amount = amount
    }
}
