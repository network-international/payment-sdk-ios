//
//  String+Env.swift
//  NISdk
//
//  Created by Johnny Peter on 06/10/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

public enum NGeniusEnvironments: String {
    case UAT
    case PROD
    case DEV
}

extension String {
    func ngenEnv() -> NGeniusEnvironments {
        let str = self.lowercased()
        if str.contains("-uat") || str.contains("sandbox") {
            return .UAT
        }
        if str.contains("-dev") {
            return .DEV
        }
        return .PROD
    }
}
