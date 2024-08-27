import SwiftUI

struct VisaInstallmentView: View {
    @State private var selectedPlan: InstallmentPlan?
    @State private var paymentProcessing: Bool = false
    
    let plans: [InstallmentPlan]
    let cardNumber: String
    let onMakePayment: (InstallmentPlan) -> Void?
    
    var body: some View {
        let direction: LayoutDirection = if (Locale.characterDirection(forLanguage: NISdk.sharedInstance.sdkLanguage) == .rightToLeft) {
            .rightToLeft
        } else {
            .leftToRight
        }
        VStack(alignment: .center) {
            let termsAccepted = selectedPlan?.termsAccepted ?? false
            let termsExpanded = selectedPlan?.termsExpanded ?? false
            Divider()
            VisaHeaderView(cardNumber: cardNumber)
            Divider()
            
            ScrollView {
                VStack {
                    ForEach(plans, id: \.self.vPlanId) { plan in
                        let isSelected = if (selectedPlan != nil && selectedPlan?.vPlanId == plan.vPlanId) {
                            true
                        } else {
                            false
                        }
                        
                        let terms = plan.termsAndConditions
                        
                        let amountFormatted = switch(plan.frequency) {
                        case .Monthly:
                            String.localizedStringWithFormat("Visa Monthly Instalment".localized, plan.amount)
                        case .BiMonthly:
                            String.localizedStringWithFormat("Visa Bi Monthly Instalment".localized, plan.amount)
                        case.Weekly:
                            String.localizedStringWithFormat("Visa Weekly Instalment".localized, plan.amount)
                        case.BiWeekly:
                            String.localizedStringWithFormat("Visa Bi Weekly Instalment".localized, plan.amount)
                        default:
                            plan.amount
                        }
                        
                        let rateFormatted = switch(plan.frequency) {
                        case .Monthly:
                            String.localizedStringWithFormat("Visa Monthly Rate".localized, plan.rate)
                        case .BiMonthly:
                            String.localizedStringWithFormat("Visa Bi Monthly Rate".localized, plan.rate)
                        case.Weekly:
                            String.localizedStringWithFormat("Visa Weekly Rate".localized, plan.rate)
                        case.BiWeekly:
                            String.localizedStringWithFormat("Visa Bi Weekly Rate".localized, plan.rate)
                        default:
                            ""
                        }
                        
                        VStack(alignment: .leading) {
                            let headerTitle =  if (plan.frequency == .PayInFull) {
                                "Visa Pay In Full".localized.uppercased()
                            } else {
                                String.localizedStringWithFormat("Visa Pay In Instalment".localized.uppercased(), String(plan.numberOfInstallments))
                            }
                            Text(headerTitle)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(amountFormatted)
                            
                            if plan.frequency != .PayInFull {
                                Text(String.localizedStringWithFormat("Visa Processing Fee".localized, plan.totalUpFrontFees))
                                    .font(.subheadline)
                                Text(rateFormatted)
                                    .font(.subheadline)
                            }
                            
                            if terms != nil && isSelected {
                                HStack {
                                    if termsExpanded || termsAccepted {
                                        Button(action: {
                                            selectedPlan?.termsAccepted.toggle()
                                        }) {
                                            Image(systemName: termsAccepted ? "checkmark.square" : "square")
                                        }.buttonStyle(.borderless)
                                    } else {
                                        Image(systemName: "square.fill").foregroundColor(.gray)
                                    }
                                    
                                    Text("Visa Terms And Conditions".localized)
                                        .font(.subheadline)
                                    
                                    Button(termsExpanded ? "Visa Read Less".localized :"Visa Read More".localized) {
                                        selectedPlan?.termsExpanded.toggle()
                                    }.buttonStyle(.borderless)
                                        .font(.subheadline)
                                }
                                if let termsText = terms?.getFormattedText() {
                                    if termsExpanded {
                                        Text(.init(termsText))
                                            .lineSpacing(0.1)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        )
                        .padding(2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if (selectedPlan?.vPlanId != plan.vPlanId) {
                                selectedPlan = plan
                            }
                        }
                    }
                    
                }.disabled(paymentProcessing)
            }
            
            let buttonEnable = !paymentProcessing && (termsAccepted || (selectedPlan != nil && selectedPlan!.frequency == .PayInFull))
            
            VStack(alignment: .leading) {
                Divider()
                Button(action: {
                    if let selectedPlan = selectedPlan {
                        paymentProcessing = true
                        onMakePayment(selectedPlan)
                    }
                } ) {
                    if (paymentProcessing) {
                        HStack {
                            Text("Processing Payment".localized)
                            ActivityIndicator()
                        }
                    } else {
                        Text("Make Payment".localized)
                    }
                }
                .disabled(!buttonEnable)
                .buttonStyle(PaymentButtonStyle(enabled: buttonEnable))
                
                Image("visaInstallment", bundle: NISdk.sharedInstance.getBundle())
                    .resizable(resizingMode: /*@START_MENU_TOKEN@*/.stretch/*@END_MENU_TOKEN@*/)
                    .scaledToFit()
                    .frame(height: 12)
                    .padding(.horizontal, 10)
                Divider()
                
            }
        }.padding(10)
            .environment(\.layoutDirection, direction)
    }
}

struct ActivityIndicator: UIViewRepresentable {
    
    typealias UIView = UIActivityIndicatorView
    fileprivate var configuration = { (indicator: UIView) in }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView {
        UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        uiView.startAnimating()
        configuration(uiView)
    }
}

struct VisaHeaderView: View {
    let cardNumber: String
    var body: some View {
        HStack {
            Image("visalogo", bundle: NISdk.sharedInstance.getBundle())
                .resizable()
                .frame(width: 124, height: 40)
                .fixedSize()
            
            VStack(alignment: .leading) {
                Text(getMaskedCardNumber(cardNumber: cardNumber))
                    .font(.headline)
                Text("Visa Instalment Eligible".localized)
                    .foregroundColor(.green)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }.padding(8)
    }
    
    func getMaskedCardNumber(cardNumber: String) -> String {
        var maskedCardNumber = ""
        if !cardNumber.isEmpty {
            let startIndex = cardNumber.index(cardNumber.startIndex, offsetBy: 6)
            let endIndex = cardNumber.index(startIndex, offsetBy: 6)
            let replacement = String(repeating: "*", count: 6)
            
            maskedCardNumber = cardNumber.replacingCharacters(in: startIndex..<endIndex, with: replacement)
                .replacingOccurrences(of: "....", with: "$0 ", options: .regularExpression)
        }
        return maskedCardNumber
    }
}

struct PaymentButtonStyle: ButtonStyle {
    let enabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: 44)
            .foregroundColor(.white)
            .background(enabled ? Color.blue : Color.gray)
            .cornerRadius(5)
    }
}

struct VisaInstallmentView_Previews: PreviewProvider {
    static var previews: some View {
        VisaInstallmentView(plans: [
            InstallmentPlan(vPlanId: "1", amount: "$1000", totalUpFrontFees: "$50", rate: "5.0", numberOfInstallments: 12, frequency: .Monthly, termsAndConditions: TermsAndConditions(text: "These terms of use constitute an agreement between https://www.google.com you and X Pay Pvt Ltd ABN 123456", version: 1, languageCode: "end", url: ""), termsAccepted: false, termsExpanded: false),
            InstallmentPlan(vPlanId: "2", amount: "$500", totalUpFrontFees: "$25", rate: "2.5", numberOfInstallments: 24, frequency: .Monthly, termsAndConditions: TermsAndConditions(text: "sometext", version: 1, languageCode: "end", url: ""), termsAccepted: false, termsExpanded: false),
            InstallmentPlan(vPlanId: "3", amount: "$250", totalUpFrontFees: "$15", rate: "1.0", numberOfInstallments: 36, frequency: .Monthly, termsAndConditions: TermsAndConditions(text: "sometext", version: 1, languageCode: "end", url: ""), termsAccepted: false, termsExpanded: false)], cardNumber: "476108******2022", onMakePayment: { _ in
                
            })
    }
}

struct InstallmentPlan {
    var vPlanId: String
    var amount: String
    var totalUpFrontFees: String
    var rate: String
    var numberOfInstallments: Int
    var frequency: PlanFrequency
    var termsAndConditions: TermsAndConditions? = nil
    var termsAccepted: Bool = false
    var termsExpanded: Bool = false
}

enum PlanFrequency {
    case Weekly
    case Monthly
    case BiWeekly
    case BiMonthly
    case PayInFull
}
