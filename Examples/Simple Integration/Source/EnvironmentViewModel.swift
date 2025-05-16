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
}
