//
//  AaniInputScreen.swift
//  NISdk
//
//  Created by Gautam Chibde on 06/08/24.
//

import SwiftUI

struct AaniInputScreen: View {
    @State private var selectedIdType: AaniIDType = .mobileNumber
    @State private var inputText: String = ""
    @State private var paymentProcessing: Bool = false
    let onSubmit: (AaniIDType, String) -> Void

    var body: some View {
        VStack {
            Image("aaniLogo", bundle: NISdk.sharedInstance.getBundle())
                .scaledToFit()
                .frame(height: 100)
                .padding(20)
            Divider()

            HStack {
                Spacer()
                Picker("Select ID Type", selection: $selectedIdType) {
                    ForEach(AaniIDType.allCases, id: \.self) { idType in
                        Text(idType.text).tag(idType).font(.subheadline)
                    }
                }
                .accentColor(.black)
                .disabled(paymentProcessing)
            }
            Divider()

            HStack {
                if selectedIdType == .mobileNumber {
                    Text("+971")
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    Spacer()
                }

                TextField(selectedIdType.sample, text: $inputText)
                    .keyboardType(self.keyboardTypeFor(inputType: $selectedIdType))
                    .id(selectedIdType.id)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    .onChange(of: inputText) { newValue in
                        inputText = formatInputText(newValue, for: selectedIdType)
                    }
                    .onChange(of: selectedIdType) { newType in
                        if newType == .emiratesID {
                            inputText = formatInputText("784-", for: .emiratesID)
                        } else {
                            inputText = ""
                        }
                    }
                    .disabled(paymentProcessing)
            }
            .padding(.vertical)

            let isButtonEnabled = selectedIdType.isValid(text: inputText) && !paymentProcessing

            Button(action: {
                onSubmit(selectedIdType, inputText)
                paymentProcessing = true
            }) {
                if paymentProcessing {
                    HStack {
                        Text("Processing Payment".localized)
                        ActivityIndicator()
                    }
                } else {
                    Text("Make Payment".localized)
                }
            }
            .disabled(!isButtonEnabled)
            .buttonStyle(PaymentButtonStyle(enabled: isButtonEnabled))
        }
        .padding()
    }
    
    private func keyboardTypeFor(inputType: Binding<AaniIDType>) -> UIKeyboardType {
        switch inputType.wrappedValue {
        case .emailID:
            return .emailAddress
        case .mobileNumber, .emiratesID:
            return .numberPad
        default:
            return .default
        }
    }

    private func formatInputText(_ text: String, for inputType: AaniIDType) -> String {
        switch inputType {
        case .emiratesID:
            let prefix = "784-"
            guard text.count >= prefix.count else { return prefix }
            
            let digitsOnly = String(text.dropFirst(prefix.count).filter { $0.isNumber }.prefix(inputType.maxLength - prefix.count))
            var formatted = prefix
            let parts = [4, 7, 1]
            var index = digitsOnly.startIndex
            
            for part in parts {
                guard index < digitsOnly.endIndex else { break }
                let end = digitsOnly.index(index, offsetBy: part, limitedBy: digitsOnly.endIndex) ?? digitsOnly.endIndex
                formatted += digitsOnly[index..<end]
                if end != digitsOnly.endIndex {
                    formatted += "-"
                }
                index = end
            }
            return formatted
        case .mobileNumber:
            return String(text.prefix(inputType.maxLength).filter { $0.isNumber })
        case .passportID:
            return String(text.prefix(inputType.maxLength)).uppercased()
        case .emailID:
            return String(text.prefix(inputType.maxLength)).lowercased()
        }
    }
}

#Preview {
    AaniInputScreen { _, _ in }
}
