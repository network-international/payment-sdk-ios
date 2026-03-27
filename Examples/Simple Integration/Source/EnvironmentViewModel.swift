//
//  EnvironmentViewModel.swift
//  Demo App
//
//  Created by Gautam Chibde on 03/05/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import Foundation

class EnvironmentViewModel: ObservableObject {
    @Published var environments: [Environment] = []
    @Published var merchantAttributes: [MerchantAttribute] = []
    @Published var action: String = ""
    @Published var language: String = ""
    @Published var region: String = ""
    @Published var currency: String = ""
    @Published var orderType: String = ""

    // SDK Colors
    @Published var sdkColorPayButton: String = ""
    @Published var sdkColorPayButtonText: String = ""
    @Published var sdkColorPayButtonDisabled: String = ""
    @Published var sdkColorPayButtonDisabledText: String = ""
    @Published var sdkColorInputFieldBg: String = ""
    @Published var sdkColorAuthViewBg: String = ""
    @Published var sdkColorAuthViewIndicator: String = ""
    @Published var sdkColorAuthViewLabel: String = ""
    @Published var sdkColorThreeDSViewBg: String = ""
    @Published var sdkColorThreeDSViewLabel: String = ""
    @Published var sdkColorThreeDSViewIndicator: String = ""

    func addEnvironment(name: String, apiKey: String, outletReference: String, realm: String, type: EnvironmentType) {
        let environment = Environment(type:type, name: name, apiKey: apiKey, outletReference: outletReference, realm: realm)
        environments.append(environment)
        saveEnviroments()
        updateEnvironment()
        if (environments.count == 1) {
            if let id =  environments.first?.id {
                setEnvironment(environmentId: id)
            }
        }
    }
    
    init() {
        updateEnvironment()
        self.merchantAttributes = getMerchantAttributes()
        action = getOrderAction()
        language = getLangugae()
        region = getRegion()
        currency = getCurrency()
        orderType = getOrderType()
        sdkColorPayButton = Environment.sdkColorPayButton.isEmpty ? "#007AFF" : Environment.sdkColorPayButton
        sdkColorPayButtonText = Environment.sdkColorPayButtonText.isEmpty ? "#FFFFFF" : Environment.sdkColorPayButtonText
        sdkColorPayButtonDisabled = Environment.sdkColorPayButtonDisabled.isEmpty ? "#D1D1D6" : Environment.sdkColorPayButtonDisabled
        sdkColorPayButtonDisabledText = Environment.sdkColorPayButtonDisabledText.isEmpty ? "#8E8E93" : Environment.sdkColorPayButtonDisabledText
        sdkColorInputFieldBg = Environment.sdkColorInputFieldBg.isEmpty ? "#FFFFFF" : Environment.sdkColorInputFieldBg
        sdkColorAuthViewBg = Environment.sdkColorAuthViewBg.isEmpty ? "#FFFFFF" : Environment.sdkColorAuthViewBg
        sdkColorAuthViewIndicator = Environment.sdkColorAuthViewIndicator.isEmpty ? "#8E8E93" : Environment.sdkColorAuthViewIndicator
        sdkColorAuthViewLabel = Environment.sdkColorAuthViewLabel.isEmpty ? "#000000" : Environment.sdkColorAuthViewLabel
        sdkColorThreeDSViewBg = Environment.sdkColorThreeDSViewBg.isEmpty ? "#FFFFFF" : Environment.sdkColorThreeDSViewBg
        sdkColorThreeDSViewLabel = Environment.sdkColorThreeDSViewLabel.isEmpty ? "#000000" : Environment.sdkColorThreeDSViewLabel
        sdkColorThreeDSViewIndicator = Environment.sdkColorThreeDSViewIndicator.isEmpty ? "#8E8E93" : Environment.sdkColorThreeDSViewIndicator

        // Persist defaults to UserDefaults
        Environment.sdkColorPayButton = sdkColorPayButton
        Environment.sdkColorPayButtonText = sdkColorPayButtonText
        Environment.sdkColorPayButtonDisabled = sdkColorPayButtonDisabled
        Environment.sdkColorPayButtonDisabledText = sdkColorPayButtonDisabledText
        Environment.sdkColorInputFieldBg = sdkColorInputFieldBg
        Environment.sdkColorAuthViewBg = sdkColorAuthViewBg
        Environment.sdkColorAuthViewIndicator = sdkColorAuthViewIndicator
        Environment.sdkColorAuthViewLabel = sdkColorAuthViewLabel
        Environment.sdkColorThreeDSViewBg = sdkColorThreeDSViewBg
        Environment.sdkColorThreeDSViewLabel = sdkColorThreeDSViewLabel
        Environment.sdkColorThreeDSViewIndicator = sdkColorThreeDSViewIndicator
    }
    
    func saveEnviroments() {
        Environment.saveEnvironments(environments: environments)
    }
    
    func addMerchantAtrribute(key: String, value: String) {
        let merchantAttribute = MerchantAttribute(key: key, value: value)
        merchantAttributes.append(merchantAttribute)
        saveMerchantAttributes()
        self.merchantAttributes = Environment.getMerchantAttributes()
    }
    
    func saveMerchantAttributes() {
        Environment.saveMerchantAttributes(merchantAttributes: merchantAttributes)
    }
    
    func delete(merchantAttribute: MerchantAttribute) {
        merchantAttributes.removeAll(where: {$0.id == merchantAttribute.id })
        saveMerchantAttributes()
        self.merchantAttributes = Environment.getMerchantAttributes()
    }
    
    func getMerchantAttributes() -> [MerchantAttribute] {
        return Environment.getMerchantAttributes()
    }
    
    func updateEnvironment(){
        self.environments = Environment.getEnvironments()
    }
    
    func getSelectedId() -> String? {
        return Environment.getSelectedEnvironment()
    }
    
    func setEnvironment(environmentId: String) {
        Environment.setSelectedEnvironment(environmentId: environmentId)
        updateEnvironment()
    }
    
    func delete(environemnt: Environment) {
        environments.removeAll(where: { $0.id == environemnt.id })
        saveEnviroments()
        updateEnvironment()
    }

    func update(environment: Environment) {
        if let index = environments.firstIndex(where: { $0.id == environment.id }) {
            environments[index] = environment
            saveEnviroments()
            updateEnvironment()
        }
    }
    
    func setOrderAction(action: String) {
        Environment.setOrderAction(action: action)
    }
    
    func getOrderAction() -> String {
        return Environment.getOrderAction()
    }
    
    func setLanguage(language: String) {
        Environment.setLanguage(language: language)
    }
    
    func getLangugae() -> String {
        return Environment.getLanguage()
    }

    func setRegion(region: String) {
        Environment.setRegion(region: region)
    }

    func getRegion() -> String {
        return Environment.getRegion()
    }

    func setCurrency(currency: String) {
        Environment.setCurrency(currency: currency)
    }

    func getCurrency() -> String {
        return Environment.getCurrency()
    }

    func setOrderType(orderType: String) {
        Environment.setOrderType(orderType: orderType)
    }

    func getOrderType() -> String {
        return Environment.getOrderType()
    }

    // MARK: - SDK Colors

    func saveSDKColorPayButton(_ hex: String) {
        Environment.sdkColorPayButton = hex
    }

    func saveSDKColorPayButtonText(_ hex: String) {
        Environment.sdkColorPayButtonText = hex
    }

    func saveSDKColorPayButtonDisabled(_ hex: String) {
        Environment.sdkColorPayButtonDisabled = hex
    }

    func saveSDKColorPayButtonDisabledText(_ hex: String) {
        Environment.sdkColorPayButtonDisabledText = hex
    }

    func saveSDKColorInputFieldBg(_ hex: String) {
        Environment.sdkColorInputFieldBg = hex
    }

    func saveSDKColorAuthViewBg(_ hex: String) {
        Environment.sdkColorAuthViewBg = hex
    }

    func saveSDKColorAuthViewIndicator(_ hex: String) {
        Environment.sdkColorAuthViewIndicator = hex
    }

    func saveSDKColorAuthViewLabel(_ hex: String) {
        Environment.sdkColorAuthViewLabel = hex
    }

    func saveSDKColorThreeDSViewBg(_ hex: String) {
        Environment.sdkColorThreeDSViewBg = hex
    }

    func saveSDKColorThreeDSViewLabel(_ hex: String) {
        Environment.sdkColorThreeDSViewLabel = hex
    }

    func saveSDKColorThreeDSViewIndicator(_ hex: String) {
        Environment.sdkColorThreeDSViewIndicator = hex
    }

}
