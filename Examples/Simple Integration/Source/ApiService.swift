//
//  ApiService.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 25/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import Foundation
import NISdk

class ApiService {
    func getAuthToken(environment: Environment, completion: @escaping (Result<String, Error>) -> Void) {
        let authData = ["realmName": environment.realm]
        let authDataJson = try! JSONSerialization.data(withJSONObject: authData)
        
        var authRequest = URLRequest(url: URL(string: environment.getIdentityUrl())!)
        authRequest.httpMethod = "POST"
        authRequest.setValue("application/vnd.ni-identity.v1+json", forHTTPHeaderField: "Content-Type")
        authRequest.setValue("Basic \(environment.apiKey)", forHTTPHeaderField: "Authorization")
        authRequest.httpBody = authDataJson
        
        URLSession.shared.dataTask(with: authRequest) { (data, response, error) in
            guard let data = data else {
                completion(.failure(error ?? NSError(domain: "Auth Failed", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let accessToken = jsonResponse["access_token"] as? String {
                    completion(.success(accessToken))
                } else {
                    completion(.failure(NSError(domain: "Invalid Access Token", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createOrder(orderData: OrderRequest, completion: @escaping (Result<OrderResponse, Error>) -> Void) {
        if let environment = getEnvironment() {
            getAuthToken(environment: environment) { result in
                switch result {
                case .success(let accessToken):
                    var orderRequest = URLRequest(url: URL(string: environment.getGateWayUrl())!)
                    orderRequest.httpMethod = "POST"
                    orderRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    orderRequest.setValue("application/vnd.ni-payment.v2+json", forHTTPHeaderField: "Content-Type")
                    orderRequest.setValue("application/vnd.ni-payment.v2+json", forHTTPHeaderField: "Accept")
                    
                    let encoder = JSONEncoder()
                    let orderRequestData = try! encoder.encode(orderData)
                    orderRequest.httpBody = orderRequestData
                    
                    URLSession.shared.dataTask(with: orderRequest) { (data, response, error) in
                        guard let data = data else {
                            completion(.failure(error ?? NSError(domain: "Failed creating order", code: -1, userInfo: nil)))
                            return
                        }
                        
                        do {
                            let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                            completion(.success(orderResponse))
                        } catch {
                            completion(.failure(error))
                        }
                    }.resume()
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveCardForOrder(orderId: String, completion: @escaping (Result<SavedCard, Error>) -> Void) {
        if let environment = getEnvironment() {
            getAuthToken(environment: environment) { result in
                switch result {
                case .success(let accessToken):
                    let orderUrl = "\(environment.getGateWayUrl())/\(orderId)"
                    
                    var orderRequest = URLRequest(url: URL(string: orderUrl)!)
                    orderRequest.httpMethod = "GET"
                    orderRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    orderRequest.setValue("application/vnd.ni-payment.v2+json", forHTTPHeaderField: "Content-Type")
                    orderRequest.setValue("application/vnd.ni-payment.v2+json", forHTTPHeaderField: "Accept")
                    
                    URLSession.shared.dataTask(with: orderRequest) { (data, response, error) in
                        guard let data = data else {
                            completion(.failure(error ?? NSError(domain: "Get order failed", code: -1, userInfo: nil)))
                            return
                        }
                        
                        do {
                            let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                            if let savedCard = orderResponse.embeddedData?.payment?.first?.savedCard {
                                completion(.success(savedCard))
                            } else {
                                completion(.failure(NSError(domain: "Get order failed", code: -1, userInfo: nil)))
                            }
                            
                        } catch {
                            completion(.failure(error))
                        }
                    }.resume()
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getEnvironment() -> Environment? {
        if let selectedId = Environment.getSelectedEnvironment() {
            return Environment.getEnvironments().first(where: { $0.id == selectedId})
        } else {
            return nil
        }
    }
}
