//
//  PaymentOption.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

enum PaymentOption: Equatable {
    case applePay
    case card
    case savedCard(SavedCard)
    case clickToPay
    case aani
    case qpay
    case benefit
    /// Buy now, pay later — Tamara or Tabby. Both drive the same flow, so the provider rides along
    /// with the case rather than each getting one of its own.
    case bnpl(BnplProvider)
}
