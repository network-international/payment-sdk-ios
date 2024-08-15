//
//  AaniInputScreen.swift
//  NISdk
//
//  Created by Gautam Chibde on 06/08/24.
//

import SwiftUI

struct AaniInputScreen: View {
    
    @State var selectedIdType: AaniIDType = .mobileNumber
    @State var inputText: String = ""
    @State var paymentProcessing: Bool = false
    let onSubmit: (AaniIDType, String) -> Void?
    
    var body: some View {
        VStack {
            Image("aaniLogo", bundle: NISdk.sharedInstance.getBundle())
                .scaledToFit()
                .frame(height: 100)
                .padding(20)
            Divider()
            
            HStack {
                Text("aani_alias_type".localized).font(.headline)
                Spacer()
                Picker("Select ID Type", selection: $selectedIdType) {
                    ForEach(AaniIDType.allCases, id: \.self) { idType in
                        Text(idType.text).tag(idType).font(.subheadline)
                    }
                }.accentColor(.black)
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
                    }.onChange(of: selectedIdType) { newType in
                        inputText = ""
                    }.disabled(paymentProcessing)
                
            }.padding(.vertical)
            
            let isButtonEnable = !selectedIdType.isValid(text: inputText) || paymentProcessing
            Button(action: {
                onSubmit(selectedIdType, inputText)
                paymentProcessing = true
            }) {
                if (paymentProcessing) {
                    HStack {
                        Text("Processing Payment".localized)
                        ActivityIndicator()
                    }
                } else {
                    Text("Submit".localized)
                }
            }.buttonStyle(PaymentButtonStyle(enabled: !isButtonEnable))
        }
        .padding()
    }
    
    private func keyboardTypeFor(inputType: Binding<AaniIDType>) -> UIKeyboardType {
        switch inputType.wrappedValue {
        case .emailID:
            return .emailAddress
        case .mobileNumber, .emiratesID:
            return .phonePad
        default:
            return .default
        }
    }
    
    private func formatInputText(_ text: String, for inputType: AaniIDType) -> String {
        switch inputType {
        case .emiratesID:
            let digitsOnly = String(text.filter { $0.isNumber }.prefix(inputType.maxLength))
            var formatted = ""
            let parts = [3, 4, 7, 1]
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
            return String(text.prefix(inputType.maxLength))
        case .passportID:
            return String(text.prefix(inputType.maxLength)).uppercased()
        case .emailID:
            return String(text.prefix(inputType.maxLength)).lowercased()
        }
    }
}

#Preview {
    AaniInputScreen() { _, _ in
        
    }
}
