//
//  EnvironmentView.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 24/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import SwiftUI
import NISdk

private let niBlue = Color(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0)

struct QRScannedData: Identifiable {
    let id = UUID()
    let realm: String
    let outletReference: String
    let apiKey: String
}

struct EnvironmentView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    @State private var isAddingEnvironment = false
    @State private var selectedEnvironment: String = "DEV"
    @State private var apiKey: String = ""
    @State private var outletReference: String = ""
    @State private var realm: String = ""
    @State private var errorMessage: String?
    @State private var environmentExpanded = false

    @State private var isAddingMerchantAttributes = false
    @State private var merchantAtrributesExpanded = false

    @State private var merchantAttributeKey: String = ""
    @State private var merchantAttributeValue: String = ""

    // QR scanning
    @State private var isShowingQRScanner = false
    @State private var qrScannedData: QRScannedData?
    @State private var qrSelectedType: String = "DEV"
    @State private var qrErrorMessage: String?

    // SDK Colors
    @State private var sdkColorsExpanded = false

    // Edit environment
    @State private var editingEnvironment: Environment?

    private func pickerRow<SelectionValue: Hashable, Content: View>(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .layoutPriority(1)
            Spacer()
            Picker(title, selection: selection, content: content)
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
        }
        .padding(.vertical, 4)
    }

    func actionChange(_ tag: String) {
        viewModel.setOrderAction(action: tag)
    }

    func languageChange(_ tag: String) {
        viewModel.setLanguage(language: tag)
    }

    func currencyChange(_ tag: String) {
        viewModel.setCurrency(currency: tag)
    }

    func regionChange(_ tag: String) {
        viewModel.setRegion(region: tag)
    }

    func orderTypeChange(_ tag: String) {
        viewModel.setOrderType(orderType: tag)
    }

    private var pickersSection: some View {
        Group {
            Divider()
            Text("Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) SDK-v\(NISdk.sharedInstance.version)")
                .frame(maxWidth: .infinity)
                .font(.caption)
                .multilineTextAlignment(.trailing)

            Divider()

            pickerRow(title: "Order Action", selection: $viewModel.action.onChange(actionChange)) {
                Text("PURCHASE").tag("PURCHASE")
                Text("SALE").tag("SALE")
                Text("AUTH").tag("AUTH")
            }

            Divider()

            pickerRow(title: "Order Type", selection: $viewModel.orderType.onChange(orderTypeChange)) {
                Text("SINGLE").tag("")
                Text("RECURRING").tag("RECURRING")
                Text("UNSCHEDULED").tag("UNSCHEDULED")
                Text("INSTALLMENT").tag("INSTALLMENT")
            }

            Divider()

            pickerRow(title: "SDK Language", selection: $viewModel.language.onChange(languageChange)) {
                Text("English").tag("en")
                Text("Arabic").tag("ar")
                Text("French").tag("fr")
            }

            Divider()

            currencyPicker

            Divider()

            pickerRow(title: "Region", selection: $viewModel.region.onChange(regionChange)) {
                Text("UAE").tag("UAE")
                Text("KSA").tag("KSA")
            }
        }
    }

    private var currencyPicker: some View {
        pickerRow(title: "Currency", selection: $viewModel.currency.onChange(currencyChange)) {
            Group {
                Text("AED - UAE Dirham").tag("AED")
                Text("SAR - Saudi Riyal").tag("SAR")
                Text("AUD - Australian Dollar").tag("AUD")
                Text("BRL - Brazilian Real").tag("BRL")
                Text("CAD - Canadian Dollar").tag("CAD")
                Text("CHF - Swiss Franc").tag("CHF")
                Text("CNY - Chinese Yuan").tag("CNY")
                Text("EUR - Euro").tag("EUR")
                Text("GBP - British Pound").tag("GBP")
                Text("HKD - Hong Kong Dollar").tag("HKD")
            }
            Group {
                Text("INR - Indian Rupee").tag("INR")
                Text("JPY - Japanese Yen").tag("JPY")
                Text("KRW - South Korean Won").tag("KRW")
                Text("MXN - Mexican Peso").tag("MXN")
                Text("NOK - Norwegian Krone").tag("NOK")
                Text("NZD - New Zealand Dollar").tag("NZD")
                Text("SEK - Swedish Krona").tag("SEK")
                Text("SGD - Singapore Dollar").tag("SGD")
                Text("TRY - Turkish Lira").tag("TRY")
                Text("USD - US Dollar").tag("USD")
            }
            Group {
                Text("ZAR - South African Rand").tag("ZAR")
                Text("BHD - Bahraini Dinar").tag("BHD")
                Text("DZD - Algerian Dinar").tag("DZD")
                Text("ILS - Israeli Shekel").tag("ILS")
                Text("JOD - Jordanian Dinar").tag("JOD")
                Text("KWD - Kuwaiti Dinar").tag("KWD")
                Text("LYD - Libyan Dinar").tag("LYD")
                Text("OMR - Omani Rial").tag("OMR")
                Text("QAR - Qatari Riyal").tag("QAR")
                Text("TND - Tunisian Dinar").tag("TND")
                Text("ZWG - Zimbabwean Dollar").tag("ZWG")
            }
        }
    }

    private var sdkColorsSection: some View {
        Group {
            HStack {
                Text("SDK Colors")
                Spacer()
                Button {
                    sdkColorsExpanded.toggle()
                } label: {
                    Image(systemName: sdkColorsExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(niBlue)
                }
            }

            if sdkColorsExpanded {
                VStack(spacing: 12) {
                    SDKColorRow(label: "Button", hex: $viewModel.sdkColorPayButton, onSave: viewModel.saveSDKColorPayButton)
                    SDKColorRow(label: "Button Text", hex: $viewModel.sdkColorPayButtonText, onSave: viewModel.saveSDKColorPayButtonText)
                    SDKColorRow(label: "Button Disabled", hex: $viewModel.sdkColorPayButtonDisabled, onSave: viewModel.saveSDKColorPayButtonDisabled)
                    SDKColorRow(label: "Button Disabled Text", hex: $viewModel.sdkColorPayButtonDisabledText, onSave: viewModel.saveSDKColorPayButtonDisabledText)
                    SDKColorRow(label: "Input Field BG", hex: $viewModel.sdkColorInputFieldBg, onSave: viewModel.saveSDKColorInputFieldBg)
                    SDKColorRow(label: "Auth View BG", hex: $viewModel.sdkColorAuthViewBg, onSave: viewModel.saveSDKColorAuthViewBg)
                    SDKColorRow(label: "Auth Indicator", hex: $viewModel.sdkColorAuthViewIndicator, onSave: viewModel.saveSDKColorAuthViewIndicator)
                    SDKColorRow(label: "Auth Label", hex: $viewModel.sdkColorAuthViewLabel, onSave: viewModel.saveSDKColorAuthViewLabel)
                    SDKColorRow(label: "3DS View BG", hex: $viewModel.sdkColorThreeDSViewBg, onSave: viewModel.saveSDKColorThreeDSViewBg)
                    SDKColorRow(label: "3DS Label", hex: $viewModel.sdkColorThreeDSViewLabel, onSave: viewModel.saveSDKColorThreeDSViewLabel)
                    SDKColorRow(label: "3DS Indicator", hex: $viewModel.sdkColorThreeDSViewIndicator, onSave: viewModel.saveSDKColorThreeDSViewIndicator)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var merchantAttributesSection: some View {
        Group {
            HStack {
                Text("Merchant Attributes")
                Spacer()
                Button {
                    isAddingMerchantAttributes.toggle()
                } label: {
                    Image(systemName: "plus.app")
                        .foregroundColor(niBlue)
                }.sheet(isPresented: $isAddingMerchantAttributes, content: {
                    Form {
                        TextField("Key", text: $merchantAttributeKey)
                        TextField("Value", text: $merchantAttributeValue)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        Button("Save") {
                            if merchantAttributeKey.isEmpty || merchantAttributeValue.isEmpty {
                                errorMessage = "Please fill in all fields"
                            } else {
                                viewModel.addMerchantAtrribute(key: merchantAttributeKey, value: merchantAttributeValue)
                                merchantAttributeKey = ""
                                merchantAttributeValue = ""
                                isAddingMerchantAttributes.toggle()
                            }
                        }.frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(niBlue)
                            .cornerRadius(6)
                    }
                })

                Button {
                    merchantAtrributesExpanded.toggle()
                } label: {
                    Image(systemName: merchantAtrributesExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(niBlue)
                }
            }
            Divider()

            if merchantAtrributesExpanded && !viewModel.merchantAttributes.isEmpty {
                VStack {
                    ForEach(viewModel.merchantAttributes, id: \.id) { attribute in
                        HStack {
                            Text("Key: \(attribute.key)")
                            Text("value: \(attribute.value)")
                            Spacer()
                            Button {
                                viewModel.delete(merchantAttribute: attribute)
                            } label: {
                                Image(systemName: "trash")
                            }.foregroundColor(.red)
                        }.frame(maxWidth: .infinity).padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    }
                }
            }
        }
    }

    private var environmentsSection: some View {
        Group {
            HStack {
                Text("Environments")
                Spacer()

                Button {
                    isShowingQRScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(niBlue)
                }
                .fullScreenCover(isPresented: $isShowingQRScanner) {
                    QRScannerView(
                        onCodeScanned: { code in
                            let parts = code.split(separator: "|").map(String.init)
                            if parts.count == 3 {
                                let data = QRScannedData(
                                    realm: parts[0],
                                    outletReference: parts[1],
                                    apiKey: parts[2]
                                )
                                isShowingQRScanner = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    qrSelectedType = "DEV"
                                    qrScannedData = data
                                }
                            } else {
                                isShowingQRScanner = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    qrErrorMessage = "Invalid QR format. Expected: realm|outletReference|apiKey"
                                }
                            }
                        },
                        onCancel: {
                            isShowingQRScanner = false
                        }
                    )
                }

                Button {
                    isAddingEnvironment.toggle()
                } label: {
                    Image(systemName: "plus.app")
                        .foregroundColor(niBlue)
                }.sheet(isPresented: $isAddingEnvironment, content: {
                    Form {
                        Picker("Select Environment", selection: $selectedEnvironment) {
                            Text("DEV").tag("DEV")
                            Text("UAT").tag("UAT")
                            Text("PROD").tag("PROD")
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        TextField("API Key", text: $apiKey)
                        TextField("Outlet Reference", text: $outletReference)
                        TextField("Realm", text: $realm)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        Button("Save") {
                            if selectedEnvironment.isEmpty || apiKey.isEmpty || outletReference.isEmpty || realm.isEmpty {
                                errorMessage = "Please fill in all fields"
                            } else {
                                let env = switch(selectedEnvironment) {
                                case "DEV":
                                    EnvironmentType.DEV
                                case "UAT":
                                    EnvironmentType.UAT
                                case "PROD":
                                    EnvironmentType.PROD
                                default:
                                    EnvironmentType.DEV
                                }
                                viewModel.addEnvironment(name: realm, apiKey: apiKey, outletReference: outletReference, realm: realm, type: env)

                                apiKey = ""
                                outletReference = ""
                                realm = ""
                                isAddingEnvironment.toggle()
                                errorMessage = nil
                            }
                        }.frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(niBlue)
                            .cornerRadius(6)
                    }
                })

                Button {
                    environmentExpanded.toggle()
                } label: {
                    Image(systemName: environmentExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(niBlue)
                }
            }
            Divider()
            if environmentExpanded {
                environmentsList
            }
        }
    }

    private var environmentsList: some View {
        VStack {
            ForEach(viewModel.environments, id: \.id) { environment in
                let isSelected = viewModel.getSelectedId() == environment.id
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(environment.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(environment.realm)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("\(environment.type)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(niBlue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(niBlue, lineWidth: 1)
                            )
                            .cornerRadius(12)

                        Button {
                            editingEnvironment = environment
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(niBlue)
                        }
                        .padding(4)

                        Button {
                            viewModel.delete(environemnt: environment)
                        } label: {
                            Image(systemName: "trash.fill")
                        }.foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? niBlue : Color.gray, lineWidth: isSelected ? 2 : 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? niBlue.opacity(0.05) : Color.clear)
                )
                .padding(2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isSelected {
                        viewModel.setEnvironment(environmentId: environment.id)
                    }
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                pickersSection
                Divider()
                sdkColorsSection
                Divider()
                merchantAttributesSection
                environmentsSection
                Spacer()
            }.padding(10)
        }
        // QR Confirm Sheet
        .sheet(item: $qrScannedData) { data in
            Form {
                Section(header: Text("Scanned Environment")) {
                    Picker("Type", selection: $qrSelectedType) {
                        Text("DEV").tag("DEV")
                        Text("UAT").tag("UAT")
                        Text("PROD").tag("PROD")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Realm")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(data.realm)
                    }
                    HStack {
                        Text("Outlet Reference")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(data.outletReference)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    HStack {
                        Text("API Key")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(data.apiKey)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Button("Add Environment") {
                    let envType = switch(qrSelectedType) {
                    case "DEV": EnvironmentType.DEV
                    case "UAT": EnvironmentType.UAT
                    case "PROD": EnvironmentType.PROD
                    default: EnvironmentType.DEV
                    }
                    viewModel.addEnvironment(name: data.realm, apiKey: data.apiKey, outletReference: data.outletReference, realm: data.realm, type: envType)
                    environmentExpanded = true
                    qrScannedData = nil
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(6)
                .background(niBlue)
                .cornerRadius(6)

                Button("Cancel") {
                    qrScannedData = nil
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(niBlue)
            }
        }
        // Edit Environment Sheet
        .sheet(item: $editingEnvironment) { environment in
            EditEnvironmentSheet(
                environment: environment,
                onSave: { updated in
                    viewModel.update(environment: updated)
                    editingEnvironment = nil
                },
                onCancel: {
                    editingEnvironment = nil
                }
            )
        }
        .alert("QR Error", isPresented: Binding(
            get: { qrErrorMessage != nil },
            set: { if !$0 { qrErrorMessage = nil } }
        )) {
            Button("OK") { qrErrorMessage = nil }
        } message: {
            Text(qrErrorMessage ?? "")
        }
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en"))
    }
}

struct EditEnvironmentSheet: View {
    let environment: Environment
    let onSave: (Environment) -> Void
    let onCancel: () -> Void

    @State private var type: String
    @State private var apiKey: String
    @State private var outletReference: String
    @State private var realm: String
    @State private var errorMessage: String?

    init(environment: Environment, onSave: @escaping (Environment) -> Void, onCancel: @escaping () -> Void) {
        self.environment = environment
        self.onSave = onSave
        self.onCancel = onCancel
        _type = State(initialValue: environment.type.rawValue)
        _apiKey = State(initialValue: environment.apiKey)
        _outletReference = State(initialValue: environment.outletReference)
        _realm = State(initialValue: environment.realm)
    }

    var body: some View {
        Form {
            Section(header: Text("Edit Environment")) {
                Picker("Type", selection: $type) {
                    Text("DEV").tag("DEV")
                    Text("UAT").tag("UAT")
                    Text("PROD").tag("PROD")
                }
                .pickerStyle(SegmentedPickerStyle())

                TextField("Realm", text: $realm)
                TextField("API Key", text: $apiKey)
                TextField("Outlet Reference", text: $outletReference)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Button("Save") {
                if apiKey.isEmpty || outletReference.isEmpty || realm.isEmpty {
                    errorMessage = "Please fill in all fields"
                } else {
                    let envType = switch(type) {
                    case "DEV": EnvironmentType.DEV
                    case "UAT": EnvironmentType.UAT
                    case "PROD": EnvironmentType.PROD
                    default: EnvironmentType.DEV
                    }
                    let updated = Environment(
                        id: environment.id,
                        type: envType,
                        name: realm,
                        apiKey: apiKey,
                        outletReference: outletReference,
                        realm: realm
                    )
                    onSave(updated)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(6)
            .background(Color(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0))
            .cornerRadius(6)

            Button("Cancel") {
                onCancel()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0))
        }
    }
}

struct SDKColorRow: View {
    let label: String
    @Binding var hex: String
    let onSave: (String) -> Void

    @State private var pickerColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            TextField("#RRGGBB", text: $hex, onCommit: {
                onSave(hex)
            })
            .font(.system(.subheadline, design: .monospaced))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 110)
            .autocapitalization(.allCharacters)
            .disableAutocorrection(true)
            .onChange(of: hex) { newValue in
                onSave(newValue)
                if let c = Color(hex: newValue) {
                    pickerColor = c
                }
            }
            ColorPicker("", selection: $pickerColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28, height: 28)
                .onChange(of: pickerColor) { newColor in
                    if let hexStr = newColor.toHex() {
                        hex = hexStr
                        onSave(hexStr)
                    }
                }
        }
        .onAppear {
            if let c = Color(hex: hex) {
                pickerColor = c
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

struct EnvironmentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EnvironmentViewModel()
        viewModel.addEnvironment(name: "DEV", apiKey: "api_key_123", outletReference: "outlet_ref_123", realm: "realm_123", type: EnvironmentType.DEV)

        viewModel.addMerchantAtrribute(key: "some", value: "some")
        viewModel.addMerchantAtrribute(key: "some", value: "some")
        viewModel.addMerchantAtrribute(key: "some", value: "some")

        return EnvironmentView(viewModel: viewModel)
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
            })
    }
}
