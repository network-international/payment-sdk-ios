//
//  EnvironmentView.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 24/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import SwiftUI
import NISdk

struct EnvironmentView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    @State private var isAddingEnvironment = false
    @State private var selectedEnvironment: String = "DEV"
    @State private var apiKey: String = ""
    @State private var outletReference: String = ""
    @State private var realm: String = ""
    @State private var errorMessage: String?
    @State private var name: String = ""
    @State private var environmentExpanded = false
    
    @State private var isAddingMerchantAttributes = false
    @State private var merchantAtrributesExpanded = false
    
    @State private var merchantAttributeKey: String = ""
    @State private var merchantAttributeValue: String = ""
    
    func actionChange(_ tag: String) {
        viewModel.setOrderAction(action: tag)
    }
    
    func languageChange(_ tag: String) {
        viewModel.setLanguage(language: tag)
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
                
                Text("SDK Language")
                Picker("Select Language", selection: $viewModel.language.onChange(languageChange)) {
                    Text("English").tag("en")
                    Text("Arabic").tag("ar")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(8)
                
                Divider()
                
                HStack {
                    Text("Merchant Attributes")
                    Spacer()
                    Button {
                        isAddingMerchantAttributes.toggle()
                    } label: {
                        Image(systemName: "plus.app")
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
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    })
                    
                    Button {
                        merchantAtrributesExpanded.toggle()
                    } label: {
                        Image(systemName: merchantAtrributesExpanded ? "chevron.down" : "chevron.up")
                    }
                }
                Divider()
                
                if merchantAtrributesExpanded {
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
                
                HStack {
                    Text("Environments")
                    Spacer()
                    Button {
                        isAddingEnvironment.toggle()
                    } label: {
                        Image(systemName: "plus.app")
                    }.sheet(isPresented: $isAddingEnvironment, content: {
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
                                .padding(6)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    })
                    
                    Button {
                        environmentExpanded.toggle()
                    } label: {
                        Image(systemName: environmentExpanded ? "chevron.down" : "chevron.up")
                    }
                }
                Divider()
                if (environmentExpanded) {
                    VStack {
                        ForEach(viewModel.environments, id: \.id) { environment in
                            VStack(alignment: .leading) {
                                HStack{
                                    VStack(alignment: .leading) {
                                        Text("Name: \(environment.name)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Realm: \(environment.realm)")
                                    }
                                    
                                    Text("\(environment.type)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue, lineWidth: 2)
                                        )
                                    
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
                Spacer()
            }.padding(10)
        }
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
