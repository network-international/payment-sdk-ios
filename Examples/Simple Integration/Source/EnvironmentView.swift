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

struct EnvironmentView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    @State private var isAddingEnvironment = false
    @State private var selectedEnvironment: String = "DEV"
    @State private var nickname: String = ""
    @State private var apiKey: String = ""
    @State private var outletReference: String = ""
    @State private var realm: String = ""
    @State private var applePayMerchantId: String = ""
    @State private var newRegion: String = "UAE"
    @State private var newCurrency: String = "AED"
    @State private var newOrderAction: String = "SALE"
    @State private var newOrderType: String = ""
    @State private var clickToPayMerchantId: String = ""
    @State private var errorMessage: String?
    @State private var environmentExpanded = false
    @State private var useNIApplePayCertificate = Environment.useNIApplePayCertificate

    @State private var isAddingMerchantAttributes = false
    @State private var merchantAtrributesExpanded = false

    @State private var merchantAttributeKey: String = ""
    @State private var merchantAttributeValue: String = ""

    // QR scanning
    @State private var isShowingQRScanner = false
    @State private var qrScannedData: ScannedEnvironment?
    @State private var qrImportSummary: String?
    @State private var qrSelectedType: String = "DEV"
    @State private var qrErrorMessage: String?

    // SDK Colors
    @State private var isShowingSdkAppearance = false
    @State private var isShowingTransfer = false

    // Edit environment
    @State private var editingEnvironment: Environment?
    /// Set when the trash button is tapped; the confirmation alert below is driven
    /// off it. Deleting discards an API key that may need another portal trip to
    /// recover, and the button sits next to Edit, so it asks first.
    @State private var environmentPendingDeletion: Environment?

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

    func languageChange(_ tag: String) {
        viewModel.setLanguage(language: tag)
    }

    private var pickersSection: some View {
        Group {
            Divider()
            Text("Version: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) SDK-v\(NISdk.sharedInstance.version)")
                .frame(maxWidth: .infinity)
                .font(.caption)
                .multilineTextAlignment(.trailing)

            Divider()

            // Order action, order type, currency and region are outlet configuration, not app
            // settings — which actions and methods an outlet accepts differ per outlet, and a
            // key only works against its own region. They live in the add/edit environment
            // form; only genuinely app-wide settings remain here.
            pickerRow(title: "SDK Language", selection: $viewModel.language.onChange(languageChange)) {
                Text("English").tag("en")
                Text("Arabic").tag("ar")
                Text("French").tag("fr")
            }
            .accessibilityIdentifier("environment_picker_language")

            Divider()

            applePayCertificateRow
        }
    }

    /// Switches Apple Pay between the customer's uploaded certificate and NI's own. Both
    /// halves move together: the merchant identifier the sheet is presented with decides
    /// which key the token is encrypted to, and the gateway flag decides which key it is
    /// decrypted with. Changing one without the other only breaks decryption.
    private var applePayCertificateRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $useNIApplePayCertificate.onChange(applePayCertificateChange)) {
                Text("Use NI Apple Pay certificate")
            }
            .accessibilityIdentifier("environment_toggle_applepay_certificate")

            Text(useNIApplePayCertificate
                 ? Environment.niApplePayMerchantId
                 : "Merchant certificate — uses the environment's Apple Pay merchant ID")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("environment_caption_applepay_certificate")
        }
    }

    private func applePayCertificateChange(_ isOn: Bool) {
        Environment.useNIApplePayCertificate = isOn
    }

    /// Opens the SDK Appearance page.
    ///
    /// These settings describe how the SDK draws, not which outlet is charged, and
    /// eleven colour rows crowded a screen that is mostly about environments. The
    /// Android and Flutter demos show the same list under the same name.
    /// Opens the Transfer page. A sheet, not a NavigationLink, for the same reason
    /// as the SDK Appearance row: this view is hosted in a UIKit navigation
    /// controller, so a SwiftUI link has nothing to push onto.
    private var transferSection: some View {
        Button {
            isShowingTransfer = true
        } label: {
            HStack {
                Text("Transfer Environments")
                    .foregroundColor(.primary)
                Spacer()
                Text("Copy, paste, scan or QR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier("environment_row_transfer")
        .sheet(isPresented: $isShowingTransfer) {
            EnvironmentTransferView(viewModel: viewModel,
                                    onDone: { isShowingTransfer = false })
        }
    }

    private var sdkColorsSection: some View {
        // Presented as a sheet, not a NavigationLink: this view is hosted in a
        // UIKit UINavigationController, so there is no SwiftUI navigation
        // ancestor for a link to push onto — it would render and do nothing.
        Button {
            isShowingSdkAppearance = true
        } label: {
            HStack {
                Text("SDK Appearance")
                    .foregroundColor(.primary)
                Spacer()
                Text("SDK colours")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier("environment_row_sdkAppearance")
        .sheet(isPresented: $isShowingSdkAppearance) {
            SdkAppearanceView(viewModel: viewModel,
                              onDone: { isShowingSdkAppearance = false })
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
                            .accessibilityIdentifier("merchantattr_field_key")
                        TextField("Value", text: $merchantAttributeValue)
                            .accessibilityIdentifier("merchantattr_field_value")

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
                            .accessibilityIdentifier("merchantattr_button_save")
                    }
                })
                .accessibilityIdentifier("environment_button_addMerchantAttribute")

                Button {
                    merchantAtrributesExpanded.toggle()
                } label: {
                    Image(systemName: merchantAtrributesExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(niBlue)
                }
                .accessibilityIdentifier("environment_button_toggleMerchantAttributes")
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

    /// QA shortcut: region, currency, order action and order type for every order, in
    /// place of the selected environment's own. Built to be obvious at a glance whether it
    /// is on — an override left on by accident silently changes every order.
    private var overrideSection: some View {
        let on = viewModel.overrideEnabled
        let onColor = Color(red: 0xE6 / 255, green: 0x51 / 255, blue: 0)  // deep orange: attention, not error
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.setOverrideEnabled(!on) }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: on ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(on ? onColor : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Override environment settings")
                                .font(.body.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Text(on ? "ON" : "OFF")
                                .font(.caption2.bold())
                                .foregroundColor(on ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(on ? onColor : Color(.systemGray5)))
                        }
                        Text(on
                             ? "Every order uses the values below instead of the selected environment's."
                             : "Off — each environment's own region, currency, action and type are used.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("environment_checkbox_override")

            // Collapsed while off: the values only matter when they apply.
            if on {
                VStack(alignment: .leading, spacing: 2) {
                    overridePicker("Region", selection: $viewModel.overrideRegion
                        .onChange(viewModel.setOverrideRegion), id: "region") {
                        Text("UAE").tag("UAE")
                        Text("KSA").tag("KSA")
                    }
                    overridePicker("Currency", selection: $viewModel.overrideCurrency
                        .onChange(viewModel.setOverrideCurrency), id: "currency") {
                        ForEach(Environment.supportedCurrencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    overridePicker("Order Action", selection: $viewModel.overrideOrderAction
                        .onChange(viewModel.setOverrideOrderAction), id: "orderAction") {
                        Text("SALE").tag("SALE")
                        Text("PURCHASE").tag("PURCHASE")
                        Text("AUTH").tag("AUTH")
                    }
                    overridePicker("Order Type", selection: $viewModel.overrideOrderType
                        .onChange(viewModel.setOverrideOrderType), id: "orderType") {
                        Text("SINGLE").tag("")
                        Text("RECURRING").tag("RECURRING")
                        Text("UNSCHEDULED").tag("UNSCHEDULED")
                        Text("INSTALLMENT").tag("INSTALLMENT")
                    }
                    Text("Region sets the Apple Pay country. The gateway and outlet still come from the selected environment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.leading, 36)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(on ? onColor.opacity(0.08) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(on ? onColor : Color(.systemGray3), lineWidth: on ? 2 : 1))
    }

    /// One override row: a fixed label column and a menu filling the rest, so the four
    /// rows line up whatever their values' lengths.
    private func overridePicker<Content: View>(
        _ title: String,
        selection: Binding<String>,
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .frame(width: 110, alignment: .leading)
            Picker(title, selection: selection, content: content)
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("environment_picker_override_\(id)")
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
                        onCodesScanned: { codes in
                            isShowingQRScanner = false
                            let batch = ScannedEnvironment.parseAll(codes.joined(separator: "\n"))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if batch.environments.isEmpty {
                                    qrErrorMessage = "No environment found. Expected one per line: nickname|realm|outletReference|apiKey|applePayMerchantId|region|currency|type|orderAction|orderType"
                                } else if batch.environments.count == 1 && batch.rejected == 0 {
                                    // One outlet: confirm before saving, as before.
                                    let data = batch.environments[0]
                                    qrSelectedType = data.type.rawValue
                                    qrScannedData = data
                                } else {
                                    // A batch is imported directly — the point is not
                                    // to confirm ten sheets.
                                    let r = viewModel.importEnvironments(batch.environments)
                                    environmentExpanded = true
                                    let skipped = batch.rejected > 0 ? ", \(batch.rejected) line(s) skipped" : ""
                                    qrImportSummary = "\(r.added) added, \(r.replaced) updated\(skipped)."
                                }
                            }
                        },
                        onCancel: {
                            isShowingQRScanner = false
                        }
                    )
                }
                .accessibilityIdentifier("environment_button_scanQR")

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
                        .accessibilityIdentifier("addenv_picker_type")

                        TextField("Nickname (optional)", text: $nickname)
                            .accessibilityIdentifier("addenv_field_nickname")
                        TextField("Realm", text: $realm)
                            .accessibilityIdentifier("addenv_field_realm")
                        TextField("API Key", text: $apiKey)
                            .accessibilityIdentifier("addenv_field_apiKey")
                        TextField("Outlet Reference", text: $outletReference)
                            .accessibilityIdentifier("addenv_field_outletReference")

                        OutletSettingsFields(region: $newRegion, currency: $newCurrency,
                                             orderAction: $newOrderAction, orderType: $newOrderType,
                                             idPrefix: "addenv")

                        TextField("Apple Pay Merchant ID (optional)", text: $applePayMerchantId)
                            .accessibilityIdentifier("addenv_field_applePayMerchantId")
                        TextField("Click to Pay Merchant ID (optional)", text: $clickToPayMerchantId)
                            .accessibilityIdentifier("addenv_field_clickToPayMerchantId")

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
                                viewModel.addEnvironment(nickname: nickname, apiKey: apiKey, outletReference: outletReference, realm: realm, type: env, region: Region(rawValue: newRegion) ?? .UAE, currency: newCurrency, orderAction: newOrderAction, orderType: newOrderType, applePayMerchantId: applePayMerchantId, clickToPayMerchantId: clickToPayMerchantId)

                                nickname = ""
                                apiKey = ""
                                outletReference = ""
                                realm = ""
                                applePayMerchantId = ""
                                clickToPayMerchantId = ""
                                newRegion = "UAE"
                                newCurrency = "AED"
                                newOrderAction = "SALE"
                                newOrderType = ""
                                isAddingEnvironment.toggle()
                                errorMessage = nil
                            }
                        }.frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(niBlue)
                            .cornerRadius(6)
                            .accessibilityIdentifier("addenv_button_save")
                    }
                })
                .accessibilityIdentifier("environment_button_addEnvironment")

                Button {
                    environmentExpanded.toggle()
                } label: {
                    Image(systemName: environmentExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(niBlue)
                }
                .accessibilityIdentifier("environment_button_toggleEnvironments")
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
                EnvironmentRow(
                    environment: environment,
                    isSelected: viewModel.getSelectedId() == environment.id,
                    isOverridden: viewModel.overrideEnabled,
                    onSelect: { viewModel.setEnvironment(environmentId: environment.id) },
                    onEdit: { editingEnvironment = environment },
                    onDelete: { environmentPendingDeletion = environment }
                )
            }
        }
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                pickersSection
                Divider()
                transferSection
                Divider()
                sdkColorsSection
                Divider()
                merchantAttributesSection
                overrideSection
                    .padding(.vertical, 8)
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
                    .accessibilityIdentifier("qrconfirm_picker_type")

                    if !data.nickname.isEmpty {
                        HStack {
                            Text("Nickname")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(data.nickname)
                        }
                    }
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
                    if !data.applePayMerchantId.isEmpty {
                        HStack {
                            Text("Apple Pay Merchant ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(data.applePayMerchantId)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    // Region and currency belong to the outlet, so the tester should
                    // see what the code is about to commit them to before tapping Add.
                    HStack {
                        Text("Region · Currency")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(data.region.rawValue) · \(data.currency)")
                    }
                    HStack {
                        Text("Order")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(data.orderAction) · \(data.orderType.isEmpty ? "SINGLE" : data.orderType)")
                    }
                }

                Button("Add Environment") {
                    let envType = switch(qrSelectedType) {
                    case "DEV": EnvironmentType.DEV
                    case "UAT": EnvironmentType.UAT
                    case "PROD": EnvironmentType.PROD
                    default: EnvironmentType.DEV
                    }
                    viewModel.addEnvironment(nickname: data.nickname, apiKey: data.apiKey, outletReference: data.outletReference, realm: data.realm, type: envType, region: data.region, currency: data.currency, orderAction: data.orderAction, orderType: data.orderType, applePayMerchantId: data.applePayMerchantId)
                    environmentExpanded = true
                    qrScannedData = nil
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(6)
                .background(niBlue)
                .cornerRadius(6)
                .accessibilityIdentifier("qrconfirm_button_add")

                Button("Cancel") {
                    qrScannedData = nil
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("qrconfirm_button_cancel")
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
        .alert("Delete environment",
               isPresented: Binding(
                get: { environmentPendingDeletion != nil },
                set: { if !$0 { environmentPendingDeletion = nil } }
               ),
               presenting: environmentPendingDeletion) { environment in
            Button("Delete", role: .destructive) {
                viewModel.delete(environemnt: environment)
                environmentPendingDeletion = nil
            }
            .accessibilityIdentifier("environment_button_confirmDelete")
            Button("Cancel", role: .cancel) { environmentPendingDeletion = nil }
        } message: { environment in
            Text("Remove \(environment.name)? This cannot be undone.")
        }
        .alert("Environments imported", isPresented: Binding(
            get: { qrImportSummary != nil },
            set: { if !$0 { qrImportSummary = nil } }
        )) {
            Button("OK") { qrImportSummary = nil }
        } message: {
            Text(qrImportSummary ?? "")
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

/// Region, currency, order action and order type for one outlet.
///
/// These four are outlet configuration, not app settings: a key only works against its
/// own region's deployment, alternative payment methods follow the acquirer (so the
/// currency decides what is offered), and which actions and order types an outlet
/// accepts differ per outlet. They used to sit in the main configuration screen, where
/// one global value was necessarily wrong for every outlet but the one it was set for.
struct OutletSettingsFields: View {
    @Binding var region: String
    @Binding var currency: String
    @Binding var orderAction: String
    @Binding var orderType: String
    let idPrefix: String

    var body: some View {
        Group {
            Picker("Region", selection: $region) {
                Text("UAE").tag("UAE")
                Text("KSA").tag("KSA")
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityIdentifier("\(idPrefix)_picker_region")

            Picker("Currency", selection: $currency) {
                ForEach(Environment.supportedCurrencies, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .accessibilityIdentifier("\(idPrefix)_picker_currency")

            Picker("Order Action", selection: $orderAction) {
                Text("SALE").tag("SALE")
                Text("PURCHASE").tag("PURCHASE")
                Text("AUTH").tag("AUTH")
            }
            .accessibilityIdentifier("\(idPrefix)_picker_orderAction")

            Picker("Order Type", selection: $orderType) {
                Text("SINGLE").tag("")
                Text("RECURRING").tag("RECURRING")
                Text("UNSCHEDULED").tag("UNSCHEDULED")
                Text("INSTALLMENT").tag("INSTALLMENT")
            }
            .accessibilityIdentifier("\(idPrefix)_picker_orderType")
        }
    }
}

struct EditEnvironmentSheet: View {
    let environment: Environment
    let onSave: (Environment) -> Void
    let onCancel: () -> Void

    @State private var type: String
    @State private var nickname: String
    @State private var apiKey: String
    @State private var outletReference: String
    @State private var realm: String
    @State private var applePayMerchantId: String
    @State private var region: String
    @State private var currency: String
    @State private var orderAction: String
    @State private var orderType: String
    @State private var errorMessage: String?

    init(environment: Environment, onSave: @escaping (Environment) -> Void, onCancel: @escaping () -> Void) {
        self.environment = environment
        self.onSave = onSave
        self.onCancel = onCancel
        _type = State(initialValue: environment.type.rawValue)
        _nickname = State(initialValue: environment.nickname)
        _apiKey = State(initialValue: environment.apiKey)
        _outletReference = State(initialValue: environment.outletReference)
        _realm = State(initialValue: environment.realm)
        _applePayMerchantId = State(initialValue: environment.applePayMerchantId)
        _region = State(initialValue: environment.region.rawValue)
        _currency = State(initialValue: environment.currency)
        _orderAction = State(initialValue: environment.orderAction)
        _orderType = State(initialValue: environment.orderType)
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
                .accessibilityIdentifier("editenv_picker_type")

                TextField("Nickname (optional)", text: $nickname)
                    .accessibilityIdentifier("editenv_field_nickname")
                TextField("Realm", text: $realm)
                    .accessibilityIdentifier("editenv_field_realm")
                TextField("API Key", text: $apiKey)
                    .accessibilityIdentifier("editenv_field_apiKey")
                TextField("Outlet Reference", text: $outletReference)
                    .accessibilityIdentifier("editenv_field_outletReference")

                OutletSettingsFields(region: $region, currency: $currency,
                                     orderAction: $orderAction, orderType: $orderType,
                                     idPrefix: "editenv")

                TextField("Apple Pay Merchant ID (optional)", text: $applePayMerchantId)
                    .accessibilityIdentifier("editenv_field_applePayMerchantId")

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
                    // Every field is passed explicitly. Omitting one does not preserve it —
                    // it takes the initialiser default, which silently reset this outlet's
                    // region, currency and Click to Pay id on every edit.
                    let updated = Environment(
                        id: environment.id,
                        type: envType,
                        nickname: nickname,
                        apiKey: apiKey,
                        outletReference: outletReference,
                        realm: realm,
                        region: Region(rawValue: region) ?? .UAE,
                        currency: currency,
                        orderAction: orderAction,
                        orderType: orderType,
                        applePayMerchantId: applePayMerchantId,
                        clickToPayMerchantId: environment.clickToPayMerchantId
                    )
                    onSave(updated)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(6)
            .background(Color(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0))
            .cornerRadius(6)
            .accessibilityIdentifier("editenv_button_save")

            Button("Cancel") {
                onCancel()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0))
            .accessibilityIdentifier("editenv_button_cancel")
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
            .accessibilityIdentifier("sdkcolor_field_\(label.lowercased().replacingOccurrences(of: " ", with: "_"))")
            ColorPicker("", selection: $pickerColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28, height: 28)
                .accessibilityIdentifier("sdkcolor_picker_\(label.lowercased().replacingOccurrences(of: " ", with: "_"))")
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
        viewModel.addEnvironment(nickname: "DEV", apiKey: "api_key_123", outletReference: "outlet_ref_123", realm: "realm_123", type: EnvironmentType.DEV)

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
