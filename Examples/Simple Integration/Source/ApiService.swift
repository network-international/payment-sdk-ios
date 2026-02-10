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

        let identityUrl = environment.getIdentityUrl()
        print("📡 [Auth] Requesting token from: \(identityUrl)")

        var authRequest = URLRequest(url: URL(string: identityUrl)!)
        authRequest.httpMethod = "POST"
        authRequest.setValue("application/vnd.ni-identity.v1+json", forHTTPHeaderField: "Content-Type")
        authRequest.setValue("Basic \(environment.apiKey)", forHTTPHeaderField: "Authorization")
        authRequest.httpBody = authDataJson

        URLSession.shared.dataTask(with: authRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [Auth] Response status: \(httpResponse.statusCode)")
            }
            guard let data = data else {
                print("❌ [Auth] No data returned. Error: \(error?.localizedDescription ?? "nil")")
                completion(.failure(error ?? NSError(domain: "Auth Failed", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth failed - no data returned"])))
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let accessToken = jsonResponse["access_token"] as? String {
                    print("✅ [Auth] Token received successfully")
                    completion(.success(accessToken))
                } else {
                    let responseStr = String(data: data, encoding: .utf8) ?? "non-utf8"
                    print("❌ [Auth] No access_token in response: \(responseStr)")
                    completion(.failure(NSError(domain: "Invalid Access Token", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth response missing access_token"])))
                }
            } catch {
                let responseStr = String(data: data, encoding: .utf8) ?? "non-utf8"
                print("❌ [Auth] JSON parse error: \(error). Response body: \(responseStr)")
                completion(.failure(error))
            }
        }.resume()
    }

    func createOrder(orderData: OrderRequest, completion: @escaping (Result<OrderResponse, Error>) -> Void) {
        if let environment = getEnvironment() {
            print("📡 [Order] Environment: \(environment.name) (\(environment.type.rawValue))")
            getAuthToken(environment: environment) { result in
                switch result {
                case .success(let accessToken):
                    var url = environment.getGateWayUrl()
                    var contentType: String = "application/vnd.ni-payment.v2+json"
                    if (orderData.type == "RECURRING" || orderData.type == "INSTALLMENT") {
                        url = url.replacingOccurrences(of: "transactions", with: "recurring-payment")
                        contentType = "application/vnd.ni-recurring-payment.v2+json"
                    }
                    print("📡 [Order] Creating order at: \(url)")

                    var orderRequest = URLRequest(url: URL(string: url)!)
                    orderRequest.httpMethod = "POST"
                    orderRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    orderRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    orderRequest.setValue(contentType, forHTTPHeaderField: "Accept")
                    let userAgent = "iOS pay page \(UIDevice().name) \(UIDevice().systemName)-\(UIDevice().systemVersion) - SDK -\(NISdk.sharedInstance.version)"
                    orderRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")

                    let encoder = JSONEncoder()
                    let orderRequestData = try! encoder.encode(orderData)
                    print("📡 [Order] Request body: \(String(data: orderRequestData, encoding: .utf8) ?? "nil")")
                    orderRequest.httpBody = orderRequestData

                    URLSession.shared.dataTask(with: orderRequest) { (data, response, error) in
                        if let httpResponse = response as? HTTPURLResponse {
                            print("📡 [Order] Response status: \(httpResponse.statusCode)")
                        }
                        guard let data = data else {
                            print("❌ [Order] No data returned. Error: \(error?.localizedDescription ?? "nil")")
                            completion(.failure(error ?? NSError(domain: "Failed creating order", code: -1, userInfo: [NSLocalizedDescriptionKey: "Order creation failed - no data"])))
                            return
                        }

                        let responseStr = String(data: data, encoding: .utf8) ?? "non-utf8"
                        print("📡 [Order] Response body: \(responseStr)")

                        do {
                            let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                            print("✅ [Order] Order created successfully. Reference: \(orderResponse.reference ?? "nil")")
                            completion(.success(orderResponse))
                        } catch {
                            print("❌ [Order] JSON decode error: \(error)")
                            completion(.failure(NSError(domain: "OrderDecodeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode order response: \(error.localizedDescription)"])))
                        }
                    }.resume()

                case .failure(let error):
                    print("❌ [Order] Auth failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        } else {
            print("❌ [Order] No environment selected!")
            completion(.failure(NSError(domain: "NoEnvironment", code: -1, userInfo: [NSLocalizedDescriptionKey: "No environment configured. Please set up an environment first."])))
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

                    let userAgent = "iOS pay page \(UIDevice().name) \(UIDevice().systemName)-\(UIDevice().systemVersion) - SDK -\(NISdk.sharedInstance.version)"
                    orderRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")

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
