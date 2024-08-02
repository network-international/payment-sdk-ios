//
//  PartialAuthView.swift
//  NISdk
//
//  Created by Gautam Chibde on 08/07/24.
//

import SwiftUI

struct PartialAuthView: View {
    @State private var paymentProcessing: Bool = false
    let issuingOrg: String?
    let partialAmount: String
    let amount: String
    
    let onAccept: () -> Void?
    let onDecline: () -> Void?
    
    var body: some View {
        VStack {
            Divider()
            Image("networklogo", bundle: NISdk.sharedInstance.getBundle())
                .resizable()
                .frame(width: 300, height: 52)
                .aspectRatio(contentMode: .fit)
                .padding(.vertical)
            
            let titleText = if (issuingOrg != nil) {
                String.localizedStringWithFormat(
                    "Partial Auth Message With Org".localized,
                    issuingOrg ?? "",
                    partialAmount,
                    amount
                )
            } else {
                String.localizedStringWithFormat(
                    "Partial Auth Message".localized,
                    partialAmount,
                    amount
                )
            }
            Divider()
            Text(titleText)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            Divider()
            Text("Partial Auth Message Question".localized)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            HStack {
                if (paymentProcessing) {
                    HStack {
                        Text("Processing Payment".localized)
                        ActivityIndicator()
                    }
                } else {
                    Button(action: {
                        paymentProcessing = true
                        onAccept()
                    }) {
                        Text("Yes".localized)
                    }
                    .buttonStyle(PaymentButtonStyle(enabled: true))
                    Button(action: {
                        paymentProcessing = true
                        onDecline()
                    }) {
                        Text("Cancel Alert".localized)
                    }
                    .buttonStyle(BorderButtonStyle())
                }
            }.padding(.vertical)
        }.padding(.horizontal)
    }
}

struct BorderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: 44)
            .foregroundColor(.red)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.red, lineWidth: 1)
            )
    }
}

#Preview {
    PartialAuthView(
        issuingOrg: "HDBC",
        partialAmount: "100 AED",
        amount: "1000 AED",
        onAccept: {},
        onDecline: {}
    )
}
