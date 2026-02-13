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
    @State private var editType: String = "DEV"
    @State private var editApiKey: String = ""
    @State private var editOutletReference: String = ""
    @State private var editRealm: String = ""
    @State private var editErrorMessage: String?

    func actionChange(_ tag: String) {
        viewModel.setOrderAction(action: tag)
    }

    func languageChange(_ tag: String) {
        viewModel.setLanguage(language: tag)
    }

    func regionChange(_ tag: String) {
        viewModel.setRegion(region: tag)
    }

    func orderTypeChange(_ tag: String) {
        viewModel.setOrderType(orderType: tag)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                Text("Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) SDK-v\(NISdk.sharedInstance.version)")
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)

                Divider()

                Text("Order Action")

                Picker("Order action", selection: $viewModel.action.onChange(actionChange)) {
                    Text("PURCHASE").tag("PURCHASE")
                    Text("SALE").tag("SALE")
                    Text("AUTH").tag("AUTH")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)

                Divider()

                Text("Order type")

                Picker("Select order type", selection: $viewModel.orderType.onChange(orderTypeChange)) {
                    Text("SINGLE").tag("")
                    Text("RECURRING").tag("RECURRING")
                    Text("UNSCHEDULED").tag("UNSCHEDULED")
                    Text("INSTALLMENT").tag("INSTALLMENT")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)

                Divider()

                Text("SDK Language")
                Picker("Select Language", selection: $viewModel.language.onChange(languageChange)) {
                    Text("English").tag("en")
                    Text("Arabic").tag("ar")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)

                Divider()

                Text("Region")
                Picker("Select region", selection: $viewModel.region.onChange(regionChange)) {
                    Text("UAE").tag("UAE")
                    Text("KSA").tag("KSA")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)

                Divider()

                // MARK: - SDK Colors
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
                        SDKColorRow(label: "Pay Button", hex: $viewModel.sdkColorPayButton, onSave: viewModel.saveSDKColorPayButton)
                        SDKColorRow(label: "Pay Button Text", hex: $viewModel.sdkColorPayButtonText, onSave: viewModel.saveSDKColorPayButtonText)
                        SDKColorRow(label: "Page Background", hex: $viewModel.sdkColorPageBackground, onSave: viewModel.saveSDKColorPageBackground)
                        SDKColorRow(label: "Card Preview", hex: $viewModel.sdkColorCardPreview, onSave: viewModel.saveSDKColorCardPreview)
                        SDKColorRow(label: "Page Title", hex: $viewModel.sdkColorPageTitle, onSave: viewModel.saveSDKColorPageTitle)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                // MARK: - Merchant Attributes
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

                // MARK: - Environments
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
                if (environmentExpanded) {
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
                                        editType = environment.type.rawValue
                                        editApiKey = environment.apiKey
                                        editOutletReference = environment.outletReference
                                        editRealm = environment.realm
                                        editErrorMessage = nil
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
            Form {
                Section(header: Text("Edit Environment")) {
                    Picker("Type", selection: $editType) {
                        Text("DEV").tag("DEV")
                        Text("UAT").tag("UAT")
                        Text("PROD").tag("PROD")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Realm", text: $editRealm)
                    TextField("API Key", text: $editApiKey)
                    TextField("Outlet Reference", text: $editOutletReference)

                    if let editErrorMessage = editErrorMessage {
                        Text(editErrorMessage)
                            .foregroundColor(.red)
                    }
                }

                Button("Save") {
                    if editApiKey.isEmpty || editOutletReference.isEmpty || editRealm.isEmpty {
                        editErrorMessage = "Please fill in all fields"
                    } else {
                        let envType = switch(editType) {
                        case "DEV": EnvironmentType.DEV
                        case "UAT": EnvironmentType.UAT
                        case "PROD": EnvironmentType.PROD
                        default: EnvironmentType.DEV
                        }
                        let updated = Environment(
                            id: environment.id,
                            type: envType,
                            name: editRealm,
                            apiKey: editApiKey,
                            outletReference: editOutletReference,
                            realm: editRealm
                        )
                        viewModel.update(environment: updated)
                        editingEnvironment = nil
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(6)
                .background(niBlue)
                .cornerRadius(6)

                Button("Cancel") {
                    editingEnvironment = nil
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(niBlue)
            }
        }
        .alert("QR Error", isPresented: Binding(
            get: { qrErrorMessage != nil },
            set: { if !$0 { qrErrorMessage = nil } }
        )) {
            Button("OK") { qrErrorMessage = nil }
        } message: {
            Text(qrErrorMessage ?? "")
        }
    }
}

struct SDKColorRow: View {
    let label: String
    @Binding var hex: String
    let onSave: (String) -> Void

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
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: hex) ?? Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray, lineWidth: 1)
                )
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
