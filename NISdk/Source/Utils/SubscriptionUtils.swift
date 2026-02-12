//
//  SubscriptionUtils.swift
//  Pods
//
//  Created by Prasath R on 09/02/26.
//


import Foundation

enum SubscriptionUtils {

    static func getSubscriptionDetails(order: OrderResponse) -> SubscriptionDetails? {
        guard
            isSubscriptionOrder(order: order),
            order.type == "RECURRING",
            let recurringDetails = order.recurringDetails,
            let startDate = recurringDetails.startDate,
            let endDate = recurringDetails.endDate
        else {
            return nil
        }

        return SubscriptionDetails(
            frequency: order.frequency ?? "",
            startDate: formatSimpleDate(startDate),
            amount: getSubscriptionAmount(amount: recurringDetails.recurringAmount),
            lastPaymentDate: formatSimpleDate(endDate)
        )
    }

    private static func getSubscriptionAmount(amount: Amount?) -> String {
        guard let amount = amount else { return "" }

        let orderAmount = Amount(
            currencyCode: amount.currencyCode, value: amount.value
        )

        return orderAmount.getFormattedAmount2Decimal()
    }

    static func isSubscriptionOrder(order: OrderResponse) -> Bool {
        return (order.type == "RECURRING" || order.type == "INSTALLMENT")
            && order.merchantAttributes?["paymentModel"] == "subscription"
    }

    static func formatSimpleDate(_ input: String) -> String {
        do {
            let normalizedInput: String
            if input.contains(".") {
                normalizedInput = input.components(separatedBy: ".")[0] + "Z"
            } else {
                normalizedInput = input
            }

            let inputFormatter = DateFormatter()
            inputFormatter.locale = Locale(identifier: "en_US_POSIX")
            inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "en_US_POSIX")
            outputFormatter.dateFormat = "dd/MM/yyyy"

            guard let date = inputFormatter.date(from: normalizedInput) else {
                return input
            }

            return outputFormatter.string(from: date)
        }
    }
}
