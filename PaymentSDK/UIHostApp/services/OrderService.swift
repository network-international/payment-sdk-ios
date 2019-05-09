//
//  OrderService.swift
//  UIHostApp
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

typealias OrderResponseReturnBlock = (OrderResponse?, Error?)->()

class OrderService {
    
    private static let endpoint = URL(string: "http://localhost:3000/api/create_payment_order")
    
    static func create(amount: Amount, action: String, completion : @escaping OrderResponseReturnBlock){
        guard let url = endpoint  else
        {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let payload = OrderRequestPayload(amount: amount, action: action, language: "en", description: "Purchase from merchant sample app")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let orderResponse = try decoder.decode(OrderResponse.self, from: data)
                    completion(orderResponse, nil)
                } catch let error {
                    completion(nil, error)
                }
            })
            task.resume()
            
        } catch let error {
            print(error.localizedDescription)
            completion(nil, error)
        }
        
    }
    
}
