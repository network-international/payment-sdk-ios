//
//  EnvironmentView.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 24/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import SwiftUI

class EnvironmentViewModel: ObservableObject {
    @Published var environments: [Environment] = []
    @Published var action: String = ""
    @Published var language: String = ""
    
    func addEnvironment(name: String, apiKey: String, outletReference: String, realm: String, type: EnvironmentType) {
        let environment = Environment(type:type, name: name, apiKey: apiKey, outletReference: outletReference, realm: realm)
        environments.append(environment)
        saveEnviroments()
        updateEnvironment()
    }
    
    init() {
        updateEnvironment()
        action = getOrderAction()
        language = getLangugae()
    }
    
    func saveEnviroments() {
        Environment.saveEnvironments(environments: environments)
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
}

struct EnvironmentView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    @State private var isAddingEnvironment = false
    @State private var selectedEnvironment: String = "DEV"
    @State private var apiKey: String = ""
    @State private var outletReference: String = ""
    @State private var realm: String = ""
    @State private var errorMessage: String?
    @State private var name: String = ""
    
    func actionChange(_ tag: String) {
        viewModel.setOrderAction(action: tag)
    }
    
    func languageChange(_ tag: String) {
        viewModel.setLanguage(language: tag)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
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
            
            Text("SDK Language")
            Picker("Select Language", selection: $viewModel.language.onChange(languageChange)) {
                Text("English").tag("en")
                Text("Arabic").tag("ar")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(8)
            
            Divider()
            HStack {
                Spacer()
                Button("Add Environment") {
                    isAddingEnvironment.toggle()
                }
                .padding(10)
                .foregroundColor(.blue)
                .background(Color.white)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .sheet(isPresented: $isAddingEnvironment, content: {
                    Form {
                        Picker("Select Environment", selection: $selectedEnvironment) {
                            Text("DEV").tag("DEV")
                            Text("UAT").tag("UAT")
                            Text("PROD").tag("PROD")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        TextField("Name", text: $name)
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
                                viewModel.addEnvironment(name: name, apiKey: apiKey, outletReference: outletReference, realm: realm, type: env)
                                
                                name = ""
                                apiKey = ""
                                outletReference = ""
                                realm = ""
                                isAddingEnvironment.toggle()
                                errorMessage = nil
                            }
                        }.frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                })
                Spacer()
            }
            ScrollView {
                VStack {
                    ForEach(viewModel.environments, id: \.id) { environment in
                        VStack(alignment: .leading) {
                            Text("Environment: \(environment.type)")
                            Text("Name: \(environment.name)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Realm: \(environment.realm)")
                            
                            Button("Delete") {
                                viewModel.delete(environemnt: environment)
                            }.foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke((viewModel.getSelectedId() == environment.id) ? Color.blue : Color.gray, lineWidth: 2)
                        )
                        .padding(2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.getSelectedId() != environment.id {
                                viewModel.setEnvironment(environmentId: environment.id)
                            }
                        }
                    }
                }
            }
        }.padding(10)
    }
}

struct EnvironmentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EnvironmentViewModel()
        viewModel.addEnvironment(name: "DEV", apiKey: "api_key_123", outletReference: "outlet_ref_123", realm: "realm_123", type: EnvironmentType.DEV)
        
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
