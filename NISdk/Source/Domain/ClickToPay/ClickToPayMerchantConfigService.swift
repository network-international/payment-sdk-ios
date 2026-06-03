//
//  ClickToPayMerchantConfigService.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

/// Calls `/config/merchants/{merchantId}/configs/vctp` on the N-Genius gateway and decodes
/// the DPA credentials the SDK needs to launch Click to Pay. Decouples the gateway response
/// shape from `ClickToPayConfig` so the parsing logic lives in one place.
enum ClickToPayMerchantConfigService {

    struct Resolved {
        let dpaId: String
        let dpaClientId: String?
        let dpaName: String?
    }

    enum FetchError: Error, LocalizedError {
        case invalidUrl
        case noData
        case missingDpaId
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .invalidUrl:     return "Invalid Click to Pay merchant config URL"
            case .noData:         return "Empty response from Click to Pay merchant config endpoint"
            case .missingDpaId:   return "Click to Pay merchant config response did not contain a dpaId"
            case .underlying(let e): return e.localizedDescription
            }
        }
    }

    static func fetch(merchantId: String,
                      accessToken: String,
                      apiGatewayBaseUrl: String,
                      completion: @escaping (Result<Resolved, FetchError>) -> Void) {
        let trimmedBase = apiGatewayBaseUrl.hasSuffix("/")
            ? String(apiGatewayBaseUrl.dropLast())
            : apiGatewayBaseUrl
        let urlString = "\(trimmedBase)/config/merchants/\(merchantId)/configs/vctp"

        guard let client = HTTPClient(url: urlString) else {
            completion(.failure(.invalidUrl))
            return
        }

        client
            .withMethod(method: "GET")
            .withHeaders(headers: [
                "Accept": "application/json",
                "Authorization": "Bearer \(accessToken)"
            ])
            .makeRequest { data, _, error in
                if let error = error {
                    completion(.failure(.underlying(error)))
                    return
                }
                guard let data = data,
                      let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                    completion(.failure(.noData))
                    return
                }
                guard let dpaId = json["dpaId"] as? String, !dpaId.isEmpty else {
                    completion(.failure(.missingDpaId))
                    return
                }
                let dpaClientId = json["dpaClientId"] as? String
                let dpaName = (json["successResponse"] as? [String: Any])?["companyPrimaryLegalName"] as? String
                completion(.success(Resolved(dpaId: dpaId, dpaClientId: dpaClientId, dpaName: dpaName)))
            }
    }
}
