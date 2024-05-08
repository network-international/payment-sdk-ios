//
//  VisaRequest.swift
//  NISdk
//
//  Created by Gautam Chibde on 15/04/24.
//

import Foundation

class VisaRequest: NSObject, Codable {
    var planSelectionIndicator: Bool
    var acceptedTAndCVersion: Int?
    var vPlanId: String?
    
    override init() {
        self.planSelectionIndicator = false
        self.acceptedTAndCVersion = nil
        self.vPlanId = nil
    }
    
    init(planSelectionIndicator: Bool, acceptedTAndCVersion: Int?, vPlanId: String?) {
        self.planSelectionIndicator = planSelectionIndicator
        self.acceptedTAndCVersion = acceptedTAndCVersion
        self.vPlanId = vPlanId
    }
    
    enum CodingKeys: String, CodingKey {
        case planSelectionIndicator
        case acceptedTAndCVersion
        case vPlanId
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        planSelectionIndicator = try container.decode(Bool.self, forKey: .planSelectionIndicator)
        acceptedTAndCVersion = try container.decode(Int.self, forKey: .acceptedTAndCVersion)
        vPlanId = try container.decode(String.self, forKey: .vPlanId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planSelectionIndicator, forKey: .planSelectionIndicator)
        try container.encode(acceptedTAndCVersion, forKey: .acceptedTAndCVersion)
        try container.encode(vPlanId, forKey: .vPlanId)
    }
}
